package main

import (
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"github.com/innoai-tech/webappserve/cuepkg/tool"
)

dagger.#Plan & {
	client: {
		platform: _

		env: {
			VERSION: string | *"dev"
			GIT_SHA: string | *""
			GIT_REF: string | *""

			LINUX_MIRROR: string | *"dl-cdn.alpinelinux.org"

			GOPROXY:   string | *""
			GOPRIVATE: string | *""
			GOSUMDB:   string | *""

			GH_USERNAME: string | *""
			GH_PASSWORD: dagger.#Secret
		}

		for _os in actions.build.targetPlatform.os for _arch in actions.build.targetPlatform.arch {
			filesystem: "./build/output/\(actions.build.name)_\(_os)_\(_arch)": write: contents: actions.build["\(_os)/\(_arch)"].output
		}
	}

	actions: {
		_env: {
			for k, v in client.env if k != "$dagger" {
				"\(k)": v
			}
		}
		_buildPlatform: {
			for k, v in client.platform if k != "$dagger" {
				"\(k)": v
			}
		}

		_source: core.#Source & {
			path: "."
			include: [
				"cmd/",
				"pkg/",
				"go.mod",
				"go.sum",
			]
		}

		info: tool.#GoModInfo & {
			source: _source.output
		}

		_imageName: "ghcr.io/\(strings.TrimPrefix(info.module, "github.com/"))"
		_version:   tool.#ParseVersion & {_, #ref: _env.GIT_REF, #version: _env.VERSION}
		_tag:       _version
		_archs: ["amd64", "arm64"]

		build: {
			tool.#GoBuild & {
				source:        _source.output
				package:       "./cmd/webappserve"
				buildPlatform: _buildPlatform
				targetPlatform: {
					arch: _archs
					os: ["linux"]
				}
				image: {
					downloadMirror: "\(_env.LINUX_MIRROR)"
				}
				run: {
					env: _env
				}
				ldflags: [
					"-s -w",
					"-X \(info.module)/version.Version=\(_version)",
					"-X \(info.module)/version.Revision=\(_env.GIT_SHA)",
				]
			}
		}

		image: {
			for _arch in _archs {
				"linux/\(_arch)": docker.#Build & {
					steps: [
						tool.#AlpineBuild & {
							platform: "linux/\(_arch)"
						},
						docker.#Copy & {
							contents: build["linux/\(_arch)"].output
							source:   "./"
							dest:     "/"
						},
						docker.#Set & {
							config: {
								label: {
									"org.opencontainers.image.source":   "https://\(info.module)"
									"org.opencontainers.image.revision": "\(_env.GIT_SHA)"
								}
								env: {
									APP_ROOT: "/app"
									ENV:      ""
								}
								workdir: "/"
								entrypoint: ["/\(build.name)"]
							}
						},
					]
				}
			}
		}

		push: docker.#Push & {
			dest: "\(_imageName):\(_tag)"
			images: {
				for _arch in _archs {
					"linux/\(_arch)": image["linux/\(_arch)"].output
				}
			}
			auth: {
				username: _env.GH_USERNAME
				secret:   _env.GH_PASSWORD
			}
		}
	}
}

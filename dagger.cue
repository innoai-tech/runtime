package main

import (
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"

	"github.com/innoai-tech/runtime/cuepkg/tool"
	"github.com/innoai-tech/runtime/cuepkg/golang"
	"github.com/innoai-tech/runtime/cuepkg/debian"
)

dagger.#Plan & {
	client: {
		env: {
			VERSION: string | *"dev"
			GIT_SHA: string | *""
			GIT_REF: string | *""

			GOPROXY:   string | *""
			GOPRIVATE: string | *""
			GOSUMDB:   string | *""

			GH_USERNAME: string | *""
			GH_PASSWORD: dagger.#Secret

			LINUX_MIRROR: string | *""
		}

		filesystem: "build/output": write: contents: actions.export.output

		filesystem: {
			_archs: ["amd64", "arm64"]

			for arch in _archs {
				"build/dump/\(arch)": {
					write: contents: actions.shipfs.dump["linux/\(arch)"].output
				}
			}
		}
	}

	actions: {
		version: tool.#ResolveVersion & {
			ref: client.env.GIT_REF, version: "\(client.env.VERSION)"
		}

		src: {
			go: core.#Source & {
				path: "."
				include: [
					"cmd/",
					"pkg/",
					"go.mod",
					"go.sum",
				]
			}
		}

		build: golang.#Build & {
			source: src.go.output
			go: {
				os: ["linux", "darwin"]
				arch: ["amd64", "arm64"]
				package: "./cmd/webappserve"
				ldflags: [
					"-s -w",
					"-X \(go.module)/pkg/version.Version=\(version.output)",
					"-X \(go.module)/pkg/version.Revision=\(client.env.GIT_SHA)",
				]
			}
			run: env: {
				GOPROXY:   client.env.GOPROXY
				GOPRIVATE: client.env.GOPRIVATE
				GOSUMDB:   client.env.GOSUMDB
			}
			//   image: mirror: "\(client.env.LINUX_MIRROR)"
		}

		export: tool.#Export & {
			archive: true
			directories: {
				for _os in build.go.os for _arch in build.go.arch {
					"\(build.go.name)_\(_os)_\(_arch)": build["\(_os)/\(_arch)"].output
				}
			}
		}

		images: {
			for arch in build.go.arch {
				"linux/\(arch)": docker.#Build & {
					steps: [
						debian.#Build & {
							platform: "linux/\(arch)"
							mirror:   client.env.LINUX_MIRROR
							packages: {
								"ca-certificates": _
							}
						},
						docker.#Set & {
							config: {
								label: {
									"org.opencontainers.image.source":   "https://\(build.go.module)"
									"org.opencontainers.image.revision": "\(client.env.GIT_SHA)"
								}
								env: {
									APP_ROOT: "/app"
									ENV:      ""
								}
								workdir: "/"
								entrypoint: ["/webappserve"]
							}
						},
					]
				}
			}
		}

		#Ship: {
			images: [P=string]: docker.#Image

			_push: docker.#Push & {
				"dest":   "\(strings.Replace(build.go.module, "github.com/", "ghcr.io/", -1))/webappserve:\(version.output)"
				"images": images
				"auth": {
					username: client.env.GH_USERNAME
					secret:   client.env.GH_PASSWORD
				}
			}

			result: _push.result
		}

		ship: #Ship & {
			_images: {
				for p, image in images {
					"\(p)": docker.#Copy & {
						input:    image.output
						contents: build["\(p)"].output
						source:   "./webappserve"
						dest:     "/webappserve"
					}
				}
			}

			"images": {
				for p, image in _images {
					"\(p)": image.output
				}
			}
		}

		shipfs: {
			dump: {
				for arch in build.go.arch {
					"linux/\(arch)": build["linux/\(arch)"]
				}
			}

			create: #Ship & {
				_dumps: {
					for arch in build.go.arch {
						"linux/\(arch)": core.#Source & {
							path: "build/dump/\(arch)"
						}
					}
				}

				_images: {
					for p, image in images {
						"\(p)": docker.#Copy & {
							input:    image.output
							contents: _dumps["\(p)"].output
							source:   "./webappserve"
							dest:     "/webappserve"
						}
					}
				}

				"images": {
					for p, image in _images {
						"\(p)": image.output
					}
				}
			}
		}
	}
}

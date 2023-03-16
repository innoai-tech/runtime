package node

import (

	"path"
	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#Project: imagetool.#Project & {
	source: core.#Source

	version: _

	targetarch: [...string] | *["amd64", "arm64"]

	env: [Key=string]:     string | core.#Secret
	mounts: [Name=string]: core.#Mount
	workdir: "/app"

	build: {
		outputs: [Key=string]: string

		pre: [...string]
		post: [...string]

		script: string | *""

		// dev image setting
		image: #Image & {
		}

		_build: docker.#Build & {
			steps: [
				{
					output: image.output
				},
				docker.#Copy & {
					"contents": source.output
					"dest":     "\(workdir)"
				},
				for name, scripts in {
					"prebuild": build.pre
					"build": ["\(build.script)"]
					"postbuild": build.post
				} {
					imagetool.#Script & {
						"name":    "\(name)"
						"workdir": "\(workdir)"
						"mounts": {
							mounts
							pnpm_store: core.#Mount & {
								// https://github.com/pnpm/pnpm/releases/tag/v7.0.0
								dest:     "/root/.local/share/pnpm/store"
								contents: core.#CacheDir & {
									id: "pnpm_store"
								}
							}
						}
						"env": env
						"run": scripts
					}
				},
			]
		}

		_output: docker.#Build & {
			steps: [
				{
					output: docker.#Scratch
				},
				for dest, from in outputs {
					docker.#Copy & {
						"contents": _build.output.rootfs
						"source":   "\(path.Join([workdir, from]))"
						"dest":     "/\(dest)"
					}
				},
			]
		}

		output: _output.output.rootfs
	}

	ship: {
		platforms: [
			for arch in targetarch {
				"linux/\(arch)"
			},
		]

		_assets: {
			for p in platforms {
				"\(p)": build.output
			}
		}

		postSteps: [
			docker.#Copy & {
				input:      _
				"contents": _assets["\(input.platform)"]
				"source":   "/"
				"dest":     "/"
			},
		]
	}
}

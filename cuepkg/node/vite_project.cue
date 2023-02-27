package node

import (
	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#ViteProject: imagetool.#Project & {
	source: core.#Source

	version:  _
	revision: _
	auths:    _
	mirror:   _

	viteconfig: string | *"vite.config.ts"

	env: [Key=string]:     string | core.#Secret
	mounts: [Name=string]: core.#Mount
	workdir: "/app"

	build: {
		pre: [...string]
		post: [...string]

		script: """
		./node_modules/.bin/vite build --mode=production --config=\(viteconfig) --outDir=/output
		"""

		// dev image setting
		image: #Image & {
			"auths":  auths
			"mirror": mirror
		}

		_build: docker.#Build & {
			steps: [
				{
					output: image.output
				},
				docker.#Copy & {
					contents: source.output
					dest:     "\(workdir)"
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

		_output: core.#Subdir & {
			input: _build.output.rootfs
			path:  "/output"
		}

		output: _output.output
	}
}

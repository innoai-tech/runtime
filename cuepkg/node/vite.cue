package node

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#ViteBuild: {
	source: dagger.#FS

	node: {
		npmrc: string | *""
	}

	vite: {
		config: string | *"vite.config.ts"
	}

	run: {
		env: [Key=string]:     string | dagger.#Secret
		mounts: [Name=string]: core.#Mount
		workdir: "/app"
	}

	image: #Image & {}

	_run: docker.#Run & {
		"input":   image.output
		"workdir": run.workdir
		"env":     run.env
		"mounts": {
			run.mounts

			pnpm_store: core.#Mount & {
				// https://github.com/pnpm/pnpm/releases/tag/v7.0.0
				dest:     "/root/.local/share/pnpm/store"
				contents: core.#CacheDir & {
					id: "pnpm_store"
				}
			}
			codesource: core.#Mount & {
				dest:     run.workdir
				contents: source
			}
		}
		command: {
			name: "sh"
			flags: "-c": """
				cat <<EOT >> ~/.npmrc
				\(node.npmrc)
				EOT
				npm install -g pnpm
				pnpm --version
				pnpm config list
				pnpm install
				./node_modules/.bin/vite build --mode=production --config=\(vite.config) --outDir=/output
				"""
		}
		export: directories: "/output": _
	}

	output: _run.export.directories."/output"
}

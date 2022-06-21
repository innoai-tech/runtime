package libify

import (
	"path"

	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#Project: {
	module:  string
	version: string
	name:    string | *path.Base(module)

	revision: string | *string

	target: {
		arch: [...string]
		include: [...string]
		lib: [...string]
	}

	mirror: crutil.#Mirror

	base: {
		source: string
	}

	packages: [Name=string]: string | *""

	ship: crutil.#Ship & {
		tag: version

		config: {
			label: {
				"org.opencontainers.image.source":   "https://\(module)"
				"org.opencontainers.image.revision": "\(revision)"
			}
			cmd: []
			entrypoint: []
		}

		platforms: [
			for arch in target.arch {
				"linux/\(arch)"
			},
		]

		image: {
			steps: [
				#Diff & {
					"base":     base
					"mirror":   mirror
					"packages": packages
				},
				#Extract & {
					"name":    name
					"include": target.include
					"lib":     target.lib
				},
			]
		}
	}
}

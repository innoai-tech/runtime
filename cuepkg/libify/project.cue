package libify

import (
	"path"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
	"github.com/innoai-tech/runtime/cuepkg/debian"
)

#Project: imagetool.#Project & {
	module:   string
	name:     string | *path.Base(module)
	version:  _
	revision: _

	target: {
		arch: [...string]
		include: [...string]
		lib: [...string]
	}

	base: {
		source: string
	}

	packages: [Name=string]: debian.#PackageOption

	ship: {
		tag: "\(version)"

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

		steps: [
			#Diff & {
				"base":     base
				"packages": packages
				"mirror": ship.mirror
				"auths":  ship.auths
			},
			#Extract & {
				"name":    name
				"include": target.include
				"lib":     target.lib
			},
		]
	}
}

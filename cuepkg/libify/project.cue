package libify

import (
	"strings"
	"path"
	"text/template"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"

	"github.com/innoai-tech/runtime/cuepkg/debian"
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
				#InstallDiff & {
					"mirror":   mirror
					"packages": packages
				},
				#Pick & {
					dests: {
						"/usr/shared/\(name)/{{ .TARGETARCH }}/\(name)/include": target.include
						"/usr/shared/\(name)/{{ .TARGETARCH }}/\(name)/lib":     target.lib
					}
				},
			]
		}
	}
}

#InstallDiff: {
	input:  docker.#Image
	output: docker.#Image

	mirror: crutil.#Mirror
	packages: [Name=string]: string | *""

	_base: debian.#Build & {
		platform: input.platform
		"mirror": mirror
	}

	_install: debian.#InstallPackage & {
		input:      _base.output
		"packages": packages
	}

	_diff: core.#Diff & {
		"lower": _install.input.rootfs
		"upper": _install.output.rootfs
	}

	output: docker.#Image & {
		rootfs:   _diff.output
		platform: input.platform
		config: {}
	}
}

#Pick: {
	input: docker.#Image
	dests: [Dir=string]: [...string]

	_platform: "\(input.platform)"

	_ctx: {
		TARGETPLATFORM: "\(_platform)"
		TARGETOS:       "\(strings.Split(_platform, "/")[0])"
		TARGETARCH:     "\(strings.Split(_platform, "/")[1])"
		TARGETGNUARCH:  {
			"amd64": "x86_64"
			"arm64": "aarch64"
		}["\(TARGETARCH)"]
	}

	_mv: {
		for dest, include in dests for from in include {
			"\(from) => \(dest)": core.#Copy & {
				"input":    dagger.#Scratch
				"contents": input.rootfs
				"dest":     template.Execute("\(dest)", _ctx)
				"source":   template.Execute("\(from)", _ctx)
			}
		}
	}

	_merge: core.#Merge & {
		inputs: [
			for d in _mv {
				d.output
			},
		]
	}

	_flat: core.#Copy & {
		"input":    dagger.#Scratch
		"contents": _merge.output
		"dest":     "/"
		"source":   "/"
	}

	output: docker.#Image & {
		rootfs:   _flat.output
		platform: input.platform
		config: {}
	}
}

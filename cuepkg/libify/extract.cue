package libify

import (
	"strings"
	"text/template"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"

	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#Extract: {
	name: string
	include: [...string]
	lib: [...string]

	input: docker.#Image

	_ctx: {
		TARGETPLATFORM: "\(input.platform)"
		TARGETOS:       "\(strings.Split(input.platform, "/")[0])"
		TARGETARCH:     "\(strings.Split(input.platform, "/")[1])"
		TARGETGNUARCH:  crutil.#GnuArch["\(TARGETARCH)"]
	}

	_dirs: {
		"/usr/pkg/\(name)/{{ .TARGETARCH }}/include": include
		"/usr/pkg/\(name)/{{ .TARGETARCH }}/lib":     lib
	}

	_mv: {
		for dest, include in _dirs for from in include {
			"\(from)/* => \(dest)": core.#Copy & {
				"input":    dagger.#Scratch
				"contents": input.rootfs
				"source":   template.Execute("\(from)", _ctx)
				"dest":     template.Execute("\(dest)", _ctx)
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

	_busybox: docker.#Pull & {
		source: "busybox"
	}

	_ln: crutil.#Script & {
		input: docker.#Image & {
			rootfs:   _merge.output
			platform: input.platform
			config: {}
		}
		mounts: {
			busybox: core.#Mount & {
				dest:     "/busybox"
				contents: _busybox.output.rootfs
			}
		}
		workdir: "/usr/pkg/\(name)"
		env: "PATH": "/busybox/bin"
		run: [
			"ln -s ./\(_ctx.TARGETARCH)/lib ./lib",
			"ln -s ./\(_ctx.TARGETARCH)/include ./include",
		]
	}

	_flat: core.#Copy & {
		"input":    dagger.#Scratch
		"contents": _ln.output.rootfs
		"dest":     "/"
		"source":   "/"
		"include": [
			"usr/pkg",
		]
	}

	output: docker.#Image & {
		rootfs:   _flat.output
		platform: input.platform
		config: {}
	}
}

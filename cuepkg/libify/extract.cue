package libify

import (
	"strings"
	"text/template"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
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
		TARGETGNUARCH:  imagetool.#GnuArch["\(TARGETARCH)"]
	}

	_dirs: {
		"/usr/local/pkg/\(name)/{{ .TARGETARCH }}/include": include
		"/usr/local/pkg/\(name)/{{ .TARGETARCH }}/lib":     lib
	}

	_mv: {
		for dest, include in _dirs for from in include {
			"\(from)/* => \(dest)": core.#Copy & {
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

	_flat: core.#Copy & {
		"contents": _merge.output
		"dest":     "/"
		"source":   "/"
		"include": [
			"usr/local/pkg",
		]
	}

	output: docker.#Image & {
		rootfs:   _flat.output
		platform: input.platform
		config: {}
	}
}

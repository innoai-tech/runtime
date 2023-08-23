package libify

import (
	"strings"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

	"github.com/innoai-tech/runtime/cuepkg/debian"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#Diff: {
	input:  docker.#Image
	output: docker.#Image

	name: string
	base: source: string

	auths: [Host=string]: imagetool.#Auth

	packages: [Name=string]: debian.#PackageOption

	_base: imagetool.#Pull & {
		"source": base.source
		"auths":  auths
	}

	_pkg: debian.#Build & {
		"platform": input.platform
		"packages": packages
		"auths": auths
	}

	_ctx: {
		TARGETPLATFORM: "\(input.platform)"
		TARGETOS:       "\(strings.Split(input.platform, "/")[0])"
		TARGETARCH:     "\(strings.Split(input.platform, "/")[1])"
		TARGETGNUARCH:  imagetool.#GnuArch["\(TARGETARCH)"]
	}

	_ln: imagetool.#Script & {
		input:   _pkg.output
		workdir: "/usr/local/pkg/\(name)"
		run: [
			"pwd",
			"ln -s ./\(_ctx.TARGETARCH)/lib ./lib",
			"ln -s ./\(_ctx.TARGETARCH)/include ./include",
		]
	}

	_diff: core.#Diff & {
		"lower": _base.output.rootfs
		"upper": _ln.output.rootfs
	}

	output: docker.#Image & {
		rootfs:   _diff.output
		platform: input.platform
		config: {}
	}
}

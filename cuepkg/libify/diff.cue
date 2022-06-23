package libify

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"

	"github.com/innoai-tech/runtime/cuepkg/debian"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#Diff: {
	input:  docker.#Image
	output: docker.#Image

	base: source: string

	mirror: imagetool.#Mirror
	auths: [Host=string]: imagetool.#Auth

	packages: [Name=string]: debian.#PackageOption

	_base: imagetool.#Pull & {
		"source": base.source
		"mirror": mirror
		"auths":  auths
	}

	_pkg: debian.#Build & {
		"platform": input.platform
		"packages": packages

		"mirror": mirror
		"auths":  auths
	}

	_diff: core.#Diff & {
		"lower": _base.output.rootfs
		"upper": _pkg.output.rootfs
	}

	output: docker.#Image & {
		rootfs:   _diff.output
		platform: input.platform
		config: {}
	}
}

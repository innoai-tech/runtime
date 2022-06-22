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
	packages: [Name=string]: string | *""

	_base: docker.#Pull & {
		"source": "\(mirror.pull)\(base.source)"
	}

	_pkg: debian.#Build & {
		"platform": input.platform
		"mirror":   mirror
		"packages": packages
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

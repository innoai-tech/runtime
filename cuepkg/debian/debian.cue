package debian

import (

	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#Version: "bullseye" // debian 11

#ImageBase: {
	packages: [pkgName=string]: string | *""
	mirror: crutil.#Mirror
	steps: [...docker.#Step]
	auth?: crutil.#Auth
	...
}

#Build: #ImageBase & {
	source:    string | *"docker.io/library/debian:\(#Version)-slim"
	platform?: string

	packages: _
	mirror:   _
	steps:    _
	auth?:    _

	_base: docker.#Pull & {
		"source": "\(mirror.pull)\(source)"

		if platform != _|_ {
			"platform": platform
		}

		if auth != _|_ {
			"auth": auth
		}
	}

	_build: docker.#Build & {
		"steps": [
			{
				output: _base.output
			},
			#ConfigMirror & {
				"mirror": mirror
			},
			#InstallPackage & {
				"packages": packages
			},
			for step in steps {
				step
			},
		]
	}

	output: _build.output
}

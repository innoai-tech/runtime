package debian

import (

	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#Version: "bullseye" // debian 11


#ImageBase: {
	packages: [pkgName=string]: #PackageOption
	mirror: crutil.#Mirror
	steps: [...docker.#Step]
	auth?: crutil.#Auth
	...
}

#Build: #ImageBase & {
	source: string | *"docker.io/library/debian:\(#Version)-slim"

	packages: _
	mirror:   _
	steps:    _
	auth?:    _

	platform?: string

	_build: crutil.#Build & {
		"source": "\(source)"

		if platform != _|_ {
			"platform": platform
		}

		if auth != _|_ {
			"auth": auth
		}

		"mirror": mirror

		"steps": [
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

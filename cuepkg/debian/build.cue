package debian

import (

	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#Version: "bullseye" // debian 11

#ImageBase: {
	packages: [pkgName=string]: #PackageOption
	mirror: imagetool.#Mirror
	steps: [...docker.#Step]
	auths: [Host=string]: imagetool.#Auth
	...
}

#Build: #ImageBase & {
	source: string | *"docker.io/library/debian:\(#Version)-slim"

	packages: _
	mirror:   _
	steps:    _
	auths:    _

	platform?: string

	_build: imagetool.#Build & {
		if platform != _|_ {
			"platform": platform
		}
		"from":   "\(source)"
		"auths":  auths
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

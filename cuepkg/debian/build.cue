package debian

import (
	"wagon.octohelm.tech/docker"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#Version: "bullseye" // debian 11

#ImageBase: {
	packages: [pkgName=string]: #PackageOption
	steps: [...docker.#Step]
	mirror: imagetool.#Mirror
	auths: [Host=string]: imagetool.#Auth
	...
}

#Build: #ImageBase & {
	debianversion: string | *#Version
	source:        string | *"docker.io/library/debian:\(debianversion)-slim"

	packages: _
	steps:    _
	auths:  _

	platform?: string

	_pull: imagetool.#Pull & {
		"source": "\(source)"
		"auths":  auths
		if platform != _|_ {
			"platform": platform
		}
	}

	_packages: #InstallPackage & {
		input:      _pull.output
		"packages": packages
	}

	_debian: docker.#Build & {
		"steps": [
			{
				output: _packages.output
			},
			for step in steps {
				step
			},
		]
	}

	output: _debian.output
}

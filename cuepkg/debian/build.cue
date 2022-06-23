package debian

import (

	"universe.dagger.io/docker"
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
	source: string | *"docker.io/library/debian:\(#Version)-slim"

	packages: _
	steps:    _

	mirror: _
	auths:  _

	platform?: string

	_pull: imagetool.#Pull & {
		"source": "\(source)"
		"auths":  auths
		"mirror": mirror
		if platform != _|_ {
			"platform": platform
		}
	}

	_config_mirror: imagetool.#Shell & {
		input: _pull.output
		env: {
			LINUX_MIRROR: mirror.linux
		}
		run: """
				if [ "${LINUX_MIRROR}" != "" ]; then
					sed -i "s@http://deb.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
					sed -i "s@http://security.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
				fi
			"""
	}

	_packages: #InstallPackage & {
		input:      _config_mirror.output
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

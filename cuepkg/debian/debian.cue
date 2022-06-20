package debian

import (
	"dagger.io/dagger/core"

	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#Version: "bullseye"

#LinuxMirror: {
	ustc:        "http://mirrors.ustc.edu.cn"
	huaweicloud: "http://repo.huaweicloud.com"
}

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
			#InstallPackage & {
				"packages": packages
				"mirror":   mirror
			},
			for step in steps {
				step
			},
		]
	}

	output: _build.output
}

#InstallPackage: {
	input:  docker.#Image
	output: docker.#Image

	packages: [pkgName=string]: string | *""
	mirror: crutil.#Mirror

	if len(packages) == 0 {
		output: input
	}

	if len(packages) > 0 {
		_install: crutil.#Script & {
			"input": input
			mounts: {
				"apt_lists": core.#Mount & {
					dest:     "/var/lib/apt/lists"
					contents: core.#CacheDir & {
						id: "\(input.platform)/apt_lists"
					}
				}
				"apt_cache": core.#Mount & {
					dest:     "/var/apt/cache"
					contents: core.#CacheDir & {
						id: "\(input.platform)/apt_cache"
					}
				}
			}
			env: {
				LINUX_MIRROR: mirror.linux
			}
			run: [
				"""
					if [ ${LINUX_MIRROR} != "" ]; then
						sed -i "s@http://deb.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
						sed -i "s@http://security.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
					fi
					apt-get update -y
					""",
				for _pkgName, _version in packages {
					"apt-get install -y -f \(_pkgName)\(_version)"
				},
			]
		}

		output: _install.output
	}
}

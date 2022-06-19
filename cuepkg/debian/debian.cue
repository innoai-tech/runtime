package debian

import (
	"dagger.io/dagger/core"

	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#Version: "bullseye"

#Mirror: {
	ustc:        "http://mirrors.ustc.edu.cn"
	huaweicloud: "http://repo.huaweicloud.com"
}

#Build: {
	source:    string | *"index.docker.io/debian:\(#Version)-slim"
	platform?: string
	steps: [...docker.#Step]

	packages: [pkgName=string]: string | *""
	mirror: string | *""

	_base: docker.#Pull & {
		"source": source
		if platform != _|_ {
			"platform": platform
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
	mirror: string | *""

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
						id: "apt_lists"
					}
				}
				"apt_cache": core.#Mount & {
					dest:     "/var/apt/cache"
					contents: core.#CacheDir & {
						id: "apt_cache"
					}
				}
			}
			env: {
				LINUX_MIRROR: mirror
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

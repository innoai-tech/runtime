package debian

import (
	"dagger.io/dagger/core"

	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#ConfigMirror: {
	mirror: crutil.#Mirror

	crutil.#Script & {
		name: "config linux mirror"
		env: {
			LINUX_MIRROR: mirror.linux
		}
		run: [
			"""
				if [ ${LINUX_MIRROR} != "" ]; then
					sed -i "s@http://deb.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
					sed -i "s@http://security.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
				fi
				""",
		]
	}
}

#PackageOption: {
	platform?: string
	version:   string | *""
}

#InstallPackage: {
	input:  docker.#Image
	output: docker.#Image

	packages: [pkgName=string]: #PackageOption

	if len(packages) == 0 {
		output: input
	}

	if len(packages) > 0 {
		_dirs: {
			"varlog":    "/var/log"
			"apt_cache": "/var/apt/cache"
			//             "apt_lists": "/var/lib/apt/lists"
		}

		_install: crutil.#Script & {
			"name":  "install package"
			"input": input
			mounts: {
				for id, dir in _dirs {
					"\(id)": core.#Mount & {
						dest:     "\(dir)"
						contents: core.#CacheDir & {
							"id": "\(input.platform)/\(id)"
						}
					}
				}
			}
			run: [
				"apt-get update -y",
				for _pkgName, _opt in packages {
					[
						// only install platform matched
						if _opt.platform != _|_ if _opt.platform == input.platform {
							"apt-get install -y -f \(_pkgName)\(_opt.version)"
						},
						"apt-get install -y -f \(_pkgName)\(_opt.version)",
					][0]
				},
			]
		}

		output: _install.output
	}
}

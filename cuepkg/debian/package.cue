package debian

import (
	"dagger.io/dagger/core"

	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#PackageOption: {
	platform?: string
	version:   string | *""
}

#InstallPackage: {
	input:  docker.#Image
	output: docker.#Image

	packages: [pkgName=string]: #PackageOption

	_install: {
		if len(packages) == 0 {
			output: input
		}

		if len(packages) > 0 {
			_dirs: {
				"varlog":    "/var/log"
				"apt_cache": "/var/apt/cache"
				//             "apt_lists": "/var/lib/apt/lists"
			}

			imagetool.#Script & {
				"input": input
				"mounts": {
					for id, dir in _dirs {
						"\(id)": core.#Mount & {
							dest:     "\(dir)"
							contents: core.#CacheDir & {
								"id": "\(input.platform)/\(id)"
							}
						}
					}
				}
				"run": [
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
		}
	}

	output: _install.output
}

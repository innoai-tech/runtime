package imagetool

import (
	"strings"
	"path"

	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#ImageDep: {
	input: docker.#Image
	dependences: [Path=string]: string
	auths: [Host=string]:       #Auth
	mirror: #Mirror

	_platform: core.#Nop & {
		"input": input.platform
	}

	platforms: [...string]

	_pull: {
		if len(platforms) > 0 {
			for name, version in dependences for platform in platforms {
				"\(name):\(version) for \(platform)": {
					#Pull & {
						"auths":    auths
						"platform": platform
						"source":   (#SourcePatch & {
							"source": "\(name):\(version)"
							"mirror": mirror
						}).output
					}
				}
			}
		}
		if len(platforms) == 0 {
			for name, version in dependences {
				"\(name):\(version)": {
					#Pull & {
						"source": (#SourcePatch & {
							"source": "\(name):\(version)"
							"mirror": mirror
						}).output

						"auths": auths

						if _platform.output != _|_ {
							"platform": _platform.output
						}
					}
				}
			}
		}
	}

	_dep: docker.#Build & {
		steps: [
			{
				output: input
			},
			for _id, _p in _pull {
				docker.#Copy & {
					"contents": _p.output.rootfs
					"dest":     "/"
					"source":   "/"
				}
			},
			docker.#Set & {
				"config": {
					env: {
						"LD_LIBRARY_PATH": strings.Join([ for n, v in dependences {
							"/usr/local/pkg/\(path.Base(n))/\(strings.Split(input.platform, "/")[1])/lib"
						}], ":")
					}
					for platform in platforms {
						let _arch = strings.ToUpper(strings.Split(platform, "/")[1])

						env: "LD_LIBRARY_PATH_\(_arch)": strings.Join([ for n, v in dependences {
							"/usr/local/pkg/\(path.Base(n))/\(strings.Split(platform, "/")[1])/lib"
						}], ":")
					}
				}
			},
		]
	}

	output: _dep.output
}

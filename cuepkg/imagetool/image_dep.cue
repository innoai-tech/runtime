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
						"auths":  auths
						"mirror": mirror

						"platform": platform
						"source":   "\(name):\(version)"
					}
				}
			}
		}
		if len(platforms) == 0 {
			for name, version in dependences {
				"\(name):\(version)": {
					#Pull & {
						"source": "\(name):\(version)"

						"auths":  auths
						"mirror": mirror

						if _platform.output != _|_ {
							"platform": _platform.output
						}
					}
				}
			}
		}
	}

	_values: [
		for _id, _p in _pull {
			_id
		},
	]

	_dep: {
		"0": {
			output: input
		}

		for i, id in _values {
			"\(i+1)": {
				_out:      _dep["\(i)"].output
				_contents: _pull["\(id)"].output.rootfs

				docker.#Copy & {
					"input":    _out
					"contents": _contents
					"dest":     "/"
					"source":   "/"
				}
			}
		}
	}

	// _output: _dep["\(len(_dep)-1)"].output

	_config: docker.#Set & {
		input: _dep["\(len(_dep)-1)"].output
		config: {
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
	}

	output: _config.output
}

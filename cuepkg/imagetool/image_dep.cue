package imagetool

import (
	"strings"
	"path"
	"universe.dagger.io/docker"
)

#ImageDep: {
	input: docker.#Image | *docker.#Scratch
	dependences: [Path=string]: string
	auths: [Host=string]:       #Auth
	mirror:    #Mirror
	platforms: [...string] | *[input.platform]

	_dep: {
		for name, version in dependences {
			"\(name):\(version)": {
				for platform in platforms {
					"\(platform)": #Pull & {
						"platform": platform
						"auths":    auths
						"source":   "\(mirror.pull)\(name):\(version)"
					}
				}
			}
		}
	}

	_imageDep: docker.#Build & {
		steps: [
			{
				output: input
			},
			for name, version in dependences for platform in platforms {
				docker.#Copy & {
					contents: _dep["\(name):\(version)"]["\(platform)"].output.rootfs
					dest:     "/"
				}
			},
			docker.#Set & {
				config: {
					env: {
						"LD_LIBRARY_PATH": strings.Join([ for n, v in dependences {
							"/usr/pkg/\(path.Base(n))/\(strings.Split(input.platform, "/")[1])/lib"
						}], ":")
					}

					for platform in platforms {
						let _arch = strings.ToUpper(strings.Split(platform, "/")[1])
						env: "LD_LIBRARY_PATH_\(_arch)": strings.Join([ for n, v in dependences {
							"/usr/pkg/\(path.Base(n))/\(strings.Split(platform, "/")[1])/lib"
						}], ":")
					}
				}
			},
		]
	}

	output: _imageDep.output
}

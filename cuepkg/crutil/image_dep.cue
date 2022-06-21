package crutil

import (
	"strings"
	"path"
	"universe.dagger.io/docker"
)

#ImageDep: {
	input: docker.#Image | *docker.#Scratch
	dependences: [Path=string]: string
	auth?:  #Auth
	mirror: #Mirror

	_dep: {
		for name, version in dependences {
			"\(name):\(version)": docker.#Pull & {
				if auth != _|_ {
					"auth": auth
				}
				if (input.platform != _|_) {
					"platform": input.platform
				}
				"source": "\(mirror.pull)\(name):\(version)"
			}
		}
	}

	_imageDep: docker.#Build & {
		steps: [
			{
				output: input
			},
			for name, version in dependences {
				docker.#Copy & {
					contents: _dep["\(name):\(version)"].output.rootfs
					dest:     "/"
				}
			},
			docker.#Set & {
				config: {
					env: {
						LD_LIBRARY_PATH: strings.Join([ for n, v in dependences {
							"/usr/pkg/\(path.Base(n))/\(strings.Split(input.platform, "/")[1])/lib"
						}], ":")
					}
				}
			},
		]
	}

	output: _imageDep.output
}

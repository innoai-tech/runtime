package crutil

import (
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
		]
	}

	output: _imageDep.output
}

package crutil

import (
	"universe.dagger.io/docker"
)

#ImageDep: {
	input: docker.#Image | *docker.#Scratch
	dependences: [Path=string]: string
	auth?: #Auth

	_platform: "\(input.platform)"

	_build: docker.#Build & {
		steps: [
			{
				output: input
			},
			for name, version in dependences {
				_dep: {
					"\(name):\(version)": docker.#Pull & {
						if auth != _|_ {
							"auth": {
								username: auth.username
								secret:   auth.secret
							}
						}
						source:   "\(name):\(version)"
						platform: "\(_platform)"
					}
				}

				docker.#Copy & {
					contents: _dep["\(name):\(version)"].output.rootfs
					dest:     "/"
				}
			},
		]
	}

	output: _build.output
}

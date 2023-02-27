package imagetool

import (
	"wagon.octohelm.tech/docker"
)

#Build: {
	from:      string | *""
	platform?: string
	steps: [...docker.#Step]

	auths: [Host=string]: #Auth
	mirror: #Mirror

	_dag: "0": {
		if from != "" {
			#Pull & {
				"source": "\(from)"
				"auths":  auths
				"mirror": mirror

				if platform != _|_ {
					"platform": platform
				}
			}
		}

		if from == "" {

			if platform == _|_ {
				_busybox: #Pull & {
					"source": "docker.io/library/busybox:latest"
					"auths":  auths
					"mirror": mirror
				}

				output: docker.#Scratch & {
					"platform": _busybox.output.platform
				}
			}

			if platform != _|_ {
				output: docker.#Scratch & {
					"platform": platform
				}
			}
		}
	}

	_dag: {
		for idx, step in steps {
			"\(idx+1)": {
				_output: _dag["\(idx)"].output

				step & {
					input: _output
				}
			}
		}
	}

	output: _dag["\(len(_dag)-1)"].output
}

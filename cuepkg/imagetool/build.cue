package imagetool

import (
	"universe.dagger.io/docker"
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
			_busybox: #Pull & {
				"source": "docker.io/library/busybox"

				"auths":  auths
				"mirror": mirror

				if platform != _|_ {
					"platform": platform
				}
			}

			output: docker.#Scratch & {
				if _busybox.output.platform != _|_ {
					"platform": _busybox.output.platform
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

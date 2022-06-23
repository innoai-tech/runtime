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
				"source": (#SourcePatch & {"mirror": mirror, "source": from}).output
				"auths":  auths

				if platform != _|_ {
					"platform": platform
				}
			}
		}

		if from == "" {
			_busybox: #Pull & {
				"source": (#SourcePatch & {"mirror": mirror, "source": "docker.io/library/busybox"}).output
				"auths":  auths

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
			"\(idx+1)": step & {
				_output: _dag["\(idx)"].output
				input:   _output
			}
		}
	}

	output: _dag["\(len(_dag)-1)"].output
}
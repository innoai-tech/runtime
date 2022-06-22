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

	_image: [
		if from != "" {
			#Pull & {
				"source": "\(mirror.pull)\(from)"
				"auths":  auths
				if platform != _|_ {
					"platform": platform
				}
			}
		},
		{
			output: docker.#Scratch & {
				if platform != _|_ {
					"platform": platform
				}
			}
		},
	][0]

	_dag: {
		"0": {
			output: _image.output
		}
		for idx, step in steps {
			"\(idx+1)": step & {
				_output: _dag["\(idx)"].output
				input:   _output
			}
		}
	}

	output: _dag["\(len(_dag)-1)"].output
}

package crutil

import (
	"universe.dagger.io/docker"
)

#Build: {
	source:    string | *""
	platform?: string
	auth?:     #Auth

	steps: [...docker.#Step]

	_image: [
		if source != "" {
			docker.#Pull & {
				if platform != _|_ {
					"platform": platform
				}
				if auth != _|_ {
					"auth": auth
				}
				"source": source
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
		for idx, step in steps {
			"\(idx)": step & {
				if idx == 0 {
					input: _image.output
				}
				if idx > 0 {
					_output: _dag["\(idx-1)"].output
					input:   _output
				}
			}
		}
	}

	if len(_dag) == 0 {
		output: _image
	}
	if len(_dag) > 0 {
		output: _dag["\(len(_dag)-1)"].output
	}
}

package imagetool

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/docker"
)

#Script: {
	input:  docker.#Image
	output: docker.#Image

	name: string | *"script"

	mounts: [Name=string]: core.#Mount
	env: [string]:         string | dagger.#Secret
	workdir?: string
	user?:    string
	always?:  bool

	run: [...string]

	_run: "\(name)": {
		"0": {
			output: input
		}

		for idx, script in run {
			"\(idx+1)": docker.#Step & {
				_input: _run["\(name)"]["\(idx)"].output

				docker.#Run & {
					input: _input

					if workdir != _|_ {
						"workdir": workdir
					}
					if user != _|_ {
						"user": user
					}
					if always != _|_ {
						"always": always
					}

					"env":    env
					"mounts": mounts

					command: name: "sh"
					command: flags: "-c": script
				}
			}
		}
	}

	output: _run["\(name)"]["\(len(_run["\(name)"])-1)"].output
}

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
	run: [...string]

	mounts: [Name=string]: core.#Mount
	env: [string]:         string | dagger.#Secret
	workdir?: string
	user?:    string
	always?:  bool

	_run: "\(name)": {
		"0": output: input

		for idx, script in run {
			"\(idx+1)": {
				_output: _run["\(name)"]["\(idx)"].output

				#Shell & {
					"input":  _output
					"run":    script
					"env":    env
					"mounts": mounts
					if workdir != _|_ {
						"workdir": workdir
					}
					if user != _|_ {
						"user": user
					}
					if always != _|_ {
						"always": always
					}
				}
			}
		}
	}

	output: _run["\(name)"]["\(len(_run["\(name)"])-1)"].output
}

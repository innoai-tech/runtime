package crutil

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
		for idx, script in run {
			"\(idx)": docker.#Step & {
				_input: docker.#Image

				if idx == 0 {
					_input: input
				}
				if idx > 0 {
					_input: _run["\(name)"]["\(idx-1)"].output
				}

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

	if len(_run["\(name)"]) == 0 {
		output: input
	}

	if len(_run["\(name)"]) > 0 {
		output: _run["\(name)"]["\(len(_run["\(name)"])-1)"].output
	}
}

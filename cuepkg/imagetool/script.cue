package imagetool

import (
	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"
)

#Script: {
	input:  docker.#Image
	output: docker.#Image

	name: string | *"script"
	run: [...string]

	mounts: [Name=string]: core.#Mount
	shell: string | *"sh"
	env: [string]: string | core.#Secret
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
					"shell":  shell
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

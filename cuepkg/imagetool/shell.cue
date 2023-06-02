package imagetool

import (
	"wagon.octohelm.tech/docker"
)

#Shell: {
	shell: string | *"sh"
	run:   string

	docker.#Run & {
		"command": {
			"name": "\(shell)"
			"flags": "-c": "\(run)"
		}
	}
}

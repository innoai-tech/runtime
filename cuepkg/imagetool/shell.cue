package imagetool

import (
	"wagon.octohelm.tech/docker"
)

#Shell: {
	run: string

	docker.#Run & {
		"command": {
			"name": "sh"
			"flags": "-c": "\(run)"
		}
	}
}

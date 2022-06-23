package imagetool

import (
	"universe.dagger.io/docker"
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

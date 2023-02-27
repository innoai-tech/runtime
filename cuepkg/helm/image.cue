package helm

import (
	"wagon.octohelm.tech/docker"
)

#Image: {
	version: string | *"latest"

	docker.#Pull & {
		source: "docker.io/alpine/helm:\(version)"
	}
}

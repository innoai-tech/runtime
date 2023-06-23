package helm

import (
	"wagon.octohelm.tech/docker"
)

#Image: {
	version: string | *"3.12.1"

	docker.#Pull & {
		source: "docker.io/alpine/helm:\(version)"
	}
}

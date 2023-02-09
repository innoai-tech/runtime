package kubepkg

import (
	"universe.dagger.io/docker"
)

#DefaultTag: "main@sha256:254b71fd3e0f556ed7c8260c78a4b0a33b59f6a24293521a24553ed4c2b71359"

#Image: {
	tag: string | *#DefaultTag

	docker.#Pull & {
		source: "ghcr.io/octohelm/kubepkg:\(tag)"
	}
}

package kubepkg

import (
	"universe.dagger.io/docker"
)

#DefaultTag: "0.1.1"

#Run: {
	tag: string | *#DefaultTag

	_image: #Image & {
		"tag": "\(tag)"
	}

	docker.#Run & {
		input:   _image.output
		workdir: "/build"
	}
}

#Image: {
	tag: string | *#DefaultTag

	docker.#Pull & {
		source: "ghcr.io/octohelm/kubepkg:\(tag)"
	}
}

package golang

import "github.com/innoai-tech/runtime/cuepkg/debian"

#Image: {
	goversion: string | *"1.18"

	debian.#Build & {
		source: "docker.io/library/golang:\(goversion)-\(debian.#Version)"
	}
}

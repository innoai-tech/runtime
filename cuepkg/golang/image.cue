package golang

import "github.com/innoai-tech/runtime/cuepkg/debian"

#Image: {
	goversion:     string
	debianversion: string | *debian.#Version

	packages: {}

	debian.#Build & {
		source: "docker.io/library/golang:\(goversion)-\(debianversion)"
	}
}

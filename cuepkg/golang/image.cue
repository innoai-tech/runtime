package golang

import "github.com/innoai-tech/runtime/cuepkg/debian"

#Image: {
	goversion:     string
	debianversion: string | *debian.#Version
	from:          string | *"docker.io/library/golang:\(goversion)-\(debianversion)"

	packages: {}

	debian.#Build & {
		source: "\(from)"
	}
}

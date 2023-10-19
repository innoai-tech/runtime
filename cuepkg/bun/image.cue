package bun

import "github.com/innoai-tech/runtime/cuepkg/debian"

#Image: {
	bunversion: string | *"1"

	debian.#Build & {
		source: "docker.io/oven/bun:\(bunversion)"
	}
}

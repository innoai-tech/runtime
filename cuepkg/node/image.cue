package node

import "github.com/innoai-tech/runtime/cuepkg/debian"

#Image: {
	node: string | *"18"

	packages: {
		"build-dep": _
	}

	debian.#Build & {
		source: "node:\(node)-\(debian.#Version)"
	}
}

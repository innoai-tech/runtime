package golang

import "github.com/innoai-tech/runtime/cuepkg/debian"

#Image: {
	go: string | *"1.18"

	debian.#Build & {
		source: "golang:\(go)-\(debian.#Version)"
	}
}

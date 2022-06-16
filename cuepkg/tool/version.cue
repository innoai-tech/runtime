package tool

import (
	"strings"

	"dagger.io/dagger/core"
)

#ResolveVersion: {
	ref:     string | *""
	version: string | *""

	core.#Nop & {
		input: [
			if strings.HasPrefix(ref, "refs/tags/v") {
				strings.TrimPrefix(ref, "refs/tags/v")
			},
			if strings.HasPrefix(ref, "refs/heads/") {
				strings.TrimPrefix(ref, "refs/heads/")
			},
			version,
		][0]
	}
}

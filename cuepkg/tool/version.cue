package tool

import "strings"

#ResolveVersion: {
	ref:     string | *""
	version: string | *""

	output: [
		if strings.HasPrefix(ref, "refs/tags/v") {
			strings.TrimPrefix(ref, "refs/tags/v")
		},
		if strings.HasPrefix(ref, "refs/heads/") {
			strings.TrimPrefix(ref, "refs/heads/")
		},
		version,
	][0]
}

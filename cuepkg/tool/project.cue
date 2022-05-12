package tool

import (
	"strings"
)

#ParseVersion: {
	#ref:     string
	#version: string

	[
		if strings.HasPrefix(#ref, "refs/tags/v") {
			strings.TrimPrefix(#ref, "refs/tags/v")
		},
		if strings.HasPrefix(#ref, "refs/heads/") {
			strings.TrimPrefix(#ref, "refs/heads/")
		},
		#version,
	][0]
}

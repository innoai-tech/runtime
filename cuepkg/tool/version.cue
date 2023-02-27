package tool

import (
	"strings"

	"wagon.octohelm.tech/core"
)

#VersionFromGit: {
	ref: string
	sha: string

	_version: strings.Replace([
			if strings.HasPrefix("\(ref)", "refs/tags/v") {
			strings.TrimPrefix("\(ref)", "refs/tags/v")
		},
		if strings.HasPrefix("\(ref)", "refs/heads/") {
			strings.TrimPrefix("\(ref)", "refs/heads/")
		},
		ref,
	][0], "/", "-", -1)

	_tag: "\(_version)\([
		if len(sha) >= 8 {
			"-\(strings.SliceRunes(sha, 0, 8))"
		},
		"",
	][0])"

	version: _version @wagon(generated)
	tag:     _tag     @wagon(generated)
}

#ResolveVersion: {
	ref:     string | *""
	version: string | *""

	core.#Nop & {
		input: [
			if strings.HasPrefix("\(ref)", "refs/tags/v") {
				strings.TrimPrefix("\(ref)", "refs/tags/v")
			},
			if strings.HasPrefix("\(ref)", "refs/heads/") {
				strings.Replace(strings.TrimPrefix("\(ref)", "refs/heads/"), "/", "-", -1)
			},
			version,
		][0]
	}
}

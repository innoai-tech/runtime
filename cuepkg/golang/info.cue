package golang

import (
	"regexp"

	"wagon.octohelm.tech/core"
)

#Info: {
	source: core.#FS

	_read_gomod: core.#ReadFile & {
		input: source
		path:  "go.mod"
	}

	module: regexp.FindSubmatch(#"module (.+)\n"#, _read_gomod.contents)[1]
	go:     regexp.FindSubmatch(#"\ngo (.+)\n?"#, _read_gomod.contents)[1]
}

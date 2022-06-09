package golang

import (
	"regexp"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
)

#Info: {
	source: dagger.#FS

	_gomod: core.#ReadFile & {
		input: source
		path:  "go.mod"
	}

	go:     regexp.FindSubmatch(#"go (.+)\n"#, _gomod.contents)[1]
	module: regexp.FindSubmatch(#"module (.+)\n"#, _gomod.contents)[1]
}

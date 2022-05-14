package tool

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
)

#Export: {
	inputs: [Path=string]: core.#FS

	_inputs: {
		for _p, _fs in inputs {
			"\(_p)": core.#Copy & {
				input:    dagger.#Scratch
				contents: _fs
				source:   "/"
				dest:     "/\(_p)"
			}
		}
	}

	_merge: core.#Merge & {
		inputs: [
			for _i in _inputs {
				_i.output
			},
		]
	}

	output: _merge.output
}

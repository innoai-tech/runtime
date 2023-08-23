package testing

import "wagon.octohelm.tech/core"

#Expect: {
	actual: _
	expect: _

	output: core.#Print & {
		input: actual & expect
	}
}

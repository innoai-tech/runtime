package node

import (
	"wagon.octohelm.tech/core"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#ConfigPrivateRegistry: {
	scope: string
	host:  string
	token: core.#Secret

	imagetool.#Script & {
		name: "config private registry"
		env: NPM_AUTH_TOKEN: token
		run: [
			"""
			npm config -g set \(scope):registry=https://\(host)/
			npm config -g set //\(host)/:_authToken=${NPM_AUTH_TOKEN}
			""",
		]
	}
}

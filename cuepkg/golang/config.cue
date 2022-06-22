package golang

import (
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

#ConfigGoPrivate: {
	host: string

	auth: imagetool.#Auth & {
		username: _ | *"gitlab-ci-token"
	}

	imagetool.#Script & {
		name: "git config for go private"
		env: {
			CI_JOB_USER:  auth.username
			CI_JOB_TOKEN: auth.secret
		}
		run: [
			"git config --global url.https://${CI_JOB_USER}:${CI_JOB_TOKEN}@\(host)/.insteadOf https://\(host)/",
		]
	}
}

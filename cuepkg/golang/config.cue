package golang

import (
	"github.com/innoai-tech/runtime/cuepkg/crutil"
)

#ConfigGoPrivate: {
	host: string

	auth: crutil.#Auth & {
		username: _ | *"gitlab-ci-token"
	}

	crutil.#Script & {
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

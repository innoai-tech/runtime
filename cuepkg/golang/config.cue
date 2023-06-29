package golang

import (
	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

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
		always: true
		run: [
			"git config --global url.https://${CI_JOB_USER}:${CI_JOB_TOKEN}@\(host)/.insteadOf https://\(host)/",
		]
	}
}

#ConfigGoPrviateGitLabCI: {
	input: docker.#Image

	_env: core.#ClientEnv & {
		GOPRIVATE:    _ | *""
		CI_JOB_USER:  _ | *"gitlab-ci-token"
		CI_JOB_TOKEN: core.#Secret
	}

	_set: #ConfigGoPrivate & {
		"input": input
		host:    _env.GOPRIVATE
		auth: {
			username: _env.CI_JOB_USER
			secret:   _env.CI_JOB_TOKEN
		}
	}

	output: _set.output
}

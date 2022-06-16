package golang

import (
	"dagger.io/dagger"

	"universe.dagger.io/docker"
)

#ConfigGoPrivate: {
	host:  string
	token: string | dagger.#Serect

	docker.#Run & {
		env: {
			CI_JOB_TOKEN: token
		}
		command: {
			name: "sh"
			flags: "-c": """
			git config --global url.https://gitlab-ci-token:${CI_JOB_TOKEN}@\(host)/.insteadOf https://\(host)/
			"""
		}
	}
}

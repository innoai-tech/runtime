package main

import (
	"strings"
	"wagon.octohelm.tech/core"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
	"github.com/innoai-tech/runtime/cuepkg/debian"
	"github.com/innoai-tech/runtime/cuepkg/testing"
)

actions: test: testing.#Test & {
	"rootfs file should contains correct file": {
		_build: debian.#Build & {
			packages: {
				//   "git": _
			}
			steps: [
				imagetool.#Script & {
					name: "skip"
				},
				imagetool.#Script & {
					name: "echo test"
					run: [
						"echo test > /etc/test",
					]
				},
			]
		}

		_contents: core.#ReadFile & {
			input: _build.output.rootfs
			path:  "/etc/test"
		}

		actual: strings.TrimSpace(_contents.contents)
		expect: "test"
	}
}

setting: {
	_env: core.#ClientEnv & {
		GH_USERNAME: string | *""
		GH_PASSWORD: core.#Secret
	}

	setup: core.#Setting & {
		registry: "ghcr.io": auth: {
			username: _env.GH_USERNAME
			secret:   _env.GH_PASSWORD
		}
	}
}

package main

import (
	"encoding/yaml"

	"wagon.octohelm.tech/core"
	"github.com/innoai-tech/runtime/cuepkg/golang"
	"github.com/innoai-tech/runtime/cuepkg/tool"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

client: env: core.#ClientEnv & {
	LINUX_MIRROR:                  string | *""
	CONTAINER_REGISTRY_PULL_PROXY: string | *""

	GIT_REf: string | *"dev"
	GIT_SHA: string | *""

	GH_USERNAME: string | *""
	GH_PASSWORD: core.#Secret

	GOPROXY:   string | *""
	GOPRIVATE: string | *""
	GOSUMDB:   string | *""
}

setting: core.#Setting & {
	registry: "ghcr.io": auth: {
		username: client.env.GH_USERNAME
		secret:   client.env.GH_PASSWORD
	}
}

actions: {
	ver: tool.#VersionFromGit & {
		ref: "\(client.env.GIT_REf)"
		sha: "\(client.env.GIT_SHA)"
	}

	go: golang.#Project & {
		source: {
			path: "."
			include: [
				"cmd/",
				"go.mod",
			]
		}

		version:  "\(ver.version)"
		revision: "\(ver.sha)"

		main: "./cmd/hello"

		// cgo:     true
		// isolate: false

		goos: ["linux", "darwin"]
		goarch: ["amd64", "arm64"]

		env: {
			GOPROXY:   client.env.GOPROXY
			GOPRIVATE: client.env.GOPRIVATE
			GOSUMDB:   client.env.GOSUMDB
		}

		ldflags: [
			"-s -w",
			"-X \(go.module)/pkg/version.Revision=\(go.revision)",
		]

		build: {
			pre: ["go mod download"]
		}

		ship: {
			name: "ghcr.io/innoai-tech/runtime/hello"
			tag:  ver.tag

			steps: [
				imagetool.#ImageDep & {
					dependencies: {
						"ghcr.io/innoai-tech/ffmpeg": "5"
					}
				},
			]
		}
	}
}

actions: test: core.#Nop & {
	input: yaml.Marshal({
		goversion:   actions.go.goversion
		module:      actions.go.module
		imageconfig: actions.go.build."linux/arm64".output.config
	})
}

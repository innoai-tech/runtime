package main

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"github.com/innoai-tech/runtime/cuepkg/golang"
)

dagger.#Plan

client: env: {
	LINUX_MIRROR: string | *""
	GIT_SHA:      string | *""

	GH_USERNAME: string | *""
	GH_PASSWORD: dagger.#Secret

	GOPROXY:   string | *""
	GOPRIVATE: string | *""
	GOSUMDB:   string | *""
}

mirror: {
	linux: client.env.LINUX_MIRROR
}

actions: go: golang.#Project & {
	source: {
		path: "."
		include: [
			"cmd/",
			"go.mod",
		]
	}

	main: "./cmd/hello"

	goos: ["linux", "darwin"]
	goarch: ["amd64", "arm64"]

	env: {
		GOPROXY:   client.env.GOPROXY
		GOPRIVATE: client.env.GOPRIVATE
		GOSUMDB:   client.env.GOSUMDB
	}

	ldflags: [
		"-s -w",
		"-X \(go.module)/pkg/version.Revision=\(client.env.GIT_SHA)",
	]

	build: {
		pre: ["go mod download"]
	}

	build: image: "mirror": mirror

	ship: name: "x.io/examples/hello"
}

actions: test: core.#Nop & {
	input: yaml.Marshal({
		goversion:   actions.go.goversion
		module:      actions.go.module
		imageconfig: actions.go.build."linux/arm64".output.config
	})
}

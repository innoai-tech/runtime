package main

import (
	"encoding/yaml"
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"github.com/innoai-tech/runtime/cuepkg/golang"
)

dagger.#Plan

client: env: {
	LINUX_MIRROR:                  string | *""
	CONTAINER_REGISTRY_PULL_PROXY: string | *""

	GIT_SHA: string | *""

	GH_USERNAME: string | *""
	GH_PASSWORD: dagger.#Secret

	GOPROXY:   string | *""
	GOPRIVATE: string | *""
	GOSUMDB:   string | *""
}

helper: {
	auths: "ghcr.io": {
		username: client.env.GH_USERNAME
		secret:   client.env.GH_PASSWORD
	}
	mirror: {
		linux: client.env.LINUX_MIRROR
		pull:  client.env.CONTAINER_REGISTRY_PULL_PROXY
	}
}

actions: go: golang.#Project & {
	mirror: helper.mirror
	auths:  helper.auths

	source: {
		path: "."
		include: [
			"cmd/",
			"go.mod",
		]
	}

	main: "./cmd/hello"

//	cgo:     true
//	isolate: false

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

	ship: name: "ghcr.io/innoai-tech/runtime/hello"

	devkit: load: host: client.network."unix:///var/run/docker.sock".connect
	ship: load: host:   client.network."unix:///var/run/docker.sock".connect
}

client: network: "unix:///var/run/docker.sock": connect: dagger.#Socket

actions: test: core.#Nop & {
	input: yaml.Marshal({
		goversion:   actions.go.goversion
		module:      actions.go.module
		imageconfig: actions.go.build."linux/arm64".output.config
	})
}

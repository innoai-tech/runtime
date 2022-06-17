package main

import (
	"encoding/json"
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

actions: go: golang.#Build & {
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

	build: image: {
		mirror: client.env.LINUX_MIRROR
	}

	// ship: {
	//  host: "ghcr.io"
	//  auth: {
	//   username: client.env.GH_USERNAME
	//   secret:   client.env.GH_PASSWORD
	//  }
	// }
}

actions: test: core.#Nop & {
	input: """
			goversion: \(actions.go.goversion)
			module: \(actions.go.module)
			build script: \(actions.go.build.script)
			build image config: \(json.Marshal(actions.go.build."linux/arm64".output.config))
			"""
}

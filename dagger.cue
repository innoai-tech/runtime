package main

import (
	"strings"
	"dagger.io/dagger"

	"github.com/innoai-tech/runtime/cuepkg/tool"
	"github.com/innoai-tech/runtime/cuepkg/golang"
)

dagger.#Plan

client: env: {
	VERSION: string | *"dev"
	GIT_SHA: string | *""
	GIT_REF: string | *""

	GOPROXY:   string | *""
	GOPRIVATE: string | *""
	GOSUMDB:   string | *""

	GH_USERNAME: string | *""
	GH_PASSWORD: dagger.#Secret

	CONTAINER_REGISTRY_PULL_PROXY: string | *""
	LINUX_MIRROR: string | *""
}

client: platform: arch: _
client: network: "unix:///var/run/docker.sock": connect: dagger.#Socket

client: filesystem: {
	"build/output": write: contents: actions.go.archive.output
}

actions: version: tool.#ResolveVersion & {
	"ref":     "\(client.env.GIT_REF)"
	"version": "\(client.env.VERSION)"
}

actions: go: golang.#Project & {
	source: {
		path: "."
		include: [
			"cmd/",
			"pkg/",
			"go.mod",
			"go.sum",
		]
	}

	revision: client.env.GIT_SHA

	goos: ["linux", "darwin"]
	goarch: ["amd64", "arm64"]
	main: "./cmd/webappserve"
	ldflags: [
		"-s -w",
		"-X \(go.module)/pkg/version.Version=\(go.version)",
		"-X \(go.module)/pkg/version.Revision=\(go.revision)",
	]
	env: {
		GOPROXY:   client.env.GOPROXY
		GOPRIVATE: client.env.GOPRIVATE
		GOSUMDB:   client.env.GOSUMDB
	}

	build: {
		pre: [
			"go mod download",
		]

		image: {
			mirror: {
				linux: client.env.LINUX_MIRROR
				pull:  client.env.CONTAINER_REGISTRY_PULL_PROXY
			}
		}
	}

	devkit: load: host: client.network."unix:///var/run/docker.sock".connect

	ship: {
		name: "\(strings.Replace(actions.go.module, "github.com/", "ghcr.io/", -1))/\(actions.go.binary)"
		tag:  "\(actions.version.output)"

		image: {
			source: "gcr.io/distroless/static-debian11:debug"
			mirror: pull: client.env.CONTAINER_REGISTRY_PULL_PROXY
		}

		config: env: {
			APP_ROOT: "/app"
			ENV:      ""
		}

		push: {
			auth: {
				username: client.env.GH_USERNAME
				secret:   client.env.GH_PASSWORD
			}
		}

		load: host: client.network."unix:///var/run/docker.sock".connect
	}
}

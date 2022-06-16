package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"github.com/innoai-tech/runtime/cuepkg/golang"
)

dagger.#Plan & {
	client: {
		env: {
			LINUX_MIRROR: string | *""

			GIT_SHA: string | *""
		}
	}

	actions: {
		src: {
			go: core.#Source & {
				path: "."
				include: [
					"cmd",
					"go.mod",
				]
			}
		}

		build: golang.#Build & {
			source: src.go.output
			image: {
				mirror: "\(client.env.LINUX_MIRROR)"
			}
			go: {
				os: ["linux", "darwin"]
				arch: ["amd64", "arm64"]
				package: "./cmd/hello"
				ldflags: [
					"-s -w",
					"-X \(go.module)/pkg/version.Revision=\(client.env.GIT_SHA)",
				]
			}
		}
	}
}

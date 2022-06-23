package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
	"github.com/innoai-tech/runtime/cuepkg/debian"
)

dagger.#Plan

client: env: {
	LINUX_MIRROR:                  string | *""
	CONTAINER_REGISTRY_PULL_PROXY: string | *""

	GH_USERNAME: string | *""
	GH_PASSWORD: dagger.#Secret
}

client: network: {
	"unix:///var/run/docker.sock": connect: dagger.#Socket
}

actions: {
	auths: "ghcr.io": {
		username: "\(client.env.GH_USERNAME)"
		secret:   client.env.GH_PASSWORD
	}

	mirror: {
		linux: client.env.LINUX_MIRROR
		pull:  client.env.CONTAINER_REGISTRY_PULL_PROXY
	}

	build: debian.#Build & {
		packages: {
			//   "git": _
		}
		steps: [
			imagetool.#ImageDep & {
				dependences: {
					"ghcr.io/innoai-tech/ffmpeg": "5"
				}
				"auths":  auths
				"mirror": mirror
			},
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

	inimage: core.#ReadFile & {
		input: build.output.rootfs
		path:  "/etc/test"
	}

	test: core.#Nop & {
		input: """
			loaded: \(inimage.contents)
			"""
	}
}

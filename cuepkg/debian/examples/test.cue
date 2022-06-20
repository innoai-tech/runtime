package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"github.com/innoai-tech/runtime/cuepkg/crutil"
	"github.com/innoai-tech/runtime/cuepkg/debian"
)

dagger.#Plan

client: env: {
	LINUX_MIRROR: string | *""
}

client: network: {
	"unix:///var/run/docker.sock": connect: dagger.#Socket
}

img: debian.#Build & {
	mirror: {
		linux: "\(client.env.LINUX_MIRROR)"
	}
	packages: {
		"git": _
	}
	steps: [
		crutil.#Script & {
			name: "skip"
		},
		crutil.#Script & {
			name: "echo test"
			run: [
				"echo test > /etc/test",
			]
		},
	]
}

inimage: core.#ReadFile & {
	input: img.output.rootfs
	path:  "/etc/test"
}

actions: test: core.#Nop & {
	input: """
			loaded: \(inimage.contents)
			"""
}

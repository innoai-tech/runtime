package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker/cli"

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
	mirror: "\(client.env.LINUX_MIRROR)"
	packages: "ca-certificates": ""
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

actions: load: cli.#Load & {
	image: img.output
	host:  client.network."unix:///var/run/docker.sock".connect
	tag:   "debian:test"
}

actions: test: core.#Nop & {
	input: """
			loaded: \(actions.load.imageID)
			"""
}

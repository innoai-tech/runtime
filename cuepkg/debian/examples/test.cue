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

img: debian.#Build & {
	mirror: "\(client.env.LINUX_MIRROR)"
	packages: git: ""
	steps: [
		crutil.#Run & {
			name: "skip"
		},
		crutil.#Run & {
			name: "echo test"
			scripts: [
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
			testfile: \(inimage.contents)
			"""
}

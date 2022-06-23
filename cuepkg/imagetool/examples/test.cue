package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

dagger.#Plan

actions: build: imagetool.#Build & {
	platform: "linux/arm64"
	from:     ""
	steps: [
		imagetool.#ImageDep & {
			//   platforms: ["linux/amd64", "linux/arm64"]
			dependences: {
				"ghcr.io/innoai-tech/ffmpeg": "5"
			}
		},
	]
}

actions: test: core.#Nop & {
	input: "\(actions.build.output.platform)"
}

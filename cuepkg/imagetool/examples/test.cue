package main

import (
	"dagger.io/dagger"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

dagger.#Plan

actions: test: imagetool.#Build & {
	from: ""

	steps: [
		imagetool.#ImageDep & {
			platforms: ["linux/amd64", "linux/arm64"]
			dependences: {
				"ghcr.io/innoai-tech/ffmpeg": "5"
			}
		},
	]
}

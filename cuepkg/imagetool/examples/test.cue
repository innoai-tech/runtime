package main

import (
	"dagger.io/dagger"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

dagger.#Plan

actions: test: imagetool.#Build & {
	//    platform: "linux/arm64"
	from: ""
	steps: [
		imagetool.#ImageDep & {
			//   platforms: ["linux/amd64", "linux/arm64"]
			dependencies: {
				"ghcr.io/innoai-tech/ffmpeg": "5"
			}
		},
	]
}

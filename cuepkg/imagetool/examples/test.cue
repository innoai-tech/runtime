package main

import (
	"dagger.io/dagger"

	"github.com/innoai-tech/runtime/cuepkg/imagetool"
)

dagger.#Plan

actions: test: imagetool.#Build & {
	from: "docker.io/library/debian:bullseye-slim"
}

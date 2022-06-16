package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"

	"github.com/innoai-tech/runtime/cuepkg/debian"
)

dagger.#Plan & {
	client: {
		env: {
			LINUX_MIRROR: string | *""
		}
	}

	actions: {
		testfile: core.#WriteFile & {
			input:    dagger.#Scratch
			path:     "test"
			contents: "test"
		}

		img: {
			packages: git: ""

			debian.#Build & {
				mirror:     "\(client.env.LINUX_MIRROR)"
				"packages": packages
				steps: [
					docker.#Copy & {
						contents: testfile.output
						source:   testfile.path
						dest:     "/etc/test"
					},
				]
			}
		}

		inimage: core.#ReadFile & {
			input: img.output.rootfs
			path:  "/etc/test"
		}

		print: core.#Nop & {
			input: """
			testfile: \(inimage.contents)
			"""
		}
	}
}

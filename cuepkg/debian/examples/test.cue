package main

import (
	"wagon.octohelm.tech/core"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
	"github.com/innoai-tech/runtime/cuepkg/debian"
)

client: env: core.#ClientEnv & {
	GH_USERNAME: string | *""
	GH_PASSWORD: core.#Secret
}

actions: {
	auths: "ghcr.io": {
		username: "\(client.env.GH_USERNAME)"
		secret:   client.env.GH_PASSWORD
	}

	build: debian.#Build & {
		"auths": auths
		packages: {
			//   "git": _
		}
		steps: [
			//   imagetool.#ImageDep & {
			//    dependencies: {
			//     "ghcr.io/innoai-tech/ffmpeg": "5"
			//    }
			//    "auths":  auths
			//    "mirror": mirror
			//   },
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

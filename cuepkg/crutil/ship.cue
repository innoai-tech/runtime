package crutil

import (
	"strings"

	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

#Ship: {
	name:   string
	tag:    string
	config: core.#ImageConfig
	image: {
		source: string | *""
		auth?:  #Auth
		steps: [...docker.#Step]
		postSteps: [...docker.#Step]
	}
	platforms: [...string]

	_images: {
		for p in platforms {
			"\(p)": #Build & {
				if image.auth != _|_ {
					auth: image.auth
				}
				platform: "\(p)"
				source:   image.source
				steps: [
					for step in image.steps {
						step
					},
					for step in image.postSteps {
						step
					},
					docker.#Set & {
						"config": config & {
							env: {
								PATH:   "/busybox:${PATH}"
								GOOS:   "\(strings.Split(p, "/")[0])"
								GOARCH: "\(strings.Split(p, "/")[1])"
							}
						}
					},
				]
			}
		}
	}

	push: docker.#Push & {
		"dest": "\(name):\(tag)"
		"images": {
			for p in platforms {
				"\(p)": _images["\(p)"].output
			}
		}
	}

	load?: {
		host: _

		for platform in platforms {
			"\(strings.Split(platform, "/")[1])": cli.#Load & {
				"host":  host
				"image": _images["\(platform)"].output
				"tag":   "\(name):\(tag)"
			}
		}
	}
}

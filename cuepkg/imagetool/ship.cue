package imagetool

import (
	"strings"
	"text/template"

	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

#Platform: {
	os:   string
	arch: string
}

#Ship: {
	name: string
	tag:  string

	from: string | *""
	platforms: [...string]
	config: core.#ImageConfig
	steps: [...docker.#Step]
	postSteps: [...docker.#Step]

	auths: [Host=string]: #Auth
	mirror: #Mirror

	_images: {
		for platform in platforms {
			"\(platform)": #Build & {
				"auths":    auths
				"from":     from
				"mirror":   mirror
				"platform": "\(platform)"
				"steps": [
					for step in steps {
						step
					},
					for step in postSteps {
						step
					},
					docker.#Set & {
						"config": {
							for k, v in config if k != "env" {
								"\(k)": v
							}
							for k, v in config if k == "env" {
								let ctx = {
									TARGETPLATFORM: "\(platform)"
									TARGETOS:       "\(strings.Split(platform, "/")[0])"
									TARGETARCH:     "\(strings.Split(platform, "/")[1])"
								}
								for ek, ev in v {
									"env": "\(ek)": template.Execute(ev, ctx)
								}
							}
						}
					},
				]
			}
		}
	}

	_dest: core.#Nop & {
		input: "\(name):\(tag)"
	}

	// Push all images as multi-arch images
	pushx: #Push & {
		"dest":  _dest.output
		"auths": auths
		"images": {
			for platform in platforms {
				"\(platform)": _images["\(platform)"].output
			}
		}
	}

	push: _push

	// Merge pushed arch suffix images into mutli-arch image
	"push/x": _push.x

	for platform in platforms {
		let arch = strings.Split(platform, "/")[1]

		// Push <arch> suffix image
		"push/\(platform)": _push["\(arch)"]
	}

	_push: {
		for platform in platforms {
			let arch = strings.Split(platform, "/")[1]

			// Push <arch> suffix image
			"\(arch)": #Push & {
				"auths": auths
				"dest":  "\(_dest.output)-\(arch)"
				"image": _images["\(platform)"].output
			}
		}

		// Merge pushed arch suffix images into mutli-arch image
		x: {
			#Push & {
				"dest":  _dest.output
				"auths": auths

				for platform in platforms {
					_pull: "\(platform)": #Pull & {
						"auths":  auths
						"mirror": mirror
						"source": "\(_dest.output)-\(strings.Split(platform, "/")[1])"
					}

					images: "\(platform)": _pull["\(platform)"].output
				}
			}
		}
	}

	load?: {
		host: _
	}

	if load != _|_ {
		for platform in platforms {
			let arch = strings.Split(platform, "/")[1]

			// Load built image to local docker
			"load/\(platform)": {
				_image: #Pull & {
					"source": "docker.io/library/docker:20.10.13-alpine3.15"
					"auths":  auths
					"mirror": mirror
				}

				cli.#Load & {
					"host":  load.host
					"input": _image.output
					"image": _images["\(platform)"].output
					"tag":   "\(name):\(tag)-\(arch)"
				}
			}
		}
	}
}

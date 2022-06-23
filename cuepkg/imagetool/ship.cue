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

	// Push all images as multi-arch images
	pushx: #Push & {
		"dest":  "\(name):\(tag)"
		"auths": auths
		"images": {
			for platform in platforms {
				"\(platform)": _images["\(platform)"].output
			}
		}
	}

	push: {
		// Push arch suffix image
		for platform in platforms {
			let arch = strings.Split(platform, "/")[1]

			"\(arch)": #Push & {
				"auths": auths
				"dest":  "\(name):\(tag)-\(arch)"
				"image": _images["\(platform)"].output
			}
		}

		x: {
			_published: {
				for platform in platforms {
					let arch = strings.Split(platform, "/")[1]

					"\(platform)": #Pull & {
						"auths":  auths
						"source": "\(name):\(tag)-\(arch)"
					}
				}
			}

			#Push & {
				"dest":  "\(name):\(tag)"
				"auths": auths
				"images": {
					for platform in platforms {
						"\(platform)": _published["\(platform)"].output
					}
				}
			}
		}
	}

	load?: {
		_image: #Pull & {
			"source": "docker.io/library/docker:20.10.13-alpine3.15"
			"auths":  auths
			"mirror": mirror
		}

		host: _

		for platform in platforms {
			let arch = strings.Split(platform, "/")[1]

			"\(arch)": cli.#Load & {
				"host":  host
				"input": _image.output
				"image": _images["\(platform)"].output
				"tag":   "\(name):\(tag)-\(arch)"
			}
		}
	}
}

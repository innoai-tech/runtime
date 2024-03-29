package imagetool

import (
	"strings"
	"text/template"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"
)

#Platform: {
	os:   string
	arch: string
}

#Ship: #ShipConfig & {
	name: _
	tag:  _

	from:      _
	platforms: _
	config:    _
	steps:     _
	postSteps: _

	variant: [Variant=string]: #ShipConfig & {
		"name": _ | *"\(name)"
		"tag":  _ | *"\(Variant)-\(tag)"

		"from":      _ | *from
		"platforms": _ | *platforms
		"config":    _ | *config
		"steps":     _ | *steps
		"postSteps": _ | *postSteps
	}
}

#ShipConfig: {
	name: string
	tag:  string

	from: string | *""
	platforms: [...string]
	config: core.#ImageConfig
	steps: [...docker.#Step]
	postSteps: [...docker.#Step]

	auths: [Host=string]: #Auth

	image: {
		for platform in platforms {
			"\(platform)": #Build & {
				"auths":    auths
				"from":     from
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

	_dest: "\(name):\(tag)"

	// Push all images as multi-arch images
	pushx: #Push & {
		"dest":  _dest
		"auths": auths
		"images": {
			for platform in platforms {
				"\(platform)": image["\(platform)"].output
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
				"dest":  "\(_dest)-\(arch)"
				"image": image["\(platform)"].output
			}
		}

		// Merge pushed arch suffix images into mutli-arch image
		x: {
			#Push & {
				"dest":  _dest
				"auths": auths

				for platform in platforms {
					_pull: "\(platform)": #Pull & {
						"auths":  auths
						"source": "\(_dest)-\(strings.Split(platform, "/")[1])"
					}

					images: "\(platform)": _pull["\(platform)"].output
				}
			}
		}
	}

	...
}

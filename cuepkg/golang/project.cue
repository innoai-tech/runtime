package golang

import (
	"strings"
	"path"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"

	"github.com/innoai-tech/runtime/cuepkg/debian"
	"github.com/innoai-tech/runtime/cuepkg/imagetool"
	"github.com/innoai-tech/runtime/cuepkg/tool"
)

#Project: imagetool.#Project & {
	source: core.#Source
	module: string

	goversion: string
	goos: [...string]
	goarch: [...string]
	cgo:     bool | *false
	isolate: bool | *cgo

	ldflags: [...string] | *["-x -w"]
	workdir: string | *"/go/src"

	main:   string | *"."
	binary: string | *path.Base(main)
	env: [Name=string]:    string | dagger.#Screct
	mounts: [Name=string]: core.#Mount

	auths:  _
	mirror: _

	// Go build binary for special platform 
	build: {
		pre: [...string]
		post: [...string]

		script: "go build -ldflags=\"\(strings.Join(ldflags, " "))\" -o /output/\(binary) \(main)"

		// dev image 
		image: debian.#ImageBase
		image: "auths":  auths
		image: "mirror": mirror

		for os in goos for arch in goarch {
			"\(os)/\(arch)": {
				input:  docker.#Image
				output: docker.#Image
			}
		}
	}

	devkit?: {
		load?: {
			host: _
		}

		if load != _|_ {
			for arch in goarch {
				// Load go build env image to local docker
				"load/linux/\(arch)": {
					_image: imagetool.#Pull & {
						"source": "docker.io/library/docker:20.10.13-alpine3.15"
						"auths":  auths
						"mirror": mirror
					}
					cli.#Load & {
						"host":  load.host
						"input": _image.output
						"image": build["linux/\(arch)"].input
						"tag":   "\(module):devkit-\(arch)"
					}
				}
			}
		}
	}

	// Archive all built binaries into local (need to define client: `filesytem: "x": write: contents: actions.go.archive.output`)
	archive: tool.#Export & {
		archive: true

		for os in goos for arch in goarch {
			_copy: "\(os)/\(arch)": core.#Copy & {
				input:    dagger.#Scratch
				contents: build["\(os)/\(arch)"].output.rootfs
				source:   "/output"
				dest:     "/"
			}
			directories: "\(binary)_\(os)_\(arch)": _copy["\(os)/\(arch)"].output
		}
	}

	version:  _
	revision: _

	ship: {
		tag: _

		if tag == _|_ {
			tag: "\(version)"
		}

		config: {
			label: {
				"org.opencontainers.image.source":   "https://\(module)"
				"org.opencontainers.image.revision": "\(revision)"
			}
			workdir:    "/"
			cmd:        _ | *[]
			entrypoint: _ | *["/\(binary)"]
		}

		platforms: [
			for arch in goarch {
				"linux/\(arch)"
			},
		]

		postSteps: [
			docker.#Copy & {
				input:      _
				"contents": build["\(input.platform)"].output.rootfs
				"source":   "/output"
				"dest":     "/"
			},
		]
	}

	_gomod: #Info & {"source": source.output}

	goversion: _ | *"\(_gomod.go)"
	module:    _ | *"\(_gomod.module)"

	env: {
		if cgo {
			CGO_ENABLED: "1"
		}
		if !cgo {
			CGO_ENABLED: "0"
		}
	}

	build: {
		_caches: {
			go_mod_cache:   "/go/pkg/mod"
			go_build_cache: "/root/.cache/go-build"
		}

		_cachesMounts: {
			for _n, _p in _caches {
				"\(_p)": core.#Mount & {
					dest:     _p
					contents: core.#CacheDir & {
						id: "\(_n)"
					}
				}
			}
		}

		if !isolate {
			_image: #Image & {
				build.image

				"goversion": goversion

				if cgo {
					packages: "gcc-x86-64-linux-gnu": {platform: "linux/arm64"}
					packages: "g++-x86-64-linux-gnu": {platform: "linux/arm64"}
					packages: "gcc-aarch64-linux-gnu": {platform: "linux/amd64"}
					packages: "g++-aarch64-linux-gnu": {platform: "linux/amd64"}
				}
			}

			for os in goos for arch in goarch {
				"\(os)/\(arch)": {
					input: _image.output
				}
			}
		}

		if isolate {
			for os in goos for arch in goarch {
				"\(os)/\(arch)": {
					_image: #Image & {
						build.image
						"platform":  "\(os)/\(arch)"
						"goversion": goversion
					}

					input: _image.output
				}
			}
		}

		for os in goos for arch in goarch {
			"\(os)/\(arch)": {
				input: _

				docker.#Build & {
					steps: [
						{
							output: input
						},
						docker.#Copy & {
							contents: source.output
							dest:     "\(workdir)"
						},
						for name, scripts in {
							"prebuild": build.pre
							"build": ["\(build.script)"]
							"postbuild": build.post
						} {
							imagetool.#Script & {
								"name":    "\(name)"
								"workdir": "\(workdir)"
								"mounts": {
									mounts
									_cachesMounts
								}
								"env": {
									env
									GOOS:   os
									GOARCH: arch

									if cgo && !isolate {
										CXX: "\(imagetool.#GnuArch["\(arch)"])-linux-gnu-g++"
										CC:  "\(imagetool.#GnuArch["\(arch)"])-linux-gnu-gcc"
										AR:  "\(imagetool.#GnuArch["\(arch)"])-linux-gnu-gcc-ar"
									}
								}
								"run": scripts
							}
						},
					]
				}
			}
		}
	}
}

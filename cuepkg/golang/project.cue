package golang

import (
	"strings"
	"path"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

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
	env: [Name=string]:    string | core.#Screct
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

	// Archive all built binaries into local (need to define client: `filesytem: "x": write: contents: actions.go.archive.output`)
	archive: {
		_binary: {
			for os in goos for arch in goarch {
				"\(binary)_\(os)_\(arch)": {
					_image: build["\(os)/\(arch)"].output

					_copy: core.#Copy & {
						contents: _image.rootfs
						source:   "/output"
						dest:     "/"
					}

					output: _copy.output
				}
			}
		}

		tool.#Export & {
			archive: true

			for name, fs in _binary {
				directories: "\(name)": fs.output
			}
		}
	}

	version:  _
	revision: _

	ship: {
		tag: _ | *"\(version)"

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

		_binary: {
			for p in platforms {
				"\(p)": build["\(p)"].output
			}
		}

		postSteps: [
			docker.#Copy & {
				input:      _
				"contents": _binary["\(input.platform)"].rootfs
				"source":   "/output"
				"dest":     "/"
			},
		]
	}

	_gomod: #Info & {"source": source.output}

	goversion: _ | *"\(_gomod.go)"
	module:    _ | *"\(_gomod.module)"

	_goenv: core.#ClientEnv & {
		GOPROXY:   _ | *""
		GOPRIVATE: _ | *""
		GOSUMDB:   _ | *""
	}

	env: {
		GOPROXY:   _goenv.GOPROXY
		GOPRIVATE: _goenv.GOPRIVATE
		GOSUMDB:   _goenv.GOSUMDB
	}

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

package golang

import (
	"path"
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Go: {
	version: string
	module:  string
	package: string | *"."
	name:    string | *path.Base(package)
	os: [...string]
	arch: [...string]
	cgo:     bool | *false
	ldflags: *["-x -w"] | [...string]
}

#Build: {
	source: dagger.#FS

	_gomod: #Info & {
		"source": source
	}

	go: #Go
	go: {
		version: _gomod.go
		module:  _gomod.module
	}

	run: {
		prebuild: {
			scripts: [...string]
		}
		workdir: "/go/src"
		mounts: [Name=string]: core.#Mount
		env: [Name=string]:    string | dagger.#Secret
		env: {
			if go.cgo {
				CGO_ENABLED: "1"
			}
			if !go.cgo {
				CGO_ENABLED: "0"
			}
		}
	}

	image: {
		"go":   go.version
		mirror: string | *""
		packages: [pkgName=string]: string | *""
		steps: [...docker.#Step]
	}

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

	for _os in go.os for _arch in go.arch {
		"\(_os)/\(_arch)": {
			_run: {
				_scripts: [
					for script in run.prebuild.scripts {
						script
					},
					"go build -ldflags=\"\(strings.Join(go.ldflags, " "))\" -o /output/\(go.name) \(go.package)",
				]

				input: docker.#Image

				docker.#Build & {
					steps: [
						{
							output: input
						},
						docker.#Copy & {
							contents: source
							dest:     run.workdir
						},
						for i, script in _scripts {
							docker.#Run & {
								workdir: run.workdir
								mounts: {
									run.mounts
									_cachesMounts
								}
								env: {
									run.env
									GOOS:   _os
									GOARCH: _arch
								}
								command: name: "sh"
								command: flags: "-c": script
							}
						},
					]
				}
			}

			_copy: core.#Copy & {
				input:    dagger.#Scratch
				contents: _run.output.rootfs
				source:   "/output"
				dest:     "/"
			}

			output: _copy.output
		}
	}

	// switch image for cgo or not
	if go.cgo {
		// cgo should create different build env for each arch
		for _os in go.os for _arch in go.arch {
			"\(_os)/\(_arch)": {
				_image: #Image & {
					image
					"platform": "\(_os)/\(_arch)"
				}

				_run: input: _image.output
			}
		}
	}

	if !go.cgo {
		_image: #Image & {
			image
		}

		for _os in go.os for _arch in go.arch {
			"\(_os)/\(_arch)": {
				_run: input: _image.output
			}
		}
	}
}

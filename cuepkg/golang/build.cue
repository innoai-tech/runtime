package golang

import (
	"path"
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Build: {
	source: dagger.#FS

	_gomod: #Info & {
		"source": source
	}

	go: {
		version: _gomod.go
		module:  _gomod.module
		package: string
		name:    string | *path.Base(go.package)
		os: [...string]
		arch: [...string]
		cgo:     bool | *false
		ldflags: *["-x -w"] | [...string]
	}

	run: {
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
		mounts: {
			codesource: core.#Mount & {
				dest:     workdir
				contents: source
			}
		}
	}

	image: {
		"go":   "\(go.version)"
		mirror: string | *""
		packages: [pkgName=string]: string | *""
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
			_build: docker.#Run & {
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
				command: name: "go"
				command: args: [
					"build",
					"-ldflags", strings.Join(go.ldflags, " "),
					"-o", "/output/\(go.name)",
					"\(go.package)",
				]
				export: directories: "/output": _
			}

			output: _build.export.directories."/output"
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

				_build: input: _image.output
			}
		}
	}

	if !go.cgo {
		_image: #Image & {
			image
		}

		for _os in go.os for _arch in go.arch {
			"\(_os)/\(_arch)": {
				_build: input: _image.output
			}
		}
	}
}

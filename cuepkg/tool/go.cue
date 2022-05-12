package tool

import (
	"regexp"
	"path"
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#GoModInfo: {
	source: dagger.#FS

	_gomod: core.#ReadFile & {
		input: source
		path:  "go.mod"
	}

	module: regexp.FindSubmatch(#"module (.+)\n"#, _gomod.contents)[1]
	go:     regexp.FindSubmatch(#"go (.+)\n"#, _gomod.contents)[1]
}

#GoBuild: {
	source:  dagger.#FS
	package: string
	name:    path.Base(package)

	cgoEnabled: bool | *false
	ldflags:    *["-x -w"] | [...string]

	targetPlatform: {
		os: [...string]
		arch: [...string]
	}

	buildPlatform?: {
		os:   string
		arch: string
	}

	gomod: #GoModInfo & {
		"source": source
	}

	image: {
		goVersion:      "\(gomod.go)"
		downloadMirror: string | *"dl-cdn.alpinelinux.org"
		packages: [pkgName=string]: string | *""
	}

	run: {
		workdir: "/go/src"
		mounts: [Name=string]: core.#Mount
		env: [Name=string]:    string | dagger.#Secret

		env: {
			if cgoEnabled {
				CGO_ENABLED: "1"
			}
			if !cgoEnabled {
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

	_caches: #BuildCacheMounts & {_, #caches: {
		go_mod_cache:   "/go/pkg/mod"
		go_build_cache: "/root/.cache/go-build"
	}}

	_image: image

	if cgoEnabled {
		for _os in targetPlatform.os for _arch in targetPlatform.arch {
			"\(_os)/\(_arch)": {
				goimage: #GoImage & {
					_image
					platform: "\(_os)/\(_arch)"
				}
				_build: input: goimage.output
			}
		}
	}

	if !cgoEnabled {
		goimage: #GoImage & {
			_image
		}

		for _os in targetPlatform.os for _arch in targetPlatform.arch {
			"\(_os)/\(_arch)": {
				_build: input: goimage.output
			}
		}
	}

	for _os in targetPlatform.os for _arch in targetPlatform.arch {
		"\(_os)/\(_arch)": {
			_build: docker.#Run & {
				workdir: run.workdir
				mounts: {
					run.mounts
					_caches
				}
				env: {
					run.env
					GOOS:   _os
					GOARCH: _arch
				}
				command: name: "go"
				command: args: [
					"build",
					"-ldflags", strings.Join(ldflags, " "),
					"-o", "/output/\(name)",
					"\(package)",
				]
				export: directories: "/output": _
			}

			output: _build.export.directories."/output"
		}
	}
}

#GoImage: {
	goVersion: string | *"1.18"

	packages: {
		"git":        _
		"alpine-sdk": _
	}

	#AlpineBuild & {
		source: "golang:\(goVersion)-alpine"
	}
}

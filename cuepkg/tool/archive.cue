package tool

import (
	"path"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Tar: {
	contents: dagger.#FS
	source:   string | *"/"
	dest:     string

	_busybox: docker.#Pull & {
		source: "busybox"
	}

	_run: docker.#Run & {
		input: _busybox.output
		mounts: {
			"dir": core.#Mount & {
				"contents": contents
				"dest":     "\(dest)"
				"source":   "/"
			}
		}
		workdir: "\(dest)"
		command: {
			name: "sh"
			flags: "-c": """
			mkdir -p /output
			tar -czf /output/\(path.Base(dest)).tar.gz -C \(dest) .
			"""
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

#Export: {
	directories: [Path=string]: core.#FS
	archive: bool | *false

	_directories: {
		for p, fs in directories {
			"\(p)": core.#Copy & {
				input:    dagger.#Scratch
				contents: fs
				source:   "/"
				dest:     "/\(p)"
			}
		}
	}

	_archives: {
		for _p, _fs in directories {
			"\(_p)": #Tar & {
				contents: _fs
				dest:     "/\(_p)"
				source:   "/"
			}
		}
	}

	_merge: core.#Merge & {
		inputs: [
			for d in _directories {
				d.output
			},
			for d in _archives {
				d.output
			},
		]
	}

	output: _merge.output
}

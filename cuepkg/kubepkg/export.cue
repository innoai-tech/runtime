package kubepkg

import (
	"encoding/json"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
	"github.com/innoai-tech/runtime/cuepkg/kube"
)

#Export: {
	filename: string
	kubepkg:  kube.#KubePkg
	arch:     string
	env:      docker.#Run.env

	_files: [Path=string]: core.#WriteFile & {
		input: dagger.#Scratch
	}

	_files: {
		"/src/kubepkg.json": {
			path:     "kubepkg.json"
			contents: json.Marshal(kubepkg.kube)
		}
	}

	_caches: {
		kubepkg_cache: core.#Mount & {
			dest:     "/etc/kubepkg"
			contents: core.#CacheDir & {
				id:          "kubepkg_cache"
				concurrency: "locked"
			}
		}
	}

	run: #Run & {
		mounts: _caches & {
			for p, f in _files {
				"\(p)": core.#Mount & {
					dest:     p
					source:   f.path
					contents: f.output
				}
			}
		}
		"env": env
		command: {
			name: "export"
			args: [
				"--storage-root=/etc/kubepkg",
				"--platform=linux/\(arch)",
				"--extract-manifests-yaml=/build/manifests/\(kubepkg.kube.metadata.name).yaml",
				"--output=/build/images/\(filename)",
				"/src/kubepkg.json",
			]
		}
	}

	_output: core.#Subdir & {
		input: run.output.rootfs
		path:  run.workdir
	}

	output: _output.output
}

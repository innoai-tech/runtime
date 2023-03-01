package kubepkg

import (
	"encoding/json"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"
)

#Export: {
	filename: string
	kubepkg:  #KubePkg
	arch:     string
	env:      docker.#Run.env

	_files: [Path=string]: core.#WriteFile & {
	}

	_files: "/src/kubepkg.json": {
		path:     "kubepkg.json"
		contents: json.Marshal(kubepkg)
	}

	_caches: kubepkg_cache: core.#Mount & {
		dest:     "/etc/kubepkg"
		contents: core.#CacheDir & {
			id:          "kubepkg_cache"
			concurrency: "locked"
		}
	}

	_image: #Image & {}

	run: docker.#Run & {
		input:  _image.output
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
				"--extract-manifests-yaml=/build/manifests/\(kubepkg.metadata.name).yaml",
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

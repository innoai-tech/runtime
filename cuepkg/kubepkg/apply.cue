package kubepkg

import (
	"encoding/json"

	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/docker"
)

#Apply: {
	kubepkg:    #KubePkg
	kubeconfig: dagger.#Secret

	flags: [K=string]: string

	_files: "/src/kubepkg.json": core.#WriteFile & {
		input:    dagger.#Scratch
		path:     "kubepkg.json"
		contents: json.Marshal(kubepkg)
	}

	_image: #Image & {}

	_apply: docker.#Run & {
		input: _image.output

		mounts: {
			"kubeconfig": core.#Mount & {
				dest:     "/run/secrets/kubeconfig"
				contents: kubeconfig
			}

			for p, f in _files {
				"\(p)": core.#Mount & {
					dest:     p
					source:   f.path
					contents: f.output
				}
			}
		}
		command: {
			name: "apply"
			args: [
				"--kubeconfig=/run/secrets/kubeconfig",
				for _k, _v in flags {
					"\(_k)=\(_v)"
				},
				"/src/kubepkg.json",
			]
		}
	}

	output: _apply.output
}

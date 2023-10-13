package helm

import (
	"list"
	"encoding/yaml"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

	"github.com/octohelm/kubepkg/cuepkg/kubepkg"
)

#Template: {
	namespace: string

	chart: {
		name:    string
		version: string | *"1.0.0"
		dependencies: [Name=string]: {
			version:    string
			repository: string
			name?:      string
		}
	}

	values: _

	exclude: [...string] | *[]

	_files: [Path=string]: core.#WriteFile & {
		path: Path
	}

	_files: {
		"values.yaml": contents: yaml.Marshal(values)
		"Chart.yaml": contents:  yaml.Marshal({
			apiVersion: "v2"
			name:       chart.name
			version:    chart.version
			dependencies: [
				for n, d in chart.dependencies {
					{
						name: [
							if (d.name != _|_) {
								d.name
							},
							n,
						][0]
						version:    d.version
						repository: d.repository
						alias:      n
					}
				},
			]
		})
	}

	_image: #Image

	_run: docker.#Run & {
		input:  _image.output
		always: true
		mounts: {
			for p, f in _files {
				"\(p)": core.#Mount & {
					dest:     "/src/\(f.path)"
					source:   f.path
					contents: f.output
				}
			}
		}
		workdir: "/output"
		entrypoint: ["/bin/sh"]
		command: {
			name: "-c"
			args: [
				"""
					ls /src;
					helm dependency build /src;
					helm template --namespace=\(namespace) \(chart.name) /src > /output/manifests.yaml;
					""",
			]
		}
	}

	_read: core.#ReadFile & {
		input: _run.output.rootfs
		path:  "/output/manifests.yaml"
	}

	preConvert: [...#Step]

	_preConvert: {
		"0": {
			output: _read.contents
		}

		for i, s in preConvert {
			"\(i+1)": s & {
				input: _preConvert["\(i)"].output
			}
		}
	}

	_manifests: core.#CloneWithoutNull & {
		input: yaml.UnmarshalStream(_preConvert["\(len(_preConvert)-1)"].output)
	}

	output: kubepkg.#KubePkg & {
		metadata: "namespace": namespace

		metadata: name: chart.name
		spec: version:  chart.version

		for v in _manifests.output {
			if v.kind != _|_ {
				let k = "\(v.metadata.name).\(v.kind)"

				if !list.Contains(exclude, k) {
					spec: manifests: "\(k)": v
				}
			}
		}
	}
}

#Step: {
	input?: string
	output: string
}

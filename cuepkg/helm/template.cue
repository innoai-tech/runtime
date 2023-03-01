package helm

import (
	"strings"
	"encoding/yaml"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

	"github.com/innoai-tech/runtime/cuepkg/kubepkg"
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

	_files: [Path=string]: core.#WriteFile & {
		path:  Path
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
					ls /src
					helm dependency build /src
					helm template \(chart.name) /src > /output/manifests.yaml
					""",
			]
		}
	}

	_read: core.#ReadFile & {
		input: _run.output.rootfs
		path:  "/output/manifests.yaml"
	}

	_parts: strings.Split(strings.TrimPrefix(_read.contents, "---"), "\n---")

	output: kubepkg.#KubePkg & {
		metadata: "namespace": namespace

		metadata: name: chart.name
		spec: version:  chart.version

		for part in _parts {
			let v = yaml.Unmarshal(part)
			if v != _|_ {
				if v.kind != _|_ {
					spec: manifests: "\(v.kind)": "\(v.metadata.name)": v

					if (v.kind == "Deployment" || v.kind == "DaemonSet" || v.kind == "StatefulSet") {
						for c in v.spec.template.spec.containers {
							spec: images: "\(c.image)": ""
						}
					}
				}
			}
		}
	}
}

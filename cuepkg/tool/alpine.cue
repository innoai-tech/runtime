package tool

import (
	"universe.dagger.io/docker"
)

#AlpineBuild: {
	source:         string | *"index.docker.io/alpine:3.15.0"
	downloadMirror: string | *"dl-cdn.alpinelinux.org"
	packages: [pkgName=string]: string | *""
	platform?: string

	_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				"source": source
				if platform != _|_ {
					"platform": platform
				}
			},
			docker.#Run & {
				command: {
					name: "sh"
					flags: "-c": """
					sed -i 's/dl-cdn.alpinelinux.org/\(downloadMirror)/g' /etc/apk/repositories
					"""
				}
			},
			for _pkgName, _version in packages {
				docker.#Run & {
					command: {
						name: "apk"
						args: ["add", "\(_pkgName)\(_version)"]
						flags: {
							"-U":         true
							"--no-cache": true
						}
					}
				}
			},
		]
	}

	output: _build.output
}

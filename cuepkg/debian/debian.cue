package debian

import (
	"strings"

	"universe.dagger.io/docker"
)

#Version: "bullseye"

#Build: {
	source:    string | *"index.docker.io/debian:\(#Version)-slim"
	platform?: string
	packages: [pkgName=string]: string | *""

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
					flags: "-c": strings.Join([
							"apt-get update -y",
							for _pkgName, _version in packages {"apt-get install -y -f \(_pkgName)\(_version)"},
							"rm -rf /var/lib/apt/lists/*",
					], "\n")
				}
			},
		]
	}

	output: _build.output
}

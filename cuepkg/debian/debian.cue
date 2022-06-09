package debian

import (
	"strings"

	"universe.dagger.io/docker"
)

#Version: "bullseye"

#Mirror: {
	ustc:        "http://mirrors.ustc.edu.cn"
	huaweicloud: "http://repo.huaweicloud.com"
}

#Build: {
	source:    string | *"index.docker.io/debian:\(#Version)-slim"
	platform?: string
	mirror?: string
	packages: [pkgName=string]: string | *""

	_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				"source": source
				if platform != _|_ {
					"platform": platform
				}
			},
			if mirror != _|_ {
				docker.#Run & {
					command: {
						name: "sh"
						flags: "-c": """
						sed -i "s@http://deb.debian.org@\(mirror)@g" /etc/apt/sources.list
						sed -i "s@http://security.debian.org@\(mirror)@g" /etc/apt/sources.list
						"""
					}
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

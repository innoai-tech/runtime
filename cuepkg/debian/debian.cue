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
	steps: [...docker.#Step]

	packages: [pkgName=string]: string | *""
	mirror: string | *""

	_build: docker.#Build & {
		"steps": [
			docker.#Pull & {
				"source": source
				if platform != _|_ {
					"platform": platform
				}
			},
			if len(packages) > 0 {
				docker.#Run & {
					env: {
						LINUX_MIRROR: mirror
					}
					command: {
						name: "sh"
						flags: "-c": strings.Join([
								"""
								if [ ${LINUX_MIRROR} != "" ]; then
									sed -i "s@http://deb.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
									sed -i "s@http://security.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
								fi
								""",
								"apt-get update -y",
								for _pkgName, _version in packages {"apt-get install -y -f \(_pkgName)\(_version)"},
								"rm -rf /var/lib/apt/lists/*",
						], "\n")
					}
				}
			},
			for step in steps {
				step
			},
		]
	}

	output: _build.output
}

#InstallPackage: {
	input: docker.#Image | *docker.#Scratch
	packages: [pkgName=string]: string | *""
	mirror?: string

	_build: docker.#Build & {
		steps: [
			{
				output: input
			},
			if len(packages) > 0 {
				docker.#Run & {
					env: {
						LINUX_MIRROR: mirror
					}
					command: {
						name: "sh"
						flags: "-c": strings.Join([
								"""
								if [ ${LINUX_MIRROR} != "" ]; then
									sed -i "s@http://deb.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
									sed -i "s@http://security.debian.org@${LINUX_MIRROR}@g" /etc/apt/sources.list
								fi
								""",
								"apt-get update -y",
								for _pkgName, _version in packages {"apt-get install -y -f \(_pkgName)\(_version)"},
								"rm -rf /var/lib/apt/lists/*",
						], "\n")
					}
				}
			},
		]
	}

	output: _build.output
}

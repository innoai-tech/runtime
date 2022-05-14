package tool

import (
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#DebianVersion: "bullseye"

#DebianBuild: {
	platform?: string
	source:    string | *"index.docker.io/debian:\(#DebianVersion)-slim"
	packages: [pkgName=string]: string | *""

	_sourcesList: core.#WriteFile & {
		input:    dagger.#Scratch
		path:     "/sources.list"
		contents: """
		deb https://mirrors.aliyun.com/debian/ \(#DebianVersion) main non-free contrib
		deb-src https://mirrors.aliyun.com/debian/ \(#DebianVersion) main non-free contrib
		deb https://mirrors.aliyun.com/debian-security/ \(#DebianVersion)-security main
		deb-src https://mirrors.aliyun.com/debian-security/ \(#DebianVersion)-security main
		deb https://mirrors.aliyun.com/debian/ \(#DebianVersion)-updates main non-free contrib
		deb-src https://mirrors.aliyun.com/debian/ \(#DebianVersion)-updates main non-free contrib
		deb https://mirrors.aliyun.com/debian/ \(#DebianVersion)-backports main non-free contrib
		deb-src https://mirrors.aliyun.com/debian/ \(#DebianVersion)-backports main non-free contrib
		"""
	}

	_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				"source": source
				if platform != _|_ {
					"platform": platform
				}
			},
			docker.#Copy & {
				contents: _sourcesList.output
				source:   "/sources.list"
				dest:     "/etc/apt/sources.list"
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

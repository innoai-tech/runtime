package imagetool

import (
	"strings"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"
)

#Pull: {
	auths: [Host=string]: #Auth
	source: docker.#Ref

	resolveMode: *"default" | "forcePull" | "preferLocal"
	platform?:   string

	_host: strings.Split("\(source)", "/")[0]

	_pull: core.#Pull & {
		"source":      source
		"resolveMode": resolveMode

		if auths["\(_host)"] != _|_ {
			"auth": auths["\(_host)"]
		}

		if platform != _|_ {
			"platform": platform
		}
	}

	output: docker.#Image & {
		rootfs: _pull.output
		config: _pull.config
		// to valid platform
		"platform": _pull.platform
		if platform != _|_ {
			"platform": platform
		}
	}
}

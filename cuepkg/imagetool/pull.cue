package imagetool

import (
	"strings"

	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Pull: {
	source: docker.#Ref
	auths: [Host=string]: #Auth
	resolveMode: *"default" | "forcePull" | "preferLocal"
	platform?:   string

	_host: strings.Split(source, "/")[0]

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
		rootfs:   _pull.output
		config:   _pull.config
		platform: _pull.platform
	}
}

package imagetool

import (
	"strings"

	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Pull: {
	auths: [Host=string]: #Auth
	mirror: #Mirror

	source: docker.#Ref

	resolveMode: *"default" | "forcePull" | "preferLocal"
	platform?:   string

	_host: strings.Split("\(source)", "/")[0]

	_source: [
			if (mirror.pull != "" && !strings.HasPrefix(source, mirror.pull)) {
			"\(mirror.pull)\(source)"
		},
		source,
	][0]

	_pull: core.#Pull & {
		"source":      _source
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

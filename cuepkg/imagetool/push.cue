package imagetool

import (
	"strings"

	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Push: {
	auths: [Host=string]: #Auth
	dest:   docker.#Ref
	result: docker.#Ref & _push.result

	_host: core.#Nop & {
		input: strings.Split("\(dest)", "/")[0]
	}

	_push: core.#Push & {
		"dest": dest

		if auths["\(_host.output)"] != _|_ {
			"auth": auths["\(_host.output)"]
		}
	}

	{
		image: docker.#Image

		_push: {
			input:  image.rootfs
			config: image.config

			if (image.platform != _|_) {
				platform: image.platform
			}
		}
	} | {
		images: [Platform=string]: docker.#Image

		_push: inputs: {
			for _p, _image in images {
				"\(_p)": {
					input:  _image.rootfs
					config: _image.config
				}
			}
		}
	}
}

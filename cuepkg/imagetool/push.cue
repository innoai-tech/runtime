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

	_host: strings.Split(dest, "/")[0]

	_push: core.#Push & {
		"dest": dest
		if auths["\(_host)"] != _|_ {
			"auth": auths["\(_host)"]
		}
	}

	image?: docker.#Image
	images: [Platform=string]: docker.#Image

	if image != _|_ {
		_push: {
			input:    image.rootfs
			config:   image.config
			platform: image.platform
		}
	}

	if image == _|_ {
		_push: {
			inputs: {
				for _p, _image in images {
					"\(_p)": {
						input:  _image.rootfs
						config: _image.config
					}
				}
			}
		}
	}
}

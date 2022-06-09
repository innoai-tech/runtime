package test

import (
	"github.com/innoai-tech/runtime/cuepkg/tool"
)

{
	t: {
		// https://github.com/moby/buildkit/blob/master/docs/buildkitd.toml.md
		debug: true

		// root is where all buildkit state is stored.
		root: "/var/lib/buildkit"
		grpc: {
			address: ["tcp://0.0.0.0:1234"]
			uid: 0
			gid: 0
		}
		worker: oci: {
			enabled:       true
			gc:            true
			snapshotter:   "auto"
			gckeepstorage: 9000 // MB
			gcpolicy: [
				{
					filters: [
						"type==exec.cachemount",
					]
					keepBytes:    512000000
					keepDuration: 172800
				},
				{
					all:       true
					keepBytes: 1024000000
				},
			]
		}
		registry: {
			for hub in ["docker.io", "gcr.io", "ghcr.io", "k8s.gcr.io", "quay.io"] {
				"\(hub)": {
					mirrors: [
						"10.96.0.255:5000/mirrors/\(hub)",
					]
					http:     true
					insecure: true
				}
			}
		}
	}

	toml: (tool.#ToToml & {input: t}).output
}

package main

import (
	"wagon.octohelm.tech/core"

	"github.com/innoai-tech/runtime/cuepkg/golang"
	"github.com/innoai-tech/runtime/cuepkg/testing"
)

actions: {
	go: golang.#Project & {
		source: {
			path: "."
			include: [
				"cmd/",
				"go.mod",
			]
		}

		version: "v0.0.0"

		main: "./cmd/hello"

		goos: ["linux", "darwin"]
		goarch: ["amd64", "arm64"]

		build: {
			pre: ["go mod download"]
		}

		ship: {
			name: "ghcr.io/innoai-tech/runtime/hello"
			tag:  "\(version)"
			from: "gcr.io/distroless/static-debian11"
		}
	}
}

actions: test: testing.#Test & {
	"go build archive should output binaries": {
		_dir: core.#FileList & {
			input: actions.go.archive.output
			depth: 2
		}

		actual: _dir.output
		expect: [
			"/hello_darwin_amd64/hello",
			"/hello_darwin_arm64/hello",
			"/hello_linux_amd64/hello",
			"/hello_linux_arm64/hello",
		]
	}

	"go shiped image": {
		_image: actions.go.ship.image["linux/arm64"]

		_dir: core.#FileList & {
			input: _image.output.rootfs
			depth: 3
		}

		actual: _dir.output
		expect: [
			"/etc/debian_version",
			"/etc/dpkg/origins/",
			"/etc/ethertypes",
			"/etc/group",
			"/etc/host.conf",
			"/etc/issue",
			"/etc/issue.net",
			"/etc/nsswitch.conf",
			"/etc/os-release",
			"/etc/passwd",
			"/etc/protocols",
			"/etc/rpc",
			"/etc/services",
			"/etc/ssl/certs/",
			"/etc/update-motd.d/10-uname",
			"/hello",
			"/usr/lib/os-release",
			"/usr/sbin/tzconfig",
			"/usr/share/base-files/",
			"/usr/share/common-licenses/",
			"/usr/share/dict/",
			"/usr/share/doc/",
			"/usr/share/info/",
			"/usr/share/lintian/",
			"/usr/share/man/",
			"/usr/share/misc/",
			"/usr/share/zoneinfo/",
			"/var/lib/dpkg/",
			"/var/lib/misc/",
		]
	}
}

setting: {
	_env: core.#ClientEnv & {
		GH_USERNAME: string | *""
		GH_PASSWORD: core.#Secret
	}

	setup: core.#Setting & {
		registry: "ghcr.io": auth: {
			username: _env.GH_USERNAME
			secret:   _env.GH_PASSWORD
		}
	}
}

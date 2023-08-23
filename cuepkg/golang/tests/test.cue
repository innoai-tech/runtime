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
		_dir: core.#Entries & {
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

		_dir: core.#Entries & {
			input: _image.output.rootfs
			depth: 3
		}

		actual: _dir.output
		expect: [
			"/bin/",
			"/boot/",
			"/dev/",
			"/etc/debian_version",
			"/etc/default/",
			"/etc/dpkg/origins/",
			"/etc/ethertypes",
			"/etc/group",
			"/etc/host.conf",
			"/etc/issue",
			"/etc/issue.net",
			"/etc/nsswitch.conf",
			"/etc/os-release",
			"/etc/passwd",
			"/etc/profile.d/",
			"/etc/protocols",
			"/etc/rpc",
			"/etc/services",
			"/etc/skel/",
			"/etc/ssl/certs/",
			"/etc/update-motd.d/10-uname",
			"/hello",
			"/home/nonroot/",
			"/lib/",
			"/proc/",
			"/root/",
			"/run/",
			"/sbin/",
			"/sys/",
			"/tmp/",
			"/usr/bin/",
			"/usr/games/",
			"/usr/include/",
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
			"/usr/src/",
			"/var/backups/",
			"/var/cache/",
			"/var/lib/dpkg/",
			"/var/lib/misc/",
			"/var/local/",
			"/var/lock/",
			"/var/log/",
			"/var/run/",
			"/var/spool/",
			"/var/tmp/",
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

package main

import (
	"wagon.octohelm.tech/core"

	"github.com/innoai-tech/runtime/cuepkg/distroless"
	"github.com/innoai-tech/runtime/cuepkg/testing"
)

actions: test: testing.#Test & {
	"base-files should contains correct files": {
		_pkg: distroless.#BaseFiles & {
			platform: "linux/arm64"
		}

		_filelist: core.#Entries & {
			input: _pkg.output
			depth: -1
		}

		actual: _filelist.output
		expect: [
			"/bin/",
			"/boot/",
			"/dev/",
			"/etc/debian_version",
			"/etc/default/",
			"/etc/dpkg/origins/debian",
			"/etc/host.conf",
			"/etc/issue",
			"/etc/issue.net",
			"/etc/os-release",
			"/etc/profile.d/",
			"/etc/skel/",
			"/etc/update-motd.d/10-uname",
			"/home/",
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
			"/usr/sbin/",
			"/usr/share/base-files/dot.bashrc",
			"/usr/share/base-files/dot.profile",
			"/usr/share/base-files/dot.profile.md5sums",
			"/usr/share/base-files/info.dir",
			"/usr/share/base-files/motd",
			"/usr/share/base-files/profile",
			"/usr/share/base-files/profile.md5sums",
			"/usr/share/base-files/staff-group-for-usr-local",
			"/usr/share/common-licenses/Apache-2.0",
			"/usr/share/common-licenses/Artistic",
			"/usr/share/common-licenses/BSD",
			"/usr/share/common-licenses/CC0-1.0",
			"/usr/share/common-licenses/GFDL",
			"/usr/share/common-licenses/GFDL-1.2",
			"/usr/share/common-licenses/GFDL-1.3",
			"/usr/share/common-licenses/GPL",
			"/usr/share/common-licenses/GPL-1",
			"/usr/share/common-licenses/GPL-2",
			"/usr/share/common-licenses/GPL-3",
			"/usr/share/common-licenses/LGPL",
			"/usr/share/common-licenses/LGPL-2",
			"/usr/share/common-licenses/LGPL-2.1",
			"/usr/share/common-licenses/LGPL-3",
			"/usr/share/common-licenses/MPL-1.1",
			"/usr/share/common-licenses/MPL-2.0",
			"/usr/share/dict/",
			"/usr/share/doc/base-files/copyright",
			"/usr/share/info/",
			"/usr/share/lintian/overrides/",
			"/usr/share/man/",
			"/usr/share/misc/",
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

	"ca certificates should contains correct files": {
		_pkg: distroless.#CaCertificates & {
			platform: "linux/arm64"
		}

		_filelist: core.#Entries & {
			input: _pkg.output
			depth: 3
		}

		actual: _filelist.output
		_expect: [
			"/etc/ca-certificates/update.d/",
			"/etc/ssl/certs/",
			"/usr/sbin/",
			"/usr/share/ca-certificates/",
			"/usr/share/doc/",
			"/usr/share/man/",
		]
	}

	"netbase should contains correct files": {
		_pkg: distroless.#Netbase & {
			platform: "linux/arm64"
		}

		_filelist: core.#Entries & {
			input: _pkg.output
		}

		actual: _filelist.output
		expect: [
			"/etc/ethertypes",
			"/etc/protocols",
			"/etc/rpc",
			"/etc/services",
			"/usr/share/doc/netbase/copyright",
		]
	}

	"static should contains correct files": {
		_static: distroless.#Static & {
			platform: "linux/arm64"
		}

		_filelist: core.#Entries & {
			input: _static.output.rootfs
			depth: 3
		}

		actual: _filelist.output
		expect: [
			"/bin/",
			"/boot/",
			"/dev/",
			"/etc/ca-certificates/update.d/",
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
			"/home/",
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
			"/usr/sbin/",
			"/usr/share/base-files/",
			"/usr/share/ca-certificates/",
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

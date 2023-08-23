package distroless

import (
	"strings"

	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"

	"github.com/innoai-tech/runtime/cuepkg/debian"
)

#Extract: {
	debianversion: string | *debian.#Version
	platform:      string
	packages: [pkgName=string]: debian.#PackageOption

	include: [...string] | *[]
	exclude: [...string] | *[]

	_debian: debian.#Build & {
		"debianversion": debianversion
		"platform":      platform
		"packages":      packages
	}

	_pkg_path: {
		for pkgName, _ in packages {
			"\(pkgName)": {
				_run: docker.#Run & {
					input: _debian.output
					command: {
						name: "sh"
						flags: "-c": """
						dpkg -L \(pkgName) | xargs sh -c 'for f; do if [ -d "$f" ]; then echo "$f" >> /dirlist; else echo "$f" >> /filelist; fi done'
						"""
					}
				}

				_dirlist: core.#ReadFile & {
					input: _run.output.rootfs
					path:  "/dirlist"
				}

				_filelist: core.#ReadFile & {
					input: _run.output.rootfs
					path:  "/filelist"
				}

				dirs:  strings.Split(strings.TrimSpace(_dirlist.contents), "\n")
				files: strings.Split(strings.TrimSpace(_filelist.contents), "\n")
			}
		}
	}

	_mkdir: core.#Mkdir & {
		path: [
			for p in _pkg_path for d in p.dirs {
				d
			},
		]
	}

	_copy_files: core.#Copy & {
		"input":    _mkdir.output
		"contents": _debian.output.rootfs
		"include": [
			for p in _pkg_path for f in p.files {
				strings.TrimPrefix(f, "/")
			},
			for f in include {
				f
			},
		]
		"exclude": exclude
	}

	output: _copy_files.output
}

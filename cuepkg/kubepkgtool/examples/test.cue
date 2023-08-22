package main

import (
	"wagon.octohelm.tech/core"
	"github.com/innoai-tech/runtime/cuepkg/kubepkgtool"
)

actions: {
	test: {
		_do: core.#Nop & {
			input: {
				extract_main: kubepkgtool.#ExtractTarget & {
					name: "main"
				}

				extract_develop: kubepkgtool.#ExtractTarget & {
					name: "develop"
				}

				extract_feature: kubepkgtool.#ExtractTarget & {
					name: "feat/xxx"
				}

				extract_feature_with_env: kubepkgtool.#ExtractTarget & {
					name: "feat/xxx.develop"
				}

				extract_tag: kubepkgtool.#ExtractTarget & {
					name: "v3.0.0"
					tag:  "\(name)"
				}
			}
		}

		result: _do.output
	}
}

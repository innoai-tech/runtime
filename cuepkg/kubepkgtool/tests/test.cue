package main

import (
	"github.com/innoai-tech/runtime/cuepkg/kubepkgtool"
	"github.com/innoai-tech/runtime/cuepkg/testing"
)

actions: test: testing.#Test & {
	"branch main should resolve env as default": {
		_extract: kubepkgtool.#ExtractTarget & {
			name: "main"
		}

		actual: _extract.output
		expect: {
			env:    "default"
			suffix: ""
		}
	}

	"branch develop should resolve env as default": {
		_extract: kubepkgtool.#ExtractTarget & {
			name: "develop"
		}

		actual: _extract.output
		expect: {
			env:    "staging"
			suffix: ""
		}
	}

	"branch feature should resolve env as default and suffix": {
		_extract: kubepkgtool.#ExtractTarget & {
			name: "feat/xxx"
		}

		actual: _extract.output
		expect: {
			env:    "default"
			suffix: "--xxx"
		}
	}

	"branch feature with env should resolve env as default and suffix": {
		_extract: kubepkgtool.#ExtractTarget & {
			name: "feat/xxx.staging"
		}

		actual: _extract.output
		expect: {
			env:    "staging"
			suffix: "--xxx"
		}
	}

	"tag should resolve env default": {
		_extract: kubepkgtool.#ExtractTarget & {
			name: "v3.0.0"
			tag:  "\(name)"
		}

		actual: _extract.output
		expect: {
			env:    "default"
			suffix: ""
		}
	}
}

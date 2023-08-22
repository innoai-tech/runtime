package kubepkgtool

import (
	"strings"

	"wagon.octohelm.tech/core"
)

#Target: {
	_env: core.#ClientEnv & {
		CI_COMMIT_REF_NAME: string | *""
		CI_COMMIT_TAG:      string | *""
	}

	_extract: #ExtractTarget & {
		name: _env.CI_COMMIT_REF_NAME
		tag:  _env.CI_COMMIT_TAG
	}

	output: _extract.output
}

#ExtractTarget: {
	name: string
	tag:  string | *""

	_branch: [
			if tag == name {
			ref: tag
			env: "default"
		},
		{
			let _parts = strings.Split(name, ".")

			ref: _parts[0]
			env: [
				if len(_parts) > 1 {
					_parts[1]
				},
				"",
			][0]
		},
	][0]

	output: {
		suffix: [
			if strings.HasPrefix(_branch.ref, "feat/") {
				"--\(strings.TrimPrefix(_branch.ref, "feat/"))"
			},
			if strings.HasPrefix(_branch.ref, "feature/") {
				"--\(strings.TrimPrefix(_branch.ref, "feature/"))"
			},
			"",
		][0]

		env: [
			if _branch.env != "" {
				_branch.env
			},
			if _branch.ref == "develop" {
				"staging"
			},
			"default",
		][0]
	}
}

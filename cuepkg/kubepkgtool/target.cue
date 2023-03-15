package kubepkgtool

import (
	"strings"

	"wagon.octohelm.tech/core"
)

#Target: {
	_env: core.#ClientEnv & {
		CI_COMMIT_REF_NAME: string | *""
	}

	_extract: core.#Nop & {
		input: {
			_name: _env.CI_COMMIT_REF_NAME

			_branch: {
				let _parts = strings.Split(_name, ".")

				ref: _parts[0]
				env: [
					if len(_parts) > 1 {
						_parts[1]
					},
					"",
				][0]
			}

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

	output: _extract.output
}

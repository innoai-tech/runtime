package tool

import (
	"dagger.io/dagger/core"
)

#BuildCacheMounts: {
	#caches: [Name=string]: string

	for _n, _p in #caches {
		"\(_p)": core.#Mount & {
			dest:     _p
			contents: core.#CacheDir & {
				id: "\(_n)"
			}
		}
	}
}

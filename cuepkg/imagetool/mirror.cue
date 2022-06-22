package imagetool

import (
	"strings"
)

#Mirror: {
	// mirror for docker pull
	// example x.io/
	pull: string | *""

	//  mirror for linux deps
	linux: string | *""
}

#SourcePatch: {
	mirror: #Mirror
	source: string
	output: [
		if (mirror.pull != "" && !strings.HasPrefix(source, mirror.pull)) {
			"\(mirror.pull)\(source)"
		},
		source,
	][0]
}

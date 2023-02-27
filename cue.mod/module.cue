module: "github.com/innoai-tech/runtime"

require: {
	"k8s.io/api":          "v0.25.4"
	"wagon.octohelm.tech": "v0.0.0-20200202235959-3d91e2e3161f"
}

require: {
	"k8s.io/apimachinery": "v0.25.4" @indirect()
}

replace: {
	"k8s.io/api":          "" @import("go")
	"k8s.io/apimachinery": "" @import("go")
}

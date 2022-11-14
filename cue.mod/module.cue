module: "github.com/innoai-tech/runtime"

require: {
	"dagger.io":          "v0.3.0"
	"k8s.io/api":         "v0.25.4"
	"universe.dagger.io": "v0.3.0"
}

require: {
	"k8s.io/apimachinery": "v0.25.4" @indirect()
}

replace: {
	"k8s.io/api":          "" @import("go")
	"k8s.io/apimachinery": "" @import("go")
}

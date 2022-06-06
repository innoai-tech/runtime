module: "github.com/innoai-tech/runtime"

require: {
	"dagger.io":                          "v0.2.8-0.20220513062922-fef589b33ac3" @vcs("release-main")
	"github.com/innoai-tech/webappserve": "v0.0.0-20220601100730-26b81b65d12a"
	"k8s.io/api":                         "v0.24.1"
	"universe.dagger.io":                 "v0.2.8-0.20220513062922-fef589b33ac3" @vcs("release-main")
}

require: {
	"k8s.io/apimachinery": "v0.24.1" @indirect()
}

replace: {
	"dagger.io":          "github.com/morlay/dagger/pkg/dagger.io@release-main"
	"universe.dagger.io": "github.com/morlay/dagger/pkg/universe.dagger.io@release-main"
}

replace: {
	"k8s.io/api":          "" @import("go")
	"k8s.io/apimachinery": "" @import("go")
}

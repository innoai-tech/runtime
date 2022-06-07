module: "github.com/innoai-tech/runtime"

require: {
	"dagger.io":                          "v0.2.17-0.20220607100522-de1dd909833e"
	"github.com/innoai-tech/webappserve": "v0.0.0-20220601100730-26b81b65d12a"
	"k8s.io/api":                         "v0.24.1"
	"universe.dagger.io":                 "v0.2.17-0.20220607100522-de1dd909833e"
}

require: {
	"k8s.io/apimachinery": "v0.24.1" @indirect()
}

replace: {
	"dagger.io":          "github.com/morlay/dagger/pkg/dagger.io@v0.2.17-0.20220607100522-de1dd909833e"
	"universe.dagger.io": "github.com/morlay/dagger/pkg/universe.dagger.io@v0.2.17-0.20220607100522-de1dd909833e"
}

replace: {
	"k8s.io/api":          "" @import("go")
	"k8s.io/apimachinery": "" @import("go")
}

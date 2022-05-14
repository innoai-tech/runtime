module: "github.com/innoai-tech/webappserve"

require: {
	"dagger.io":          "v0.2.8-0.20220513062922-fef589b33ac3" @vcs("release-main")
	"universe.dagger.io": "v0.2.8-0.20220513062922-fef589b33ac3" @vcs("release-main")
}

replace: {
	"dagger.io":          "github.com/morlay/dagger/pkg/dagger.io@release-main"
	"universe.dagger.io": "github.com/morlay/dagger/pkg/universe.dagger.io@release-main"
}

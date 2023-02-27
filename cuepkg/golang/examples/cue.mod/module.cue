module: ""

require: {
	"github.com/innoai-tech/runtime": "v0.0.0-20230216064403-ba7b8c4f9db2"
	"wagon.octohelm.tech":            "v0.0.0-20200202235959-3d91e2e3161f"
}

require: {
	"dagger.io":          "v0.3.0" @indirect()
	"universe.dagger.io": "v0.3.0" @indirect()
}

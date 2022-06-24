debug:
	GIT_SHA=12312312312313132123 dagger do -p ./cuepkg/golang/examples/test.cue ver

test.%:
	dagger -l=debug do -p ./cuepkg/$*/examples/test.cue test

test: test.debian test.golang test.imagetool

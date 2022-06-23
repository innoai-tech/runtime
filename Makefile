test.%:
	dagger -l=debug do -p ./cuepkg/$*/examples/test.cue test

test: test.debian test.golang test.imagetool

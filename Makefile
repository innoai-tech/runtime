test.%:
	dagger do -p ./cuepkg/$*/examples/test.cue test

test: test.debian test.golang

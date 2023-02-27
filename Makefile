test.%:
	wagon do -p ./cuepkg/$*/examples/test.cue test

test:
	$(MAKE) test.debian
	$(MAKE) test.golang
	$(MAKE) test.imagetool

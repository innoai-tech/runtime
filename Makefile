export BUILDKIT_HOST =

test.%:
	wagon do -p ./cuepkg/$*/examples/test.cue test

test:
	$(MAKE) test.debian
	$(MAKE) test.golang
	$(MAKE) test.imagetool
	$(MAKE) test.kubepkgtool

clean:
	find ./cuepkg -name 'cue.mod' -type d -prune -print -exec rm -rf '{}' \;

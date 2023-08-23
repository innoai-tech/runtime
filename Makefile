export BUILDKIT_HOST =

test.%:
	wagon do -p ./cuepkg/$*/tests/test.cue test

test: \
	test.debian \
	test.golang \
	test.kubepkgtool

clean:
	find ./cuepkg -name 'cue.mod' -type d -prune -print -exec rm -rf '{}' \;


debug:
	GIT_SHA=12312312312313132123 dagger do -p ./cuepkg/golang/examples/test.cue go ship push/linux/arm64
	GIT_SHA=12312312312313132123 dagger do -p ./cuepkg/golang/examples/test.cue go ship push/linux/amd64
	CONTAINER_REGISTRY=ghcr.io GIT_SHA=12312312312313132123 dagger do -p ./cuepkg/golang/examples/test.cue go ship push/x

test.%:
	dagger -l=debug do -p ./cuepkg/$*/examples/test.cue test

test:
	$(MAKE) test.debian
	$(MAKE) test.golang
	$(MAKE) test.imagetool

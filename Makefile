export GIT_SHA ?= $(shell git rev-parse HEAD)
export GIT_REF ?= HEAD

build:
	dagger do build
.PHONY: build

push:
	dagger do push
.PHONY: push

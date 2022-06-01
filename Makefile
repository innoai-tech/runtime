export GIT_SHA ?= $(shell git rev-parse HEAD)
export GIT_REF ?= HEAD

.PHONY: build
build:
	dagger do build

push:
	dagger do push

go.test:
	go test -v -race ./pkg/...

go.tidy:
	go mod tidy

node.dep:
	pnpm install

node.upgrade:
	pnpm up -r --latest

node.fmt:
	./node_modules/.bin/prettier --write "nodepkg/{,**/}{,**/}*.{ts,tsx,json,md}"

node.test:
	./node_modules/.bin/jest nodepkg

node.build: node.dep
	pnpm -r --filter=!monobundle exec ../../../node_modules/.bin/monobundle

node.pub:
	pnpm -r publish --no-git-checks

cue.test:
	cuem eval -o test.yaml ./cuepkg/kube/test
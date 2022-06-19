export GIT_SHA ?= $(shell git rev-parse HEAD)
export GIT_REF ?= HEAD

.PHONY: build
build:
	dagger do export

ship:
	dagger do ship

shipfs:
	#dagger do shipfs dump linux\/amd64
	#dagger do shipfs dump linux\/arm64
	dagger do shipfs create

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

cue.test.tool:
	cuem eval -o test.yaml ./cuepkg/tool/test

d.test.%:
	dagger do -p ./cuepkg/$*/examples/test.cue load


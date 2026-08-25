.PHONY: build install test

build:
	./Scripts/build-release.sh

install:
	./Scripts/install.sh

test:
	./Scripts/test.sh

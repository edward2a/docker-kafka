# TEMPORARY VARIABLES
DOCKER_REPOSITORY ?= edward2a/kafka
DOCKER_TAG ?= 2.0.0

.PHONY: build-deps build publish

help:
	@echo "This is just a help line"

build:
	docker build -t ${DOCKER_REPOSITORY}:${DOCKER_TAG} .

publish:
	docker push ${DOCKER_REPOSITORY}:${DOCKER_TAG}

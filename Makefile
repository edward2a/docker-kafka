# TEMPORARY VARIABLES
DOCKER_REPOSITORY ?= edward2a/kafka
DOCKER_TAG ?= 2.0.0-single_node

.PHONY: build-deps build publish

build-deps:

build:
	docker build -t ${DOCKER_REPOSITORY}:${DOCKER_TAG} .

publish:
	docker push ${DOCKER_REPOSITORY}:${DOCKER_TAG}

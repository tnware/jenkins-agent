# Makefile for Jenkins Agent Docker Image

# Variables
IMAGE_NAME := ghcr.io/tnware/jenkins-agent
VERSION := v0.1.6
LATEST_TAG := latest

.PHONY: help build push build-push test clean lint

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Docker image
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(LATEST_TAG)

push: ## Push the Docker image to registry
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):$(LATEST_TAG)

build-push: build push ## Build and push the Docker image

test: ## Test the Docker image (basic validation)
	@echo "Testing Docker image..."
	@docker run --rm $(IMAGE_NAME):$(VERSION) docker --version
	@docker run --rm $(IMAGE_NAME):$(VERSION) python3 --version
	@docker run --rm $(IMAGE_NAME):$(VERSION) node --version
	@docker run --rm $(IMAGE_NAME):$(VERSION) npm --version
	@echo "All tests passed!"

clean: ## Remove local Docker images
	docker rmi $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(LATEST_TAG) || true

lint: ## Lint Dockerfile using hadolint
	@echo "Linting Dockerfile..."
	@docker run --rm -v "$(PWD):/workspace" -w /workspace hadolint/hadolint hadolint Dockerfile --config .github/hadolint.yaml


.PHONY: build test push clean help login check-auth

# Suricata version - update this when upgrading Suricata
SURICATA_VERSION ?= 8.0.0

IMAGE_NAME ?= suricata
TAG ?= $(SURICATA_VERSION)
DOCKER_USERNAME ?= yourusername

# Default target
.DEFAULT_GOAL := help

# Platform detection for cross-compilation
# On macOS (Darwin), we need to explicitly build for linux/amd64
# CircleCI and Linux hosts don't need this flag
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    PLATFORM_FLAG = --platform linux/amd64
    $(info Building for Linux on macOS - using $(PLATFORM_FLAG))
else
    PLATFORM_FLAG =
    $(info Building on native Linux platform)
endif

build: ## Build the Suricata Docker image
	@echo "Building Suricata $(SURICATA_VERSION) container..."
	@echo "Checking Docker Hub authentication..."
	@docker pull alpine:3.20 >/dev/null 2>&1 || (echo "Error: Docker Hub authentication required. Run 'docker login' first." && exit 1)
	docker build $(PLATFORM_FLAG) -t $(IMAGE_NAME):$(TAG) -f docker/Dockerfile .

test: ## Test the built Docker image
	docker run $(PLATFORM_FLAG) --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" $(IMAGE_NAME):$(TAG) suricata -V

push: ## Push the image to Docker Hub
	docker tag $(IMAGE_NAME):$(TAG) $(DOCKER_USERNAME)/$(IMAGE_NAME):$(TAG)
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(TAG)

push-latest: ## Push the image to Docker Hub with both version tag and latest
	docker tag $(IMAGE_NAME):$(TAG) $(DOCKER_USERNAME)/$(IMAGE_NAME):$(TAG)
	docker tag $(IMAGE_NAME):$(TAG) $(DOCKER_USERNAME)/$(IMAGE_NAME):latest
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(TAG)
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):latest

clean: ## Remove local Docker images
	docker rmi $(IMAGE_NAME):$(TAG) || true
	docker rmi $(DOCKER_USERNAME)/$(IMAGE_NAME):$(TAG) || true

all: build test ## Build and test the image

login: ## Log in to Docker Hub
	docker login

check-auth: ## Check Docker Hub authentication
	@echo "Testing Docker Hub authentication..."
	@docker pull alpine:3.20 >/dev/null 2>&1 && echo "✓ Docker Hub authentication OK" || echo "✗ Docker Hub authentication required - run 'make login'"

help: ## Show this help message
	@echo "Suricata Container Build System"
	@echo "Platform: $(UNAME_S)"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Variables:"
	@echo "  SURICATA_VERSION Suricata version (default: $(SURICATA_VERSION))"
	@echo "  IMAGE_NAME       Docker image name (default: $(IMAGE_NAME))"
	@echo "  TAG              Docker image tag (default: $(TAG))"
	@echo "  DOCKER_USERNAME  Docker Hub username (default: $(DOCKER_USERNAME))"

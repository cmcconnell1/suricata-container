.PHONY: build test push clean help login check-auth

# =============================================================================
# SURICATA CONTAINER BUILD CONFIGURATION
# =============================================================================
# Version Control Variables - Override these to build different versions
#
# Examples:
#   SURICATA_VERSION=7.0.6 make build
#   ALPINE_VERSION=3.19 SURICATA_VERSION=7.0.6 make build
#   export SURICATA_VERSION=7.0.6 && make build && make test
# =============================================================================

# Suricata version - update this when upgrading Suricata
# Supported versions: 8.0.x (latest), 7.0.x (stable), 6.0.x (legacy)
SURICATA_VERSION ?= 8.0.0

# Alpine Linux base image version
# Note: Suricata 8.x requires Alpine 3.20+ for Rust 1.78.0 support
ALPINE_VERSION ?= 3.20

# Docker image configuration
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
	@echo "Building Suricata $(SURICATA_VERSION) container with Alpine $(ALPINE_VERSION)..."
	@echo "Checking Docker Hub authentication..."
	@docker pull alpine:$(ALPINE_VERSION) >/dev/null 2>&1 || (echo "Error: Docker Hub authentication required. Run 'docker login' first." && exit 1)
	docker build $(PLATFORM_FLAG) \
		--build-arg SURICATA_VERSION=$(SURICATA_VERSION) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		-t $(IMAGE_NAME):$(TAG) \
		-f docker/Dockerfile .

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
	@echo "Version Control Variables:"
	@echo "  SURICATA_VERSION Suricata version (current: $(SURICATA_VERSION))"
	@echo "  ALPINE_VERSION   Alpine Linux version (current: $(ALPINE_VERSION))"
	@echo "  IMAGE_NAME       Docker image name (current: $(IMAGE_NAME))"
	@echo "  TAG              Docker image tag (current: $(TAG))"
	@echo "  DOCKER_USERNAME  Docker Hub username (current: $(DOCKER_USERNAME))"
	@echo ""
	@echo "Version Control Examples:"
	@echo "  SURICATA_VERSION=7.0.6 make build"
	@echo "  ALPINE_VERSION=3.19 SURICATA_VERSION=7.0.6 make build"
	@echo "  export SURICATA_VERSION=7.0.6 && make build && make test"

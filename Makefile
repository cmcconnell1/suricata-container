.PHONY: build test push clean help login check-auth

# =============================================================================
# SURICATA CONTAINER BUILD CONFIGURATION
# =============================================================================
# Version Control Variables - Override these to build different versions
#
# Examples:
#   SURICATA_VERSION=7.0.6 make build
#   ORACLE_VERSION=9 SURICATA_VERSION=7.0.6 make build
#   BUILD_VARIANT=napatech BASE_OS=oracle make build
#   export SURICATA_VERSION=7.0.6 && make build && make test
# =============================================================================

# Suricata version - update this when upgrading Suricata
# Supported versions: 8.0.x (current), 7.0.x (stable), 6.0.x (legacy)
SURICATA_VERSION ?= 7.0.11

# Base image configuration
# Oracle Linux base image version (primary for legacy refactor)
ORACLE_VERSION ?= 9
# Alpine Linux base image version (lightweight alternative)
ALPINE_VERSION ?= 3.19

# Build variant configuration (legacy refactoring)
BUILD_VARIANT ?= afpacket
HYPERSCAN_VERSION ?= 5.4.0
BASE_OS ?= oracle

# Docker image configuration
IMAGE_NAME ?= suricata
TAG ?= $(SURICATA_VERSION)
DOCKER_USERNAME ?= yourusername

# Docker registry configuration (for future use)
# Uncomment and configure these variables when ready to push to registry
# DOCKER_REGISTRY ?= engineering2
# DOCKER_HUB_RW_USERNAME ?= example-user
# DOCKER_HUB_RW_PASSWORD_FILE ?= .docker_hub_rw_password

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

build: ## Build the Suricata Docker image (Alpine-based)
	@echo "Building Suricata $(SURICATA_VERSION) container with Alpine $(ALPINE_VERSION)..."
	@echo "Checking Docker Hub authentication..."
	@docker pull alpine:$(ALPINE_VERSION) >/dev/null 2>&1 || (echo "Error: Docker Hub authentication required. Run 'docker login' first." && exit 1)
	docker build $(PLATFORM_FLAG) \
		--build-arg SURICATA_VERSION=$(SURICATA_VERSION) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		-t $(IMAGE_NAME):$(TAG) \
		-f docker/Dockerfile .

build-oracle: ## Build the Suricata Docker image (Oracle Linux-based, legacy refactored)
	@echo "Building Suricata $(SURICATA_VERSION) container with Oracle Linux $(ORACLE_VERSION)..."
	@echo "Build variant: $(BUILD_VARIANT), Hyperscan: $(HYPERSCAN_VERSION)"
	docker build $(PLATFORM_FLAG) \
		--build-arg SURICATA_VERSION=$(SURICATA_VERSION) \
		--build-arg ORACLE_VERSION=$(ORACLE_VERSION) \
		--build-arg BUILD_VARIANT=$(BUILD_VARIANT) \
		--build-arg HYPERSCAN_VERSION=$(HYPERSCAN_VERSION) \
		-t $(IMAGE_NAME):$(TAG)-ol$(ORACLE_VERSION)-$(BUILD_VARIANT) \
		-f docker/Dockerfile.oracle-linux .

test: ## Test the built Docker image (Alpine-based)
	docker run $(PLATFORM_FLAG) --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" $(IMAGE_NAME):$(TAG) suricata -V

test-oracle: ## Test the built Oracle Linux Docker image
	docker run $(PLATFORM_FLAG) --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" $(IMAGE_NAME):$(TAG)-ol$(ORACLE_VERSION)-$(BUILD_VARIANT) /usr/local/bin/suricata -V

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
	docker rmi $(IMAGE_NAME):$(TAG)-ol$(ORACLE_VERSION)-$(BUILD_VARIANT) || true

all: build test ## Build and test the Alpine image
all-oracle: build-oracle test-oracle ## Build and test the Oracle Linux image

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
	@echo "  SURICATA_VERSION  Suricata version (current: $(SURICATA_VERSION))"
	@echo "  ALPINE_VERSION    Alpine Linux version (current: $(ALPINE_VERSION))"
	@echo "  ORACLE_VERSION    Oracle Linux version (current: $(ORACLE_VERSION))"
	@echo "  BUILD_VARIANT     Build variant: afpacket|napatech (current: $(BUILD_VARIANT))"
	@echo "  HYPERSCAN_VERSION Hyperscan version (current: $(HYPERSCAN_VERSION))"
	@echo "  IMAGE_NAME        Docker image name (current: $(IMAGE_NAME))"
	@echo "  TAG               Docker image tag (current: $(TAG))"
	@echo "  DOCKER_USERNAME   Docker Hub username (current: $(DOCKER_USERNAME))"
	@echo ""
	@echo "Build Examples:"
	@echo "  make build                                    # Alpine-based build"
	@echo "  make build-oracle                             # Oracle Linux build (afpacket)"
	@echo "  BUILD_VARIANT=napatech make build-oracle     # Oracle Linux build (napatech)"
	@echo "  SURICATA_VERSION=7.0.6 make build-oracle     # Custom version"
	@echo "  make all-oracle                               # Build and test Oracle Linux"

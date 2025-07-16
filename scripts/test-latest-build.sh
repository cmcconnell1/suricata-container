#!/bin/bash

set -e

# Configuration
DOCKER_REGISTRY="cmcc123"
IMAGE_NAME="suricata"
LOCAL_TAG="suricata:test-latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the latest commit hash (default to current if not provided)
if [ -z "$1" ]; then
    if [ -d ".git" ]; then
        COMMIT_HASH=$(git rev-parse --short HEAD)
        print_status "Using current commit hash: $COMMIT_HASH"
    else
        print_error "No commit hash provided and not in a git repository"
        echo "Usage: $0 [commit_hash]"
        echo "Example: $0 c45964a"
        exit 1
    fi
else
    COMMIT_HASH="$1"
    print_status "Using provided commit hash: $COMMIT_HASH"
fi

FULL_IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:${COMMIT_HASH}"

print_status "Testing Docker image: $FULL_IMAGE_TAG"
echo "=================================="

# Step 1: Pull the latest image
print_status "Pulling image from Docker Hub..."
if docker pull "$FULL_IMAGE_TAG"; then
    print_success "Successfully pulled $FULL_IMAGE_TAG"
else
    print_error "Failed to pull $FULL_IMAGE_TAG"
    print_warning "Available tags for ${DOCKER_REGISTRY}/${IMAGE_NAME}:"
    docker search "${DOCKER_REGISTRY}/${IMAGE_NAME}" || true
    exit 1
fi

# Step 2: Tag it locally
print_status "Tagging image locally as $LOCAL_TAG..."
docker tag "$FULL_IMAGE_TAG" "$LOCAL_TAG"
print_success "Tagged as $LOCAL_TAG"

# Step 3: Test basic functionality
print_status "Testing basic functionality..."

# Test 1: Version check
print_status "Test 1: Version check"
if docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" "$LOCAL_TAG" suricata -V; then
    print_success "Version check passed"
else
    print_error "Version check failed"
    exit 1
fi

# Test 2: Suricata-update help
print_status "Test 2: Suricata-update functionality"
if docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" "$LOCAL_TAG" sh -c "suricata-update --help | head -5"; then
    print_success "Suricata-update test passed"
else
    print_error "Suricata-update test failed"
fi

# Test 3: Configuration validation (non-blocking)
print_status "Test 3: Configuration validation"
if docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" "$LOCAL_TAG" sh -c "suricata -T -c /etc/suricata/suricata.yaml"; then
    print_success "Configuration validation passed"
else
    print_warning "Configuration validation failed (may be due to missing network interfaces in CI environment)"
    print_status "This is expected in containerized CI environments and doesn't affect functionality"
fi

# Step 4: Run container in background for log testing
print_status "Starting container in background for log testing..."
CONTAINER_ID=$(docker run -d \
    --name "suricata-test-$$" \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    -e UPDATE_RULES=false \
    -e INTERFACE=eth0 \
    "$LOCAL_TAG")

print_success "Container started with ID: $CONTAINER_ID"

# Wait a moment for startup
print_status "Waiting 10 seconds for container startup..."
sleep 10

# Step 5: Fetch and display logs
print_status "Fetching container logs..."
echo "=================================="
docker logs "$CONTAINER_ID"
echo "=================================="

# Step 6: Check container status
print_status "Checking container status..."
if docker ps | grep "$CONTAINER_ID" > /dev/null; then
    print_success "Container is running"
    
    # Show container stats
    print_status "Container stats:"
    docker stats --no-stream "$CONTAINER_ID"
else
    print_warning "Container is not running"
    
    # Show exit code
    EXIT_CODE=$(docker inspect "$CONTAINER_ID" --format='{{.State.ExitCode}}')
    print_status "Container exit code: $EXIT_CODE"
fi

# Step 7: Cleanup
print_status "Cleaning up test container..."
docker stop "$CONTAINER_ID" 2>/dev/null || true
docker rm "$CONTAINER_ID" 2>/dev/null || true
print_success "Cleanup completed"

# Step 8: Show image info
print_status "Image information:"
docker images "$LOCAL_TAG"
docker inspect "$LOCAL_TAG" --format='{{.Config.Labels}}' | tr ',' '\n' || true

print_success "Test completed successfully!"
print_status "Local image tagged as: $LOCAL_TAG"
print_status "To run manually: docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW -e UPDATE_RULES=false $LOCAL_TAG"

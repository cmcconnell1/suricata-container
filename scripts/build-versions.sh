#!/bin/bash
# =============================================================================
# MULTI-VERSION BUILD SCRIPT FOR SURICATA CONTAINER
# =============================================================================
# This script helps build and manage both Suricata 7.x (stable/default) and 
# 8.x (latest) versions with proper tagging and testing.
#
# Usage:
#   ./scripts/build-versions.sh [OPTIONS]
#
# Options:
#   --version 7|8|both    Build specific version or both (default: both)
#   --test               Run tests after building
#   --push               Push to Docker Hub after successful build/test
#   --tag-latest         Tag as latest (7.x gets 'latest', 8.x gets '8-latest')
#   --help               Show this help message
#
# Examples:
#   ./scripts/build-versions.sh --version both --test
#   ./scripts/build-versions.sh --version 7 --test --push
#   ./scripts/build-versions.sh --version 8 --tag-latest --push
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default options
VERSION="both"
RUN_TESTS=false
PUSH_IMAGES=false
TAG_LATEST=false
DOCKER_USERNAME=${DOCKER_USERNAME:-"yourusername"}

# Version configurations (updated for new branch structure)
declare -A VERSION_CONFIG
VERSION_CONFIG[7_BRANCH]="main"
VERSION_CONFIG[7_VERSION]="7.0.11"
VERSION_CONFIG[7_ALPINE]="3.19"
VERSION_CONFIG[8_BRANCH]="suricata-8.x"
VERSION_CONFIG[8_VERSION]="8.0.0"
VERSION_CONFIG[8_ALPINE]="3.20"

# Function to show help
show_help() {
    echo -e "${BOLD}Suricata Multi-Version Build Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --version 7|8|both    Build specific version or both (default: both)"
    echo "  --test               Run tests after building"
    echo "  --push               Push to Docker Hub after successful build/test"
    echo "  --tag-latest         Tag as latest (7.x gets 'latest', 8.x gets '8-latest')"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --version both --test"
    echo "  $0 --version 7 --test --push"
    echo "  $0 --version 8 --tag-latest --push"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_USERNAME      Docker Hub username (default: yourusername)"
    echo ""
    echo "Branch Structure:"
    echo "  7.x (stable/default) → main branch"
    echo "  8.x (latest)         → suricata-8.x branch"
    echo ""
}

# Function to build a specific version
build_version() {
    local version=$1
    local branch=${VERSION_CONFIG[${version}_BRANCH]}
    local suricata_version=${VERSION_CONFIG[${version}_VERSION]}
    local alpine_version=${VERSION_CONFIG[${version}_ALPINE]}
    
    echo -e "${BLUE}==============================================================================${NC}"
    echo -e "${BOLD}Building Suricata ${version}.x (${suricata_version})${NC}"
    echo -e "${BLUE}==============================================================================${NC}"
    echo -e "Branch: ${branch}"
    echo -e "Suricata Version: ${suricata_version}"
    echo -e "Alpine Version: ${alpine_version}"
    echo ""
    
    # Switch to the appropriate branch
    echo -e "${YELLOW}Switching to branch: ${branch}${NC}"
    git checkout ${branch}
    
    # Build the image
    echo -e "${YELLOW}Building Suricata ${version}.x container...${NC}"
    make build
    
    # Tag with version-specific tags
    echo -e "${YELLOW}Tagging image...${NC}"
    docker tag suricata:${suricata_version} suricata:${version}
    docker tag suricata:${suricata_version} ${DOCKER_USERNAME}/suricata:${suricata_version}
    docker tag suricata:${suricata_version} ${DOCKER_USERNAME}/suricata:${version}
    
    # Tag as latest based on version
    if [ "$TAG_LATEST" = true ]; then
        if [ "$version" = "7" ]; then
            echo -e "${YELLOW}Tagging 7.x as latest (stable default)...${NC}"
            docker tag suricata:${suricata_version} suricata:latest
            docker tag suricata:${suricata_version} ${DOCKER_USERNAME}/suricata:latest
        elif [ "$version" = "8" ]; then
            echo -e "${YELLOW}Tagging 8.x as 8-latest...${NC}"
            docker tag suricata:${suricata_version} suricata:8-latest
            docker tag suricata:${suricata_version} ${DOCKER_USERNAME}/suricata:8-latest
        fi
    fi
    
    echo -e "${GREEN}✓ Successfully built Suricata ${version}.x${NC}"
    echo ""
}

# Function to test a specific version
test_version() {
    local version=$1
    local suricata_version=${VERSION_CONFIG[${version}_VERSION]}
    
    echo -e "${BLUE}Testing Suricata ${version}.x (${suricata_version})${NC}"
    
    # Test the image
    if docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW --entrypoint="" suricata:${suricata_version} suricata -V; then
        echo -e "${GREEN}✓ Suricata ${version}.x test passed${NC}"
    else
        echo -e "${RED}✗ Suricata ${version}.x test failed${NC}"
        return 1
    fi
    echo ""
}

# Function to push a specific version
push_version() {
    local version=$1
    local suricata_version=${VERSION_CONFIG[${version}_VERSION]}
    
    echo -e "${BLUE}Pushing Suricata ${version}.x images to Docker Hub${NC}"
    
    # Push version-specific tags
    docker push ${DOCKER_USERNAME}/suricata:${suricata_version}
    docker push ${DOCKER_USERNAME}/suricata:${version}
    
    # Push latest tags if tagged
    if [ "$TAG_LATEST" = true ]; then
        if [ "$version" = "7" ]; then
            docker push ${DOCKER_USERNAME}/suricata:latest
        elif [ "$version" = "8" ]; then
            docker push ${DOCKER_USERNAME}/suricata:8-latest
        fi
    fi
    
    echo -e "${GREEN}✓ Successfully pushed Suricata ${version}.x images${NC}"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --test)
            RUN_TESTS=true
            shift
            ;;
        --push)
            PUSH_IMAGES=true
            shift
            ;;
        --tag-latest)
            TAG_LATEST=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate version parameter
if [[ ! "$VERSION" =~ ^(7|8|both)$ ]]; then
    echo -e "${RED}Error: --version must be 7, 8, or both${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Store current branch to restore later
ORIGINAL_BRANCH=$(git branch --show-current)

echo -e "${BOLD}Suricata Multi-Version Build${NC}"
echo -e "Version(s): ${VERSION}"
echo -e "Run Tests: ${RUN_TESTS}"
echo -e "Push Images: ${PUSH_IMAGES}"
echo -e "Tag Latest: ${TAG_LATEST}"
echo -e "Docker Username: ${DOCKER_USERNAME}"
echo ""

# Build versions (7.x first as it's now the default)
if [ "$VERSION" = "both" ] || [ "$VERSION" = "7" ]; then
    build_version 7
    if [ "$RUN_TESTS" = true ]; then
        test_version 7
    fi
    if [ "$PUSH_IMAGES" = true ]; then
        push_version 7
    fi
fi

if [ "$VERSION" = "both" ] || [ "$VERSION" = "8" ]; then
    build_version 8
    if [ "$RUN_TESTS" = true ]; then
        test_version 8
    fi
    if [ "$PUSH_IMAGES" = true ]; then
        push_version 8
    fi
fi

# Restore original branch
echo -e "${YELLOW}Restoring original branch: ${ORIGINAL_BRANCH}${NC}"
git checkout ${ORIGINAL_BRANCH}

echo -e "${GREEN}==============================================================================${NC}"
echo -e "${BOLD}${GREEN}Multi-Version Build Complete!${NC}"
echo -e "${GREEN}==============================================================================${NC}"

# Show built images
echo -e "${BLUE}Built images:${NC}"
docker images | grep suricata | head -10

#!/bin/bash

# Development setup script for Suricata container
# Automatically detects platform and provides appropriate commands

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect platform
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo -e "${BLUE}Suricata Container Development Setup${NC}"
echo "=================================="
echo "Platform: $PLATFORM"
echo "Architecture: $ARCH"
echo ""

# Platform-specific setup
case "$PLATFORM" in
    "Darwin")
        echo -e "${YELLOW}macOS detected${NC}"
        echo "- Docker builds will target linux/amd64 for production compatibility"
        echo "- Network monitoring capabilities are limited in Docker Desktop"
        echo "- Use bridge networking instead of --net=host for testing"
        echo ""
        
        # Check Docker Desktop
        if ! docker info >/dev/null 2>&1; then
            echo -e "${RED}Error: Docker Desktop is not running${NC}"
            echo "Please start Docker Desktop and try again"
            exit 1
        fi

        echo -e "${GREEN}Docker Desktop is running${NC}"

        # Check Docker Hub authentication
        echo "Checking Docker Hub authentication..."
        if ! docker pull hello-world >/dev/null 2>&1; then
            echo -e "${YELLOW}Warning: Docker Hub authentication required${NC}"
            echo "Docker Hub now requires authentication for image pulls."
            echo ""
            echo "To fix this:"
            echo "1. Create a free account at https://hub.docker.com"
            echo "2. Run: docker login"
            echo "3. Enter your Docker Hub credentials"
            echo ""
            read -p "Would you like to log in to Docker Hub now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker login
            else
                echo -e "${YELLOW}You'll need to authenticate with Docker Hub before building${NC}"
            fi
        else
            echo -e "${GREEN}Docker Hub authentication OK${NC}"
            # Clean up test image
            docker rmi hello-world >/dev/null 2>&1 || true
        fi
        ;;
        
    "Linux")
        echo -e "${YELLOW}Linux detected${NC}"
        echo "- Native Docker builds (no platform flags needed)"
        echo "- Full network monitoring capabilities available"
        echo "- Can use --net=host for production-like testing"
        echo ""
        
        # Check Docker
        if ! docker info >/dev/null 2>&1; then
            echo -e "${RED}Error: Docker is not running or not accessible${NC}"
            echo "Please start Docker daemon or check permissions"
            exit 1
        fi
        
        echo -e "${GREEN}Docker is running${NC}"
        ;;
        
    *)
        echo -e "${YELLOW}Unknown platform: $PLATFORM${NC}"
        echo "This script is designed for macOS and Linux"
        echo "You may need to adjust Docker commands manually"
        ;;
esac

echo ""
echo -e "${BLUE}Quick Start Commands:${NC}"
echo "  make help    - Show all available commands"
echo "  make build   - Build the container"
echo "  make test    - Test the container"
echo "  make all     - Build and test"
echo ""

# Offer to run initial build
read -p "Would you like to build the container now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Starting build...${NC}"
    make build
    
    echo ""
    echo -e "${GREEN}Build completed! Run 'make test' to test the container.${NC}"
else
    echo "Run 'make build' when you're ready to build the container."
fi

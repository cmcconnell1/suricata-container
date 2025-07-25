#!/bin/bash
# =============================================================================
# MULTI-VERSION SETUP SCRIPT FOR SURICATA CONTAINER
# =============================================================================
# This script sets up the repository structure to support both Suricata 7.x
# (stable/default) and 8.x (latest) versions using a branching strategy.
#
# Usage:
#   ./scripts/setup-multi-version.sh
#
# What this script does:
# 1. Creates suricata-8.x branch from current main (if needed)
# 2. Updates version defaults for 8.x branch
# 3. Adjusts Alpine version compatibility
# 4. Updates documentation for multi-version approach
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version configurations
SURICATA_7X_VERSION="7.0.11"
SURICATA_8X_VERSION="8.0.0"
ALPINE_7X_VERSION="3.19"  # Compatible with Rust 1.70.0+
ALPINE_8X_VERSION="3.20"  # Required for Rust 1.78.0+

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}SURICATA CONTAINER MULTI-VERSION SETUP${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${GREEN}Setting up repository to support:${NC}"
echo -e "  • Suricata 7.x (${SURICATA_7X_VERSION}) on main branch (stable/default)"
echo -e "  • Suricata 8.x (${SURICATA_8X_VERSION}) on suricata-8.x branch (latest)"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}Warning: Not on main branch (currently on: $CURRENT_BRANCH)${NC}"
    echo -e "This script should be run from the main branch."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if suricata-8.x branch already exists
if git show-ref --verify --quiet refs/heads/suricata-8.x; then
    echo -e "${YELLOW}Branch 'suricata-8.x' already exists.${NC}"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -D suricata-8.x
        echo -e "${GREEN}Deleted existing suricata-8.x branch${NC}"
    else
        echo -e "${YELLOW}Skipping branch creation${NC}"
        exit 0
    fi
fi

echo -e "${BLUE}Step 1: Creating suricata-8.x branch${NC}"
git checkout -b suricata-8.x
echo -e "${GREEN}✓ Created and switched to suricata-8.x branch${NC}"

echo -e "${BLUE}Step 2: Updating version defaults for Suricata 8.x${NC}"

# Update Makefile for 8.x defaults
sed -i.bak "s/SURICATA_VERSION ?= ${SURICATA_7X_VERSION}/SURICATA_VERSION ?= ${SURICATA_8X_VERSION}/" Makefile
sed -i.bak "s/ALPINE_VERSION ?= ${ALPINE_7X_VERSION}/ALPINE_VERSION ?= ${ALPINE_8X_VERSION}/" Makefile

# Update Dockerfile for 8.x defaults
sed -i.bak "s/ARG ALPINE_VERSION=${ALPINE_7X_VERSION}/ARG ALPINE_VERSION=${ALPINE_8X_VERSION}/" docker/Dockerfile
sed -i.bak "s/ARG SURICATA_VERSION=${SURICATA_7X_VERSION}/ARG SURICATA_VERSION=${SURICATA_8X_VERSION}/" docker/Dockerfile

# Update Rust version requirement for 8.x (uses newer Rust)
sed -i.bak "s/ARG RUST_VERSION=1.70.0/ARG RUST_VERSION=1.78.0/" docker/Dockerfile
sed -i.bak "s/ARG PYTHON_VERSION=3.11/ARG PYTHON_VERSION=3.12/" docker/Dockerfile

# Update Dockerfile comments
sed -i.bak "s/default: 3.19/default: 3.20/" docker/Dockerfile
sed -i.bak "s/default: 7.0.11/default: 8.0.0/" docker/Dockerfile
sed -i.bak "s/default: 1.70.0/default: 1.78.0/" docker/Dockerfile
sed -i.bak "s/default: 3.11/default: 3.12/" docker/Dockerfile

# Clean up backup files
rm -f Makefile.bak docker/Dockerfile.bak

echo -e "${GREEN}✓ Updated version defaults:${NC}"
echo -e "  • Suricata: ${SURICATA_8X_VERSION}"
echo -e "  • Alpine: ${ALPINE_8X_VERSION}"
echo -e "  • Rust: 1.78.0"
echo -e "  • Python: 3.12"

echo -e "${BLUE}Step 3: Committing changes to suricata-8.x branch${NC}"
git add Makefile docker/Dockerfile
git commit -m "Configure defaults for Suricata 8.x branch

- Set SURICATA_VERSION default to ${SURICATA_8X_VERSION}
- Set ALPINE_VERSION default to ${ALPINE_8X_VERSION}
- Set RUST_VERSION to 1.78.0 for 8.x compatibility
- Set PYTHON_VERSION to 3.12
- Maintain compatibility with existing build system"

echo -e "${GREEN}✓ Committed changes to suricata-8.x branch${NC}"

echo -e "${BLUE}Step 4: Switching back to main branch${NC}"
git checkout main
echo -e "${GREEN}✓ Switched back to main branch${NC}"

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}MULTI-VERSION SETUP COMPLETE!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo ""
echo -e "${BLUE}Repository structure:${NC}"
echo -e "  • ${GREEN}main branch${NC}        → Suricata 7.x (${SURICATA_7X_VERSION}) - stable/default"
echo -e "  • ${GREEN}suricata-8.x branch${NC} → Suricata 8.x (${SURICATA_8X_VERSION}) - latest features"
echo ""
echo -e "${BLUE}Usage examples:${NC}"
echo -e "${YELLOW}Build Suricata 7.x (from main branch - default):${NC}"
echo -e "  git checkout main"
echo -e "  make build"
echo ""
echo -e "${YELLOW}Build Suricata 8.x (from suricata-8.x branch):${NC}"
echo -e "  git checkout suricata-8.x"
echo -e "  make build"
echo ""
echo -e "${YELLOW}Build specific version (any branch):${NC}"
echo -e "  SURICATA_VERSION=7.0.12 make build"
echo -e "  SURICATA_VERSION=8.0.1 make build"
echo ""
echo -e "${BLUE}Docker Hub tags:${NC}"
echo -e "  • 7.x: latest, 7, 7.0.11 (stable/default)"
echo -e "  • 8.x: 8-latest, 8, 8.0.0 (latest features)"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Update CI/CD pipeline for multi-version builds"
echo -e "  2. Create version-specific documentation"
echo -e "  3. Set up automated tagging strategy"
echo -e "  4. Test both versions thoroughly"
echo -e "  5. Use ./scripts/build-versions.sh for easy multi-version builds"
echo ""

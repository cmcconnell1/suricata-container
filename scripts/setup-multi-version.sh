#!/bin/bash
# =============================================================================
# MULTI-VERSION SETUP SCRIPT FOR SURICATA CONTAINER
# =============================================================================
# This script sets up the repository structure to support both Suricata 8.x
# and 7.x versions using a branching strategy with proper version defaults.
#
# Usage:
#   ./scripts/setup-multi-version.sh
#
# What this script does:
# 1. Creates suricata-7.x branch from current main
# 2. Updates version defaults for 7.x branch
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
SURICATA_8X_VERSION="8.0.0"
SURICATA_7X_VERSION="7.0.11"
ALPINE_8X_VERSION="3.20"  # Required for Rust 1.78.0+
ALPINE_7X_VERSION="3.19"  # Compatible with Rust 1.70.0+

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}SURICATA CONTAINER MULTI-VERSION SETUP${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${GREEN}Setting up repository to support:${NC}"
echo -e "  • Suricata 8.x (${SURICATA_8X_VERSION}) on main branch"
echo -e "  • Suricata 7.x (${SURICATA_7X_VERSION}) on suricata-7.x branch"
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

# Check if suricata-7.x branch already exists
if git show-ref --verify --quiet refs/heads/suricata-7.x; then
    echo -e "${YELLOW}Branch 'suricata-7.x' already exists.${NC}"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -D suricata-7.x
        echo -e "${GREEN}Deleted existing suricata-7.x branch${NC}"
    else
        echo -e "${YELLOW}Skipping branch creation${NC}"
        exit 0
    fi
fi

echo -e "${BLUE}Step 1: Creating suricata-7.x branch${NC}"
git checkout -b suricata-7.x
echo -e "${GREEN}✓ Created and switched to suricata-7.x branch${NC}"

echo -e "${BLUE}Step 2: Updating version defaults for Suricata 7.x${NC}"

# Update Makefile for 7.x defaults
sed -i.bak "s/SURICATA_VERSION ?= ${SURICATA_8X_VERSION}/SURICATA_VERSION ?= ${SURICATA_7X_VERSION}/" Makefile
sed -i.bak "s/ALPINE_VERSION ?= ${ALPINE_8X_VERSION}/ALPINE_VERSION ?= ${ALPINE_7X_VERSION}/" Makefile

# Update Dockerfile for 7.x defaults
sed -i.bak "s/ARG ALPINE_VERSION=${ALPINE_8X_VERSION}/ARG ALPINE_VERSION=${ALPINE_7X_VERSION}/" docker/Dockerfile
sed -i.bak "s/ARG SURICATA_VERSION=${SURICATA_8X_VERSION}/ARG SURICATA_VERSION=${SURICATA_7X_VERSION}/" docker/Dockerfile

# Update Rust version requirement for 7.x (uses older Rust)
sed -i.bak "s/ARG RUST_VERSION=1.78.0/ARG RUST_VERSION=1.70.0/" docker/Dockerfile

# Clean up backup files
rm -f Makefile.bak docker/Dockerfile.bak

echo -e "${GREEN}✓ Updated version defaults:${NC}"
echo -e "  • Suricata: ${SURICATA_7X_VERSION}"
echo -e "  • Alpine: ${ALPINE_7X_VERSION}"
echo -e "  • Rust: 1.70.0"

echo -e "${BLUE}Step 3: Committing changes to suricata-7.x branch${NC}"
git add Makefile docker/Dockerfile
git commit -m "Configure defaults for Suricata 7.x branch

- Set SURICATA_VERSION default to ${SURICATA_7X_VERSION}
- Set ALPINE_VERSION default to ${ALPINE_7X_VERSION}
- Set RUST_VERSION to 1.70.0 for 7.x compatibility
- Maintain compatibility with existing build system"

echo -e "${GREEN}✓ Committed changes to suricata-7.x branch${NC}"

echo -e "${BLUE}Step 4: Switching back to main branch${NC}"
git checkout main
echo -e "${GREEN}✓ Switched back to main branch${NC}"

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}MULTI-VERSION SETUP COMPLETE!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo ""
echo -e "${BLUE}Repository structure:${NC}"
echo -e "  • ${GREEN}main branch${NC}        → Suricata 8.x (${SURICATA_8X_VERSION})"
echo -e "  • ${GREEN}suricata-7.x branch${NC} → Suricata 7.x (${SURICATA_7X_VERSION})"
echo ""
echo -e "${BLUE}Usage examples:${NC}"
echo -e "${YELLOW}Build Suricata 8.x (from main branch):${NC}"
echo -e "  git checkout main"
echo -e "  make build"
echo ""
echo -e "${YELLOW}Build Suricata 7.x (from suricata-7.x branch):${NC}"
echo -e "  git checkout suricata-7.x"
echo -e "  make build"
echo ""
echo -e "${YELLOW}Build specific version (any branch):${NC}"
echo -e "  SURICATA_VERSION=7.0.10 make build"
echo -e "  SURICATA_VERSION=8.0.0 make build"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Update CI/CD pipeline for multi-version builds"
echo -e "  2. Create version-specific documentation"
echo -e "  3. Set up automated tagging strategy"
echo -e "  4. Test both versions thoroughly"
echo ""

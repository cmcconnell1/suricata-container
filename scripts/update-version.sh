#!/bin/bash
# =============================================================================
# VERSION UPDATE SCRIPT FOR SURICATA CONTAINER
# =============================================================================
# This script helps update Suricata versions in the appropriate branch
# and creates proper git tags.
#
# Usage:
#   ./scripts/update-version.sh [OPTIONS]
#
# Options:
#   --version VERSION       New Suricata version (e.g., 7.0.12, 8.0.1)
#   --branch main|suricata-8.x  Target branch (auto-detected from version)
#   --alpine VERSION        Alpine version (optional, auto-selected)
#   --rust VERSION          Rust version (optional, auto-selected)
#   --tag                   Create git tag after update
#   --dry-run               Show what would be changed without doing it
#   --help                  Show this help message
#
# Examples:
#   ./scripts/update-version.sh --version 7.0.12 --tag
#   ./scripts/update-version.sh --version 8.0.1 --tag
#   ./scripts/update-version.sh --version 7.0.12 --alpine 3.19 --dry-run
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
NEW_VERSION=""
TARGET_BRANCH=""
ALPINE_VERSION=""
RUST_VERSION=""
CREATE_TAG=false
DRY_RUN=false

# Version compatibility matrix (updated for new branch structure)
declare -A VERSION_MATRIX
VERSION_MATRIX[7_ALPINE]="3.19"
VERSION_MATRIX[7_RUST]="1.70.0"
VERSION_MATRIX[7_BRANCH]="main"
VERSION_MATRIX[8_ALPINE]="3.20"
VERSION_MATRIX[8_RUST]="1.78.0"
VERSION_MATRIX[8_BRANCH]="suricata-8.x"

# Function to show help
show_help() {
    echo -e "${BOLD}Suricata Version Update Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --version VERSION       New Suricata version (e.g., 7.0.12, 8.0.1)"
    echo "  --branch main|suricata-8.x  Target branch (auto-detected from version)"
    echo "  --alpine VERSION        Alpine version (optional, auto-selected)"
    echo "  --rust VERSION          Rust version (optional, auto-selected)"
    echo "  --tag                   Create git tag after update"
    echo "  --dry-run               Show what would be changed without doing it"
    echo "  --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --version 7.0.12 --tag"
    echo "  $0 --version 8.0.1 --tag"
    echo "  $0 --version 7.0.12 --alpine 3.19 --dry-run"
    echo ""
    echo "Version Compatibility:"
    echo "  Suricata 7.x → Alpine ${VERSION_MATRIX[7_ALPINE]}, Rust ${VERSION_MATRIX[7_RUST]}, Branch: ${VERSION_MATRIX[7_BRANCH]}"
    echo "  Suricata 8.x → Alpine ${VERSION_MATRIX[8_ALPINE]}, Rust ${VERSION_MATRIX[8_RUST]}, Branch: ${VERSION_MATRIX[8_BRANCH]}"
    echo ""
}

# Function to detect version family and set defaults
detect_version_family() {
    local version=$1
    
    if [[ $version =~ ^7\. ]]; then
        echo "7"
    elif [[ $version =~ ^8\. ]]; then
        echo "8"
    else
        echo -e "${RED}Error: Unsupported version family. Only 7.x and 8.x are supported.${NC}"
        exit 1
    fi
}

# Function to update file content
update_file() {
    local file=$1
    local old_pattern=$2
    local new_value=$3
    local description=$4
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}Would update ${file}: ${description}${NC}"
        echo -e "  Pattern: ${old_pattern}"
        echo -e "  New value: ${new_value}"
        return 0
    fi
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File $file does not exist${NC}"
        return 1
    fi
    
    # Create backup
    cp "$file" "${file}.backup"
    
    # Update the file
    if sed -i "s/${old_pattern}/${new_value}/g" "$file"; then
        echo -e "${GREEN}✓ Updated ${file}: ${description}${NC}"
        rm -f "${file}.backup"
        return 0
    else
        echo -e "${RED}✗ Failed to update ${file}${NC}"
        mv "${file}.backup" "$file"
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            NEW_VERSION="$2"
            shift 2
            ;;
        --branch)
            TARGET_BRANCH="$2"
            shift 2
            ;;
        --alpine)
            ALPINE_VERSION="$2"
            shift 2
            ;;
        --rust)
            RUST_VERSION="$2"
            shift 2
            ;;
        --tag)
            CREATE_TAG=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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

# Validate required parameters
if [ -z "$NEW_VERSION" ]; then
    echo -e "${RED}Error: --version is required${NC}"
    show_help
    exit 1
fi

# Detect version family and set defaults
VERSION_FAMILY=$(detect_version_family "$NEW_VERSION")

# Set defaults based on version family
if [ -z "$TARGET_BRANCH" ]; then
    TARGET_BRANCH=${VERSION_MATRIX[${VERSION_FAMILY}_BRANCH]}
fi

if [ -z "$ALPINE_VERSION" ]; then
    ALPINE_VERSION=${VERSION_MATRIX[${VERSION_FAMILY}_ALPINE]}
fi

if [ -z "$RUST_VERSION" ]; then
    RUST_VERSION=${VERSION_MATRIX[${VERSION_FAMILY}_RUST]}
fi

# Validate branch
if [[ ! "$TARGET_BRANCH" =~ ^(main|suricata-8.x)$ ]]; then
    echo -e "${RED}Error: Invalid branch. Must be 'main' or 'suricata-8.x'${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if target branch exists
if ! git show-ref --verify --quiet refs/heads/${TARGET_BRANCH}; then
    echo -e "${RED}Error: Branch ${TARGET_BRANCH} does not exist${NC}"
    exit 1
fi

# Store current branch
ORIGINAL_BRANCH=$(git branch --show-current)

echo -e "${BOLD}Suricata Version Update${NC}"
echo -e "New Version: ${NEW_VERSION}"
echo -e "Target Branch: ${TARGET_BRANCH}"
echo -e "Alpine Version: ${ALPINE_VERSION}"
echo -e "Rust Version: ${RUST_VERSION}"
echo -e "Create Tag: ${CREATE_TAG}"
echo -e "Dry Run: ${DRY_RUN}"
echo ""

# Switch to target branch
if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Switching to branch: ${TARGET_BRANCH}${NC}"
    git checkout ${TARGET_BRANCH}
fi

# Get current versions for replacement patterns
if [ "$DRY_RUN" = false ]; then
    CURRENT_SURICATA=$(grep "SURICATA_VERSION ?=" Makefile | sed 's/.*= //')
    CURRENT_ALPINE=$(grep "ALPINE_VERSION ?=" Makefile | sed 's/.*= //')
    CURRENT_RUST=$(grep "ARG RUST_VERSION=" docker/Dockerfile | sed 's/.*=//')
else
    # For dry run, use placeholder values
    CURRENT_SURICATA="CURRENT_VERSION"
    CURRENT_ALPINE="CURRENT_ALPINE"
    CURRENT_RUST="CURRENT_RUST"
fi

echo -e "${BLUE}Updating configuration files...${NC}"

# Update Makefile
update_file "Makefile" \
    "SURICATA_VERSION ?= ${CURRENT_SURICATA}" \
    "SURICATA_VERSION ?= ${NEW_VERSION}" \
    "Suricata version in Makefile"

update_file "Makefile" \
    "ALPINE_VERSION ?= ${CURRENT_ALPINE}" \
    "ALPINE_VERSION ?= ${ALPINE_VERSION}" \
    "Alpine version in Makefile"

# Update Dockerfile
update_file "docker/Dockerfile" \
    "ARG ALPINE_VERSION=${CURRENT_ALPINE}" \
    "ARG ALPINE_VERSION=${ALPINE_VERSION}" \
    "Alpine version in Dockerfile"

update_file "docker/Dockerfile" \
    "ARG SURICATA_VERSION=${CURRENT_SURICATA}" \
    "ARG SURICATA_VERSION=${NEW_VERSION}" \
    "Suricata version in Dockerfile"

update_file "docker/Dockerfile" \
    "ARG RUST_VERSION=${CURRENT_RUST}" \
    "ARG RUST_VERSION=${RUST_VERSION}" \
    "Rust version in Dockerfile"

# Commit changes
if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Committing changes...${NC}"
    git add Makefile docker/Dockerfile
    git commit -m "Update Suricata to ${NEW_VERSION}

- Suricata: ${NEW_VERSION}
- Alpine: ${ALPINE_VERSION}
- Rust: ${RUST_VERSION}
- Branch: ${TARGET_BRANCH}"
    
    echo -e "${GREEN}✓ Changes committed${NC}"
    
    # Create tag if requested
    if [ "$CREATE_TAG" = true ]; then
        TAG_NAME="v${NEW_VERSION}"
        echo -e "${YELLOW}Creating tag: ${TAG_NAME}${NC}"
        git tag -a "${TAG_NAME}" -m "Release Suricata ${NEW_VERSION}"
        echo -e "${GREEN}✓ Tag ${TAG_NAME} created${NC}"
    fi
fi

# Restore original branch
if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Restoring original branch: ${ORIGINAL_BRANCH}${NC}"
    git checkout ${ORIGINAL_BRANCH}
fi

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${BOLD}${GREEN}Version Update Complete!${NC}"
echo -e "${GREEN}==============================================================================${NC}"

if [ "$DRY_RUN" = false ]; then
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Test the new version: git checkout ${TARGET_BRANCH} && make build && make test"
    echo -e "2. Build both versions: ./scripts/build-versions.sh --version both --test"
    if [ "$CREATE_TAG" = true ]; then
        echo -e "3. Push tag: git push origin v${NEW_VERSION}"
    fi
    echo -e "4. Update documentation if needed"
else
    echo -e "${YELLOW}This was a dry run. Use without --dry-run to apply changes.${NC}"
fi

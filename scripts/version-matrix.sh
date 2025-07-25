#!/bin/bash
# =============================================================================
# VERSION COMPATIBILITY MATRIX FOR SURICATA CONTAINER
# =============================================================================
# This script shows the version relationships and compatibility matrix
# for different Suricata versions and their dependencies.
#
# Usage:
#   ./scripts/version-matrix.sh [OPTIONS]
#
# Options:
#   --show-matrix       Show compatibility matrix
#   --validate VERSION  Validate a specific version combination
#   --recommend VERSION Recommend compatible versions for Suricata version
#   --help             Show this help message
#
# Examples:
#   ./scripts/version-matrix.sh --show-matrix
#   ./scripts/version-matrix.sh --validate 7.0.11
#   ./scripts/version-matrix.sh --recommend 8.0.0
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Version compatibility matrix (updated for new branch structure)
declare -A VERSION_MATRIX

# Suricata 7.x compatibility (main branch - default)
VERSION_MATRIX[7_MIN_ALPINE]="3.18"
VERSION_MATRIX[7_RECOMMENDED_ALPINE]="3.19"
VERSION_MATRIX[7_MIN_RUST]="1.70.0"
VERSION_MATRIX[7_RECOMMENDED_RUST]="1.70.0"
VERSION_MATRIX[7_MIN_PYTHON]="3.10"
VERSION_MATRIX[7_RECOMMENDED_PYTHON]="3.11"
VERSION_MATRIX[7_BRANCH]="main"
VERSION_MATRIX[7_FEATURES]="JA3 fingerprinting, Stable TLS analysis, Proven reliability"

# Suricata 8.x compatibility (suricata-8.x branch)
VERSION_MATRIX[8_MIN_ALPINE]="3.20"
VERSION_MATRIX[8_RECOMMENDED_ALPINE]="3.20"
VERSION_MATRIX[8_MIN_RUST]="1.78.0"
VERSION_MATRIX[8_RECOMMENDED_RUST]="1.78.0"
VERSION_MATRIX[8_MIN_PYTHON]="3.11"
VERSION_MATRIX[8_RECOMMENDED_PYTHON]="3.12"
VERSION_MATRIX[8_BRANCH]="suricata-8.x"
VERSION_MATRIX[8_FEATURES]="HTTP/2 decompression, JA4 fingerprinting, Enhanced TLS analysis"

# Alpine -> Python mapping
declare -A ALPINE_PYTHON
ALPINE_PYTHON[3.18]="3.10"
ALPINE_PYTHON[3.19]="3.11"
ALPINE_PYTHON[3.20]="3.12"
ALPINE_PYTHON[3.21]="3.12"

# Function to show help
show_help() {
    echo -e "${BOLD}Suricata Version Compatibility Matrix${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --show-matrix       Show compatibility matrix"
    echo "  --validate VERSION  Validate a specific version combination"
    echo "  --recommend VERSION Recommend compatible versions for Suricata version"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --show-matrix"
    echo "  $0 --validate 7.0.11"
    echo "  $0 --recommend 8.0.0"
    echo ""
}

# Function to show compatibility matrix
show_matrix() {
    echo -e "${BOLD}Suricata Container Version Compatibility Matrix${NC}"
    echo ""
    
    echo -e "${BLUE}Suricata 7.x (Stable/Default)${NC}"
    echo "├── Branch: ${VERSION_MATRIX[7_BRANCH]}"
    echo "├── Alpine: ${VERSION_MATRIX[7_MIN_ALPINE]}+ (recommended: ${VERSION_MATRIX[7_RECOMMENDED_ALPINE]})"
    echo "├── Rust: ${VERSION_MATRIX[7_MIN_RUST]}+ (recommended: ${VERSION_MATRIX[7_RECOMMENDED_RUST]})"
    echo "├── Python: ${VERSION_MATRIX[7_MIN_PYTHON]}+ (recommended: ${VERSION_MATRIX[7_RECOMMENDED_PYTHON]})"
    echo "└── Features: ${VERSION_MATRIX[7_FEATURES]}"
    echo ""
    
    echo -e "${BLUE}Suricata 8.x (Latest Features)${NC}"
    echo "├── Branch: ${VERSION_MATRIX[8_BRANCH]}"
    echo "├── Alpine: ${VERSION_MATRIX[8_MIN_ALPINE]}+ (recommended: ${VERSION_MATRIX[8_RECOMMENDED_ALPINE]})"
    echo "├── Rust: ${VERSION_MATRIX[8_MIN_RUST]}+ (recommended: ${VERSION_MATRIX[8_RECOMMENDED_RUST]})"
    echo "├── Python: ${VERSION_MATRIX[8_MIN_PYTHON]}+ (recommended: ${VERSION_MATRIX[8_RECOMMENDED_PYTHON]})"
    echo "└── Features: ${VERSION_MATRIX[8_FEATURES]}"
    echo ""
    
    echo -e "${BLUE}Alpine Linux → Python Version Mapping${NC}"
    for alpine_ver in $(echo "${!ALPINE_PYTHON[@]}" | tr ' ' '\n' | sort -V); do
        python_ver=${ALPINE_PYTHON[$alpine_ver]}
        echo "├── Alpine ${alpine_ver} → Python ${python_ver}"
    done
    echo ""
    
    echo -e "${BLUE}Docker Build Examples${NC}"
    echo ""
    echo -e "${YELLOW}Suricata 7.x (main branch defaults - stable/default):${NC}"
    echo "docker build --build-arg SURICATA_VERSION=7.0.11 \\"
    echo "             --build-arg ALPINE_VERSION=3.19 \\"
    echo "             --build-arg RUST_VERSION=1.70.0 \\"
    echo "             --build-arg PYTHON_VERSION=3.11 \\"
    echo "             -f docker/Dockerfile -t suricata:7.0.11 ."
    echo ""
    echo -e "${YELLOW}Suricata 8.x (suricata-8.x branch defaults):${NC}"
    echo "docker build --build-arg SURICATA_VERSION=8.0.0 \\"
    echo "             --build-arg ALPINE_VERSION=3.20 \\"
    echo "             --build-arg RUST_VERSION=1.78.0 \\"
    echo "             --build-arg PYTHON_VERSION=3.12 \\"
    echo "             -f docker/Dockerfile -t suricata:8.0.0 ."
    echo ""
}

# Function to validate version combination
validate_version() {
    local suricata_version=$1
    local major_version=${suricata_version%%.*}
    
    echo -e "${BOLD}Validating Suricata ${suricata_version}${NC}"
    echo ""
    
    if [ "$major_version" != "7" ] && [ "$major_version" != "8" ]; then
        echo -e "${RED}ERROR: Unsupported Suricata major version: ${major_version}${NC}"
        echo "Supported versions: 7.x, 8.x"
        return 1
    fi
    
    local min_alpine=${VERSION_MATRIX[${major_version}_MIN_ALPINE]}
    local rec_alpine=${VERSION_MATRIX[${major_version}_RECOMMENDED_ALPINE]}
    local min_rust=${VERSION_MATRIX[${major_version}_MIN_RUST]}
    local rec_rust=${VERSION_MATRIX[${major_version}_RECOMMENDED_RUST]}
    local min_python=${VERSION_MATRIX[${major_version}_MIN_PYTHON]}
    local rec_python=${VERSION_MATRIX[${major_version}_RECOMMENDED_PYTHON]}
    local branch=${VERSION_MATRIX[${major_version}_BRANCH]}
    
    echo -e "${GREEN}Validation Results:${NC}"
    echo "├── Suricata Version: ${suricata_version} (${major_version}.x family)"
    echo "├── Target Branch: ${branch}"
    echo "├── Alpine Linux: ${min_alpine}+ required, ${rec_alpine} recommended"
    echo "├── Rust Compiler: ${min_rust}+ required, ${rec_rust} recommended"
    echo "├── Python: ${min_python}+ required, ${rec_python} recommended"
    echo "└── Status: Valid configuration"
    echo ""
    
    echo -e "${BLUE}Build Command:${NC}"
    echo "git checkout ${branch}"
    echo "docker build --build-arg SURICATA_VERSION=${suricata_version} \\"
    echo "             --build-arg ALPINE_VERSION=${rec_alpine} \\"
    echo "             --build-arg RUST_VERSION=${rec_rust} \\"
    echo "             --build-arg PYTHON_VERSION=${rec_python} \\"
    echo "             -f docker/Dockerfile -t suricata:${suricata_version} ."
    echo ""
}

# Function to recommend versions
recommend_versions() {
    local suricata_version=$1
    local major_version=${suricata_version%%.*}
    
    echo -e "${BOLD}Version Recommendations for Suricata ${suricata_version}${NC}"
    echo ""
    
    if [ "$major_version" != "7" ] && [ "$major_version" != "8" ]; then
        echo -e "${RED}ERROR: Unsupported Suricata major version: ${major_version}${NC}"
        return 1
    fi
    
    local rec_alpine=${VERSION_MATRIX[${major_version}_RECOMMENDED_ALPINE]}
    local rec_rust=${VERSION_MATRIX[${major_version}_RECOMMENDED_RUST]}
    local rec_python=${VERSION_MATRIX[${major_version}_RECOMMENDED_PYTHON]}
    local branch=${VERSION_MATRIX[${major_version}_BRANCH]}
    local features=${VERSION_MATRIX[${major_version}_FEATURES]}
    
    echo -e "${GREEN}Recommended Configuration:${NC}"
    echo "├── Git Branch: ${branch}"
    echo "├── Alpine Linux: ${rec_alpine}"
    echo "├── Rust Compiler: ${rec_rust}"
    echo "├── Python: ${rec_python}"
    echo "└── Key Features: ${features}"
    echo ""
    
    echo -e "${BLUE}Makefile Variables:${NC}"
    echo "export SURICATA_VERSION=${suricata_version}"
    echo "export ALPINE_VERSION=${rec_alpine}"
    echo "make build"
    echo ""
    
    echo -e "${BLUE}Direct Docker Build:${NC}"
    echo "docker build \\"
    echo "  --build-arg SURICATA_VERSION=${suricata_version} \\"
    echo "  --build-arg ALPINE_VERSION=${rec_alpine} \\"
    echo "  --build-arg RUST_VERSION=${rec_rust} \\"
    echo "  --build-arg PYTHON_VERSION=${rec_python} \\"
    echo "  -f docker/Dockerfile -t suricata:${suricata_version} ."
    echo ""
}

# Parse command line arguments
case "${1:-}" in
    --show-matrix)
        show_matrix
        ;;
    --validate)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}ERROR: --validate requires a Suricata version${NC}"
            show_help
            exit 1
        fi
        validate_version "$2"
        ;;
    --recommend)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}ERROR: --recommend requires a Suricata version${NC}"
            show_help
            exit 1
        fi
        recommend_versions "$2"
        ;;
    --help|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac

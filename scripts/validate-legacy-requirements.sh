#!/bin/bash
# =============================================================================
# LEGACY REQUIREMENTS VALIDATION SCRIPT
# =============================================================================
# This script validates that all legacy requirements from cisappdev/albert_build_scripts
# are properly included in our Oracle Linux refactored build.
#
# Validates:
# - All required packages from legacy Ansible playbooks
# - Napatech package availability and installation
# - Hyperscan compilation requirements
# - FPM RPM generation capabilities
# - Configuration file completeness
# - Build variant support (AF_PACKET vs Napatech)
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LEGACY_PATH="${PROJECT_ROOT}/../cisappdev/albert_build_scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Legacy package requirements from build_suricata_ol9.yml
declare -a LEGACY_HYPERSCAN_DEPS=(
    "boost-devel"
    "cmake"
    "libstdc++"
    "libstdc++-devel"
    "libpcap-devel"
    "pcre-devel"
    "gcc"
    "gcc-c++"
    "ragel"
    "libsqlite3x-devel"
)

declare -a LEGACY_SURICATA_DEPS=(
    "autoconf"
    "automake"
    "cargo"
    "clang"
    "file-devel"
    "jansson-devel"
    "libcap-ng-devel"
    "libmaxminddb"
    "libnet-devel"
    "libtool"
    "libyaml-devel"
    "llvm"
    "lz4"
    "lz4-devel"
    "nspr-devel"
    "nss-devel"
    "numactl-devel"
    "pcre-devel"
    "python-devel"
    "python-pyyaml"
    "zlib-devel"
)

declare -a LEGACY_NAPATECH_DEPS=(
    "wget"
    "numactl"
    "numactl-devel"
    "lzo-devel"
    "ncurses-devel"
    "ncurses-compat-libs"
    "rpmdevtools"
    "gnutls-devel"
    "openssl-devel"
    "libxslt"
    "libxslt-devel"
    "kernel-uek-devel"
)

declare -a LEGACY_RUNTIME_DEPS=(
    "libmaxminddb"
    "libnet"
    "libyaml"
    "libpcap"
    "libcap-ng"
    "jansson"
    "lz4"
    "file-libs"
    "nspr"
    "nss"
    "nss-softokn"
    "numactl-libs"
    "pcre"
    "zlib"
)

# Validate Oracle Linux Dockerfile contains all legacy packages
validate_dockerfile_packages() {
    log_info "Validating Oracle Linux Dockerfile contains all legacy packages..."
    
    local dockerfile="${PROJECT_ROOT}/docker/Dockerfile.oracle-linux"
    local missing_packages=()
    local total_packages=0
    local found_packages=0
    
    if [[ ! -f "$dockerfile" ]]; then
        log_error "Oracle Linux Dockerfile not found: $dockerfile"
        return 1
    fi
    
    # Check Hyperscan dependencies
    log_info "Checking Hyperscan dependencies..."
    for package in "${LEGACY_HYPERSCAN_DEPS[@]}"; do
        ((total_packages++))
        if grep -q "$package" "$dockerfile"; then
            ((found_packages++))
            log_success "Found Hyperscan dependency: $package"
        else
            missing_packages+=("$package (Hyperscan)")
            log_warning "Missing Hyperscan dependency: $package"
        fi
    done
    
    # Check Suricata dependencies
    log_info "Checking Suricata dependencies..."
    for package in "${LEGACY_SURICATA_DEPS[@]}"; do
        ((total_packages++))
        if grep -q "$package" "$dockerfile"; then
            ((found_packages++))
            log_success "Found Suricata dependency: $package"
        else
            missing_packages+=("$package (Suricata)")
            log_warning "Missing Suricata dependency: $package"
        fi
    done
    
    # Check Napatech dependencies
    log_info "Checking Napatech dependencies..."
    for package in "${LEGACY_NAPATECH_DEPS[@]}"; do
        ((total_packages++))
        if grep -q "$package" "$dockerfile"; then
            ((found_packages++))
            log_success "Found Napatech dependency: $package"
        else
            missing_packages+=("$package (Napatech)")
            log_warning "Missing Napatech dependency: $package"
        fi
    done
    
    # Check runtime dependencies
    log_info "Checking runtime dependencies..."
    for package in "${LEGACY_RUNTIME_DEPS[@]}"; do
        ((total_packages++))
        if grep -q "$package" "$dockerfile"; then
            ((found_packages++))
            log_success "Found runtime dependency: $package"
        else
            missing_packages+=("$package (Runtime)")
            log_warning "Missing runtime dependency: $package"
        fi
    done
    
    # Summary
    log_info "Package validation summary:"
    log_info "  Total legacy packages: $total_packages"
    log_info "  Found in Dockerfile: $found_packages"
    log_info "  Missing packages: ${#missing_packages[@]}"
    
    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_success "All legacy packages are included in the Dockerfile"
        return 0
    else
        log_error "Missing packages detected:"
        for package in "${missing_packages[@]}"; do
            log_error "  - $package"
        done
        return 1
    fi
}

# Validate Napatech configuration
validate_napatech_config() {
    log_info "Validating Napatech configuration..."
    
    local dockerfile="${PROJECT_ROOT}/docker/Dockerfile.oracle-linux"
    local napatech_config="${PROJECT_ROOT}/docker/config/suricata-napatech.yaml"
    
    # Check Napatech download URL
    if grep -q "your-package-server.example.com/napatech" "$dockerfile"; then
        log_success "Napatech download URL found in Dockerfile"
    else
        log_error "Napatech download URL missing from Dockerfile"
        return 1
    fi
    
    # Check Napatech configuration file
    if [[ -f "$napatech_config" ]]; then
        log_success "Napatech configuration file exists"
        
        # Check for key Napatech settings
        if grep -q "napatech:" "$napatech_config"; then
            log_success "Napatech configuration section found"
        else
            log_warning "Napatech configuration section missing"
        fi
        
        if grep -q "use-all-streams:" "$napatech_config"; then
            log_success "Napatech stream configuration found"
        else
            log_warning "Napatech stream configuration missing"
        fi
    else
        log_error "Napatech configuration file missing: $napatech_config"
        return 1
    fi
    
    # Check Napatech build variant support
    if grep -q "BUILD_VARIANT.*napatech" "$dockerfile"; then
        log_success "Napatech build variant support found"
    else
        log_error "Napatech build variant support missing"
        return 1
    fi
    
    return 0
}

# Validate legacy build configuration replication
validate_legacy_build_config() {
    log_info "Validating legacy build configuration replication..."
    
    local dockerfile="${PROJECT_ROOT}/docker/Dockerfile.oracle-linux"
    
    # Check gcc-toolset-13 usage (legacy requirement)
    if grep -q "gcc-toolset-13" "$dockerfile"; then
        log_success "gcc-toolset-13 usage found (legacy requirement)"
    else
        log_error "gcc-toolset-13 usage missing (required by legacy builds)"
        return 1
    fi
    
    # Check Hyperscan version 5.4.0 (legacy requirement)
    if grep -q "HYPERSCAN_VERSION.*5.4.0" "$dockerfile"; then
        log_success "Hyperscan version 5.4.0 found (legacy requirement)"
    else
        log_warning "Hyperscan version 5.4.0 not explicitly set"
    fi
    
    # Check FPM RPM generation
    if grep -q "fpm.*-s dir -t rpm" "$dockerfile"; then
        log_success "FPM RPM generation found"
    else
        log_error "FPM RPM generation missing"
        return 1
    fi
    
    # Check legacy configure flags
    if grep -q "\-\-disable-gccmarch-native" "$dockerfile"; then
        log_success "Legacy configure flag --disable-gccmarch-native found"
    else
        log_error "Legacy configure flag --disable-gccmarch-native missing"
        return 1
    fi
    
    if grep -q "\-\-enable-gccprotect" "$dockerfile"; then
        log_success "Legacy configure flag --enable-gccprotect found"
    else
        log_error "Legacy configure flag --enable-gccprotect missing"
        return 1
    fi
    
    return 0
}

# Validate file structure
validate_file_structure() {
    log_info "Validating file structure..."
    
    local required_files=(
        "docker/Dockerfile.oracle-linux"
        "docker/config/oracle-optional-ol9.repo"
        "docker/config/suricata-napatech.yaml"
        "scripts/entrypoint-oracle.sh"
        "scripts/validate-legacy-requirements.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        local filepath="${PROJECT_ROOT}/${file}"
        if [[ -f "$filepath" ]]; then
            log_success "Required file exists: $file"
        else
            missing_files+=("$file")
            log_error "Required file missing: $file"
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        log_success "All required files are present"
        return 0
    else
        log_error "Missing required files: ${#missing_files[@]}"
        return 1
    fi
}

# Main validation function
main() {
    log_info "Starting legacy requirements validation..."
    log_info "Project root: $PROJECT_ROOT"
    
    local exit_code=0
    
    # Run all validations
    validate_file_structure || exit_code=1
    validate_dockerfile_packages || exit_code=1
    validate_napatech_config || exit_code=1
    validate_legacy_build_config || exit_code=1
    
    # Final summary
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "All legacy requirements validation passed!"
        log_info "The Oracle Linux refactoring includes all necessary components from legacy builds"
    else
        log_error "Legacy requirements validation failed!"
        log_info "Please address the issues above before proceeding with the build"
    fi
    
    exit $exit_code
}

# Execute main function
main "$@"

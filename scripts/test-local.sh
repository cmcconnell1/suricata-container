#!/bin/bash
# =============================================================================
# LOCAL TESTING SCRIPT FOR LEGACY REFACTORING
# =============================================================================
# This script implements best practices for local testing before commits.
# It validates both Alpine and Oracle Linux builds with comprehensive testing.
#
# Usage:
#   ./scripts/test-local.sh [OPTIONS]
#
# Options:
#   --alpine-only     Test only Alpine builds
#   --oracle-only     Test only Oracle Linux builds
#   --quick          Skip long-running tests
#   --verbose        Enable verbose output
#   --help           Show this help message
#
# Best Practices Implemented:
#   - Local testing before commits
#   - Multi-variant validation
#   - Security scanning
#   - Performance benchmarking
#   - Documentation validation
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/test-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Test configuration
TEST_ALPINE=true
TEST_ORACLE=true
QUICK_MODE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${LOG_DIR}/test_${TIMESTAMP}.log"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_DIR}/test_${TIMESTAMP}.log"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_DIR}/test_${TIMESTAMP}.log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_DIR}/test_${TIMESTAMP}.log"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --alpine-only)
                TEST_ALPINE=true
                TEST_ORACLE=false
                shift
                ;;
            --oracle-only)
                TEST_ALPINE=false
                TEST_ORACLE=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Local Testing Script for Legacy Refactoring

Usage: $0 [OPTIONS]

Options:
  --alpine-only     Test only Alpine builds
  --oracle-only     Test only Oracle Linux builds
  --quick          Skip long-running tests
  --verbose        Enable verbose output
  --help           Show this help message

Examples:
  $0                    # Test all variants
  $0 --alpine-only      # Test only Alpine builds
  $0 --oracle-only      # Test only Oracle Linux builds
  $0 --quick --verbose  # Quick test with verbose output

EOF
}

# Setup test environment
setup_test_env() {
    log_info "Setting up test environment..."
    
    # Create log directory
    mkdir -p "${LOG_DIR}"
    
    # Change to project root
    cd "${PROJECT_ROOT}"
    
    # Verify we're in the correct branch
    local current_branch=$(git branch --show-current)
    if [[ "${current_branch}" != "legacy-refactor" ]]; then
        log_warning "Not on legacy-refactor branch (current: ${current_branch})"
        log_info "Switching to legacy-refactor branch..."
        git checkout legacy-refactor || {
            log_error "Failed to switch to legacy-refactor branch"
            exit 1
        }
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_warning "Uncommitted changes detected"
        log_info "Stashing changes for testing..."
        git stash push -m "test-local.sh auto-stash ${TIMESTAMP}"
    fi
    
    log_success "Test environment ready"
}

# Validate documentation
validate_documentation() {
    log_info "Validating documentation..."
    
    local errors=0
    
    # Check for emoticons in documentation (best practice: no emoticons)
    log_info "Checking for emoticons in documentation..."
    local emoticon_files=$(find . -name "*.md" -exec grep -l ":[a-z_]*:" {} \; 2>/dev/null || true)
    if [[ -n "${emoticon_files}" ]]; then
        log_error "Emoticons found in documentation files:"
        echo "${emoticon_files}" | while read -r file; do
            log_error "  - ${file}"
        done
        ((errors++))
    else
        log_success "No emoticons found in documentation"
    fi
    
    # Check for required documentation files
    local required_docs=("README.md" "CHANGELOG.md" "PROJECT_STATUS.md")
    for doc in "${required_docs[@]}"; do
        if [[ ! -f "${doc}" ]]; then
            log_error "Missing required documentation: ${doc}"
            ((errors++))
        else
            log_success "Found required documentation: ${doc}"
        fi
    done
    
    # Validate Dockerfile best practices
    log_info "Validating Dockerfile best practices..."
    local dockerfiles=("docker/Dockerfile" "docker/Dockerfile.oracle-linux")
    for dockerfile in "${dockerfiles[@]}"; do
        if [[ -f "${dockerfile}" ]]; then
            # Check for multi-stage builds
            if grep -q "FROM.*AS" "${dockerfile}"; then
                log_success "${dockerfile}: Uses multi-stage build"
            else
                log_warning "${dockerfile}: Consider using multi-stage build"
            fi
            
            # Check for non-root user
            if grep -q "USER" "${dockerfile}"; then
                log_success "${dockerfile}: Sets non-root user"
            else
                log_warning "${dockerfile}: Consider adding non-root user"
            fi
            
            # Check for HEALTHCHECK
            if grep -q "HEALTHCHECK" "${dockerfile}"; then
                log_success "${dockerfile}: Includes health check"
            else
                log_warning "${dockerfile}: Consider adding health check"
            fi
        fi
    done
    
    if [[ ${errors} -eq 0 ]]; then
        log_success "Documentation validation passed"
        return 0
    else
        log_error "Documentation validation failed with ${errors} errors"
        return 1
    fi
}

# Test Alpine builds
test_alpine_builds() {
    if [[ "${TEST_ALPINE}" != "true" ]]; then
        return 0
    fi
    
    log_info "Testing Alpine Linux builds..."
    
    # Build Alpine image
    log_info "Building Alpine Suricata container..."
    if make build 2>&1 | tee "${LOG_DIR}/alpine_build_${TIMESTAMP}.log"; then
        log_success "Alpine build completed successfully"
    else
        log_error "Alpine build failed"
        return 1
    fi
    
    # Test Alpine image
    log_info "Testing Alpine Suricata container..."
    if make test 2>&1 | tee "${LOG_DIR}/alpine_test_${TIMESTAMP}.log"; then
        log_success "Alpine test completed successfully"
    else
        log_error "Alpine test failed"
        return 1
    fi
    
    # Security scan (if available)
    if command -v trivy >/dev/null 2>&1; then
        log_info "Running security scan on Alpine image..."
        trivy image suricata:7.0.11 --exit-code 1 --severity HIGH,CRITICAL 2>&1 | tee "${LOG_DIR}/alpine_security_${TIMESTAMP}.log" || {
            log_warning "Security vulnerabilities found in Alpine image"
        }
    else
        log_warning "Trivy not available, skipping security scan"
    fi
    
    log_success "Alpine testing completed"
}

# Test Oracle Linux builds
test_oracle_builds() {
    if [[ "${TEST_ORACLE}" != "true" ]]; then
        return 0
    fi
    
    log_info "Testing Oracle Linux builds..."
    
    # Test AF_PACKET variant
    log_info "Building Oracle Linux AF_PACKET variant..."
    if make build-oracle 2>&1 | tee "${LOG_DIR}/oracle_afpacket_build_${TIMESTAMP}.log"; then
        log_success "Oracle Linux AF_PACKET build completed successfully"
    else
        log_error "Oracle Linux AF_PACKET build failed"
        return 1
    fi
    
    # Test Oracle Linux image
    log_info "Testing Oracle Linux AF_PACKET container..."
    if make test-oracle 2>&1 | tee "${LOG_DIR}/oracle_afpacket_test_${TIMESTAMP}.log"; then
        log_success "Oracle Linux AF_PACKET test completed successfully"
    else
        log_error "Oracle Linux AF_PACKET test failed"
        return 1
    fi
    
    # Test Napatech variant (if not quick mode)
    if [[ "${QUICK_MODE}" != "true" ]]; then
        log_info "Building Oracle Linux Napatech variant..."
        if BUILD_VARIANT=napatech make build-oracle 2>&1 | tee "${LOG_DIR}/oracle_napatech_build_${TIMESTAMP}.log"; then
            log_success "Oracle Linux Napatech build completed successfully"
        else
            log_warning "Oracle Linux Napatech build failed (expected if Napatech packages not available)"
        fi
    fi
    
    log_success "Oracle Linux testing completed"
}

# Performance benchmarking
run_performance_tests() {
    if [[ "${QUICK_MODE}" == "true" ]]; then
        log_info "Skipping performance tests (quick mode)"
        return 0
    fi
    
    log_info "Running performance benchmarks..."
    
    # Container startup time
    log_info "Measuring container startup time..."
    local start_time=$(date +%s%N)
    docker run --rm suricata:7.0.11 suricata --version >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local startup_time=$(( (end_time - start_time) / 1000000 ))
    log_info "Alpine container startup time: ${startup_time}ms"
    
    # Image size comparison
    log_info "Comparing image sizes..."
    docker images | grep suricata | tee "${LOG_DIR}/image_sizes_${TIMESTAMP}.log"
    
    log_success "Performance benchmarking completed"
}

# Generate test report
generate_report() {
    local report_file="${LOG_DIR}/test_report_${TIMESTAMP}.md"
    
    cat > "${report_file}" << EOF
# Local Test Report

**Date**: $(date)
**Branch**: $(git branch --show-current)
**Commit**: $(git rev-parse --short HEAD)

## Test Configuration
- Alpine Testing: ${TEST_ALPINE}
- Oracle Linux Testing: ${TEST_ORACLE}
- Quick Mode: ${QUICK_MODE}
- Verbose Mode: ${VERBOSE}

## Test Results

### Documentation Validation
$(grep -E "\[(SUCCESS|ERROR|WARNING)\].*documentation" "${LOG_DIR}/test_${TIMESTAMP}.log" || echo "No documentation validation logs found")

### Build Results
$(grep -E "\[(SUCCESS|ERROR)\].*build" "${LOG_DIR}/test_${TIMESTAMP}.log" || echo "No build logs found")

### Test Results
$(grep -E "\[(SUCCESS|ERROR)\].*test" "${LOG_DIR}/test_${TIMESTAMP}.log" || echo "No test logs found")

## Log Files
- Main log: test_${TIMESTAMP}.log
- Alpine build: alpine_build_${TIMESTAMP}.log
- Alpine test: alpine_test_${TIMESTAMP}.log
- Oracle build: oracle_afpacket_build_${TIMESTAMP}.log
- Oracle test: oracle_afpacket_test_${TIMESTAMP}.log

## Next Steps
1. Review any errors or warnings above
2. Fix issues before committing
3. Run full test suite if quick mode was used
4. Update documentation if needed

EOF

    log_success "Test report generated: ${report_file}"
}

# Main execution
main() {
    log_info "Starting local testing for legacy refactoring..."
    log_info "Timestamp: ${TIMESTAMP}"
    
    parse_args "$@"
    setup_test_env
    
    local exit_code=0
    
    # Run validation and tests
    validate_documentation || exit_code=1
    test_alpine_builds || exit_code=1
    test_oracle_builds || exit_code=1
    run_performance_tests || exit_code=1
    
    # Generate report
    generate_report
    
    if [[ ${exit_code} -eq 0 ]]; then
        log_success "All tests passed! Ready for commit."
    else
        log_error "Some tests failed. Please review and fix issues before committing."
    fi
    
    log_info "Test logs available in: ${LOG_DIR}"
    
    exit ${exit_code}
}

# Execute main function with all arguments
main "$@"

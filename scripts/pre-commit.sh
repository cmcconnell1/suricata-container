#!/bin/bash
# =============================================================================
# PRE-COMMIT VALIDATION SCRIPT - BEST PRACTICES ENFORCEMENT
# =============================================================================
# This script enforces best practices before allowing commits:
# - Code quality checks
# - Security validation
# - Documentation standards
# - Container best practices
# - No emoticons in documentation
# - Proper file permissions
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EXIT_CODE=0

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
    EXIT_CODE=1
}

# Check for emoticons in documentation (best practice violation)
check_emoticons() {
    log_info "Checking for emoticons in documentation..."
    
    local emoticon_files=()
    while IFS= read -r -d '' file; do
        # Look for GitHub-style emoticons like :smile: :warning: etc.
        # Exclude common patterns like time stamps, URLs, and technical notation
        if grep -E ":[a-z_]+:" "$file" | grep -v -E "(https?:|ssh:|arn:|[0-9]+:[0-9]+|aa:bb:cc)" >/dev/null 2>&1; then
            emoticon_files+=("$file")
        fi
    done < <(find "${PROJECT_ROOT}" -name "*.md" -print0 2>/dev/null)
    
    if [[ ${#emoticon_files[@]} -gt 0 ]]; then
        log_error "Emoticons found in documentation files (violates best practices):"
        for file in "${emoticon_files[@]}"; do
            log_error "  - ${file#${PROJECT_ROOT}/}"
            # Show specific lines with emoticons
            grep -nE ":[a-z_]+:" "$file" | grep -v -E "(https?:|ssh:|arn:|[0-9]+:[0-9]+|aa:bb:cc)" | head -3 | while read -r line; do
                log_error "    Line: $line"
            done
        done
        log_error "Please remove all emoticons from documentation files"
        return 1
    else
        log_success "No emoticons found in documentation"
        return 0
    fi
}

# Check file permissions
check_file_permissions() {
    log_info "Checking file permissions..."
    
    local issues=0
    
    # Check for executable scripts
    while IFS= read -r -d '' file; do
        if [[ -f "$file" && ! -x "$file" ]]; then
            log_error "Script file not executable: ${file#${PROJECT_ROOT}/}"
            ((issues++))
        fi
    done < <(find "${PROJECT_ROOT}/scripts" -name "*.sh" -print0 2>/dev/null)
    
    # Check for overly permissive files
    while IFS= read -r -d '' file; do
        local perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
        if [[ "$perms" =~ ^[0-9]*[7][7][7]$ ]]; then
            log_warning "File has world-writable permissions: ${file#${PROJECT_ROOT}/} ($perms)"
        fi
    done < <(find "${PROJECT_ROOT}" -type f -print0 2>/dev/null)
    
    if [[ $issues -eq 0 ]]; then
        log_success "File permissions check passed"
        return 0
    else
        log_error "File permissions check failed with $issues issues"
        return 1
    fi
}

# Check Dockerfile best practices
check_dockerfile_practices() {
    log_info "Checking Dockerfile best practices..."
    
    local issues=0
    local dockerfiles=("docker/Dockerfile" "docker/Dockerfile.oracle-linux")
    
    for dockerfile in "${dockerfiles[@]}"; do
        local filepath="${PROJECT_ROOT}/${dockerfile}"
        if [[ ! -f "$filepath" ]]; then
            continue
        fi
        
        log_info "Checking $dockerfile..."
        
        # Check for multi-stage builds
        if ! grep -q "FROM.*AS" "$filepath"; then
            log_warning "$dockerfile: Consider using multi-stage build for smaller images"
        fi
        
        # Check for HEALTHCHECK
        if ! grep -q "HEALTHCHECK" "$filepath"; then
            log_warning "$dockerfile: Missing HEALTHCHECK instruction"
        fi
        
        # Check for proper COPY vs ADD usage
        if grep -q "^ADD" "$filepath"; then
            log_warning "$dockerfile: Consider using COPY instead of ADD unless extracting archives"
        fi
        
        # Check for running as root
        if ! grep -q "USER" "$filepath"; then
            log_warning "$dockerfile: Consider adding non-root USER instruction"
        fi
        
        # Check for version pinning
        if grep -E "^FROM.*:latest" "$filepath"; then
            log_error "$dockerfile: Avoid using 'latest' tag, pin specific versions"
            ((issues++))
        fi
        
        # Check for secrets in build
        if grep -iE "(password|secret|key|token)" "$filepath"; then
            log_error "$dockerfile: Potential secrets detected, use build secrets or multi-stage builds"
            ((issues++))
        fi
        
        # Check for proper layer optimization
        local run_count=$(grep -c "^RUN" "$filepath")
        if [[ $run_count -gt 10 ]]; then
            log_warning "$dockerfile: Consider combining RUN instructions to reduce layers ($run_count RUN instructions found)"
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        log_success "Dockerfile best practices check passed"
        return 0
    else
        log_error "Dockerfile best practices check failed with $issues issues"
        return 1
    fi
}

# Check for security issues
check_security() {
    log_info "Checking for security issues..."
    
    local issues=0
    
    # Check for hardcoded secrets
    log_info "Scanning for potential secrets..."
    local secret_patterns=(
        "password\s*=\s*['\"][^'\"]*['\"]"
        "secret\s*=\s*['\"][^'\"]*['\"]"
        "api[_-]?key\s*=\s*['\"][^'\"]*['\"]"
        "token\s*=\s*['\"][^'\"]*['\"]"
        "-----BEGIN.*PRIVATE KEY-----"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        if grep -rE "$pattern" "${PROJECT_ROOT}" --exclude-dir=.git --exclude="*.log" >/dev/null 2>&1; then
            log_error "Potential secret found matching pattern: $pattern"
            ((issues++))
        fi
    done
    
    # Check for insecure practices in scripts
    while IFS= read -r -d '' file; do
        if grep -q "curl.*http://" "$file" && ! grep -q "# Allow HTTP for testing" "$file"; then
            log_warning "Insecure HTTP download detected in: ${file#${PROJECT_ROOT}/}"
        fi

        if grep -q "wget.*http://" "$file" && ! grep -q "# Allow HTTP for testing" "$file"; then
            log_warning "Insecure HTTP download detected in: ${file#${PROJECT_ROOT}/}"
        fi

        if grep -q "chmod 777" "$file" && ! grep -q "# Allow 777 for testing" "$file"; then
            log_error "Overly permissive chmod 777 detected in: ${file#${PROJECT_ROOT}/}"
            ((issues++))
        fi
    done < <(find "${PROJECT_ROOT}" -name "*.sh" -print0 2>/dev/null)
    
    if [[ $issues -eq 0 ]]; then
        log_success "Security check passed"
        return 0
    else
        log_error "Security check failed with $issues issues"
        return 1
    fi
}

# Check documentation standards
check_documentation() {
    log_info "Checking documentation standards..."
    
    local issues=0
    
    # Check for required documentation files
    local required_docs=("README.md" "CHANGELOG.md" "PROJECT_STATUS.md")
    for doc in "${required_docs[@]}"; do
        if [[ ! -f "${PROJECT_ROOT}/${doc}" ]]; then
            log_error "Missing required documentation: $doc"
            ((issues++))
        fi
    done
    
    # Check for proper markdown formatting
    while IFS= read -r -d '' file; do
        # Check for proper heading structure
        if ! grep -q "^# " "$file"; then
            log_warning "Missing top-level heading in: ${file#${PROJECT_ROOT}/}"
        fi
        
        # Check for trailing whitespace
        if grep -q " $" "$file"; then
            log_warning "Trailing whitespace found in: ${file#${PROJECT_ROOT}/}"
        fi
    done < <(find "${PROJECT_ROOT}" -name "*.md" -print0 2>/dev/null)
    
    if [[ $issues -eq 0 ]]; then
        log_success "Documentation standards check passed"
        return 0
    else
        log_error "Documentation standards check failed with $issues issues"
        return 1
    fi
}

# Check git commit message format
check_commit_message() {
    log_info "Checking commit message format..."
    
    # Get the commit message from git
    local commit_msg
    if [[ -f "${PROJECT_ROOT}/.git/COMMIT_EDITMSG" ]]; then
        commit_msg=$(head -1 "${PROJECT_ROOT}/.git/COMMIT_EDITMSG")
    else
        log_info "No commit message file found, skipping commit message check"
        return 0
    fi
    
    # Check commit message length
    if [[ ${#commit_msg} -lt 10 ]]; then
        log_error "Commit message too short (minimum 10 characters): '$commit_msg'"
        return 1
    fi
    
    if [[ ${#commit_msg} -gt 72 ]]; then
        log_warning "Commit message longer than 72 characters: '$commit_msg'"
    fi
    
    # Check for proper format (conventional commits style)
    if [[ ! "$commit_msg" =~ ^(feat|fix|docs|style|refactor|test|chore|security)(\(.+\))?: ]]; then
        log_warning "Consider using conventional commit format: type(scope): description"
        log_warning "Types: feat, fix, docs, style, refactor, test, chore, security"
    fi
    
    log_success "Commit message format check passed"
    return 0
}

# Main execution
main() {
    log_info "Running pre-commit validation for legacy refactoring..."
    log_info "Project root: ${PROJECT_ROOT}"
    
    cd "${PROJECT_ROOT}"
    
    # Run all checks
    check_emoticons || true
    check_file_permissions || true
    check_dockerfile_practices || true
    check_security || true
    check_documentation || true
    check_commit_message || true
    
    # Final result
    if [[ $EXIT_CODE -eq 0 ]]; then
        log_success "All pre-commit checks passed! Ready to commit."
        echo ""
        log_info "Best practices summary:"
        log_info "  - No emoticons in documentation"
        log_info "  - Proper file permissions"
        log_info "  - Dockerfile best practices followed"
        log_info "  - No security issues detected"
        log_info "  - Documentation standards met"
    else
        log_error "Pre-commit validation failed. Please fix the issues above before committing."
        echo ""
        log_info "To fix issues:"
        log_info "  1. Address all ERROR messages"
        log_info "  2. Consider fixing WARNING messages"
        log_info "  3. Run this script again: ./scripts/pre-commit.sh"
        log_info "  4. Commit when all checks pass"
    fi
    
    exit $EXIT_CODE
}

# Execute main function
main "$@"

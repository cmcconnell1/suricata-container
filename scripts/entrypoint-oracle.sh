#!/bin/bash
# =============================================================================
# SURICATA ORACLE LINUX CONTAINER ENTRYPOINT SCRIPT - SECURITY HARDENED
# =============================================================================
# This script implements security best practices for Oracle Linux containers:
# - Input validation and sanitization
# - Privilege dropping
# - Signal handling
# - Resource limits
# - Comprehensive logging
# - Error handling and recovery
# - Legacy compatibility features
# =============================================================================

set -euo pipefail

# Security: Set restrictive umask
umask 0027

# Security: Clear environment of potentially dangerous variables
unset IFS

# Default configuration with validation
SURICATA_CONFIG=${SURICATA_CONFIG:-/etc/suricata/suricata.yaml}
INTERFACE=${INTERFACE:-eth0}
LOG_LEVEL=${LOG_LEVEL:-info}
SURICATA_USER=${SURICATA_USER:-suricata}
SURICATA_GROUP=${SURICATA_GROUP:-suricata}
UPDATE_RULES=${UPDATE_RULES:-false}
SKIP_CONFIG_TEST=${SKIP_CONFIG_TEST:-false}
BUILD_VARIANT=${BUILD_VARIANT:-afpacket}

# Security: Validate log level
case "${LOG_LEVEL}" in
    emergency|alert|critical|error|warning|notice|info|debug)
        ;;
    *)
        echo "ERROR: Invalid log level '${LOG_LEVEL}'. Must be one of: emergency, alert, critical, error, warning, notice, info, debug"
        exit 1
        ;;
esac

# Security: Validate interface name (basic sanitization)
if [[ ! "${INTERFACE}" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    echo "ERROR: Invalid interface name '${INTERFACE}'. Must contain only alphanumeric characters, hyphens, dots, and underscores."
    exit 1
fi

# Security: Validate build variant
case "${BUILD_VARIANT}" in
    afpacket|napatech)
        ;;
    *)
        echo "ERROR: Invalid build variant '${BUILD_VARIANT}'. Must be 'afpacket' or 'napatech'"
        exit 1
        ;;
esac

# Function to log messages with structured format
log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%S.%3NZ')] [${level}] [PID:$$] [Oracle-${BUILD_VARIANT}] ${message}" >&2
}

# Function to handle errors with context
error_exit() {
    local exit_code="${2:-1}"
    log "ERROR" "$1"
    log "ERROR" "Entrypoint failed at line ${BASH_LINENO[1]} in function ${FUNCNAME[1]}"
    exit "${exit_code}"
}

# Signal handlers for graceful shutdown
cleanup() {
    log "INFO" "Received shutdown signal, cleaning up..."
    if [[ -n "${SURICATA_PID:-}" ]]; then
        log "INFO" "Stopping Suricata process (PID: ${SURICATA_PID})"
        kill -TERM "${SURICATA_PID}" 2>/dev/null || true
        wait "${SURICATA_PID}" 2>/dev/null || true
    fi
    log "INFO" "Cleanup completed"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT SIGQUIT

# Function to validate configuration file
validate_config() {
    log "INFO" "Validating Suricata configuration..."
    
    if [[ ! -f "${SURICATA_CONFIG}" ]]; then
        error_exit "Configuration file not found: ${SURICATA_CONFIG}"
    fi
    
    if [[ "${SKIP_CONFIG_TEST}" != "true" ]]; then
        if ! suricata -T -c "${SURICATA_CONFIG}" >/dev/null 2>&1; then
            error_exit "Configuration validation failed for: ${SURICATA_CONFIG}"
        fi
        log "INFO" "Configuration validation passed"
    else
        log "WARN" "Configuration validation skipped"
    fi
}

# Function to check hardware capabilities (for Napatech)
check_hardware() {
    if [[ "${BUILD_VARIANT}" == "napatech" ]]; then
        log "INFO" "Checking Napatech hardware capabilities..."
        
        # Check if Napatech driver is loaded
        if ! lsmod | grep -q "nt3gd"; then
            log "WARN" "Napatech driver (nt3gd) not loaded"
        else
            log "INFO" "Napatech driver detected"
        fi
        
        # Check for Napatech devices
        if [[ -d "/opt/napatech3" ]]; then
            log "INFO" "Napatech installation directory found"
        else
            log "WARN" "Napatech installation directory not found"
        fi
    fi
}

# Function to update rules
update_rules() {
    if [[ "${UPDATE_RULES}" == "true" ]]; then
        log "INFO" "Updating Suricata rules..."
        if command -v suricata-update >/dev/null 2>&1; then
            if suricata-update --no-test --quiet; then
                log "INFO" "Rules updated successfully"
            else
                log "WARN" "Rule update failed, continuing with existing rules"
            fi
        else
            log "WARN" "suricata-update not available, skipping rule update"
        fi
    fi
}

# Function to set up user and permissions
setup_user() {
    # Create suricata user if it doesn't exist
    if ! id "${SURICATA_USER}" >/dev/null 2>&1; then
        log "INFO" "Creating suricata user..."
        groupadd -r "${SURICATA_GROUP}" 2>/dev/null || true
        useradd -r -g "${SURICATA_GROUP}" -d /var/lib/suricata -s /sbin/nologin "${SURICATA_USER}" 2>/dev/null || true
    fi
    
    # Set up directory permissions
    local dirs=("/var/log/suricata" "/var/run/suricata" "/var/lib/suricata")
    for dir in "${dirs[@]}"; do
        if [[ -d "${dir}" ]]; then
            chown -R "${SURICATA_USER}:${SURICATA_GROUP}" "${dir}" 2>/dev/null || true
            chmod 750 "${dir}" 2>/dev/null || true
        fi
    done
}

# Function to check system resources
check_resources() {
    log "INFO" "Checking system resources..."
    
    # Check memory
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_total / 1024 / 1024))
    if [[ ${mem_gb} -lt 2 ]]; then
        log "WARN" "Low memory detected (${mem_gb}GB). Suricata may not perform optimally."
    else
        log "INFO" "Memory: ${mem_gb}GB available"
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    log "INFO" "CPU cores: ${cpu_cores} available"
    
    # Check disk space
    local disk_free=$(df /var/log | tail -1 | awk '{print $4}')
    local disk_gb=$((disk_free / 1024 / 1024))
    if [[ ${disk_gb} -lt 1 ]]; then
        log "WARN" "Low disk space detected (${disk_gb}GB free in /var/log)"
    else
        log "INFO" "Disk space: ${disk_gb}GB free in /var/log"
    fi
}

# Function to start Suricata
start_suricata() {
    log "INFO" "Starting Suricata with ${BUILD_VARIANT} capture method..."
    
    # Build command arguments
    local suricata_args=(
        "-c" "${SURICATA_CONFIG}"
        "-i" "${INTERFACE}"
        "--user" "${SURICATA_USER}"
        "--group" "${SURICATA_GROUP}"
        "-v"
    )
    
    # Add build-variant specific arguments
    if [[ "${BUILD_VARIANT}" == "napatech" ]]; then
        suricata_args+=("--napatech")
    fi
    
    log "INFO" "Executing: suricata ${suricata_args[*]}"
    
    # Start Suricata in background to handle signals
    suricata "${suricata_args[@]}" &
    SURICATA_PID=$!
    
    log "INFO" "Suricata started with PID: ${SURICATA_PID}"
    
    # Wait for Suricata process
    wait "${SURICATA_PID}"
    local exit_code=$?
    
    log "INFO" "Suricata process exited with code: ${exit_code}"
    exit ${exit_code}
}

# Main execution function
main() {
    log "INFO" "Oracle Linux Suricata container starting..."
    log "INFO" "Build variant: ${BUILD_VARIANT}"
    log "INFO" "Interface: ${INTERFACE}"
    log "INFO" "Log level: ${LOG_LEVEL}"
    
    # Handle special commands
    case "${1:-}" in
        "--version"|"-V")
            exec suricata -V
            ;;
        "/bin/bash"|"bash"|"/bin/sh"|"sh")
            exec "$@"
            ;;
        "suricata")
            # Remove 'suricata' from arguments if present
            shift
            ;;
    esac
    
    # System initialization
    check_resources
    check_hardware
    setup_user
    validate_config
    update_rules
    
    # Start Suricata
    start_suricata
}

# Execute main function with all arguments
main "$@"

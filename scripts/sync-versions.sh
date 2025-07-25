#!/bin/bash
# =============================================================================
# VERSION SYNC SCRIPT FOR SURICATA CONTAINER
# =============================================================================
# This script helps synchronize common changes between Suricata 7.x (main)
# and 8.x (suricata-8.x) branches while preserving version-specific differences.
#
# Usage:
#   ./scripts/sync-versions.sh [OPTIONS]
#
# Options:
#   --from main|suricata-8.x    Source branch (default: main)
#   --to main|suricata-8.x      Target branch (default: suricata-8.x)
#   --files FILE1,FILE2,...     Specific files to sync (comma-separated)
#   --dry-run                   Show what would be synced without doing it
#   --interactive               Prompt for each file
#   --help                      Show this help message
#
# Examples:
#   ./scripts/sync-versions.sh --from main --to suricata-8.x
#   ./scripts/sync-versions.sh --files "README.md,scripts/entrypoint.sh" --dry-run
#   ./scripts/sync-versions.sh --interactive
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
FROM_BRANCH="main"
TO_BRANCH="suricata-8.x"
SPECIFIC_FILES=""
DRY_RUN=false
INTERACTIVE=false

# Files that should typically be synced between versions
# (excluding version-specific files like Makefile and Dockerfile)
SYNCABLE_FILES=(
    "README.md"
    "CHANGELOG.md"
    "PROJECT_STATUS.md"
    "docs/SETUP.md"
    "docs/USAGE.md"
    "docs/TROUBLESHOOTING.md"
    "docs/MULTI-VERSION.md"
    "docs/TAGGING-STRATEGY.md"
    "MULTI-VERSION-QUICK-REFERENCE.md"
    "scripts/entrypoint.sh"
    "scripts/healthcheck.sh"
    "scripts/update-rules.sh"
    "scripts/dev-setup.sh"
    "docker/config/suricata.yaml"
    "docker/config/rules/"
    ".gitignore"
)

# Files that should NOT be synced (version-specific)
EXCLUDED_FILES=(
    "Makefile"
    "docker/Dockerfile"
    "scripts/setup-multi-version.sh"
    "scripts/build-versions.sh"
    "scripts/sync-versions.sh"
    "scripts/update-version.sh"
    ".circleci/config.yml"
)

# Function to show help
show_help() {
    echo -e "${BOLD}Suricata Version Sync Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --from main|suricata-8.x    Source branch (default: main)"
    echo "  --to main|suricata-8.x      Target branch (default: suricata-8.x)"
    echo "  --files FILE1,FILE2,...     Specific files to sync (comma-separated)"
    echo "  --dry-run                   Show what would be synced without doing it"
    echo "  --interactive               Prompt for each file"
    echo "  --help                      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --from main --to suricata-8.x"
    echo "  $0 --files \"README.md,scripts/entrypoint.sh\" --dry-run"
    echo "  $0 --interactive"
    echo ""
    echo "Branch Structure:"
    echo "  main         → Suricata 7.x (stable/default)"
    echo "  suricata-8.x → Suricata 8.x (latest features)"
    echo ""
    echo "Syncable files:"
    for file in "${SYNCABLE_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Excluded files (version-specific):"
    for file in "${EXCLUDED_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
}

# Function to check if file should be excluded
is_excluded() {
    local file=$1
    for excluded in "${EXCLUDED_FILES[@]}"; do
        if [[ "$file" == "$excluded" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to sync a single file
sync_file() {
    local file=$1
    local from_branch=$2
    local to_branch=$3
    
    # Check if file exists in source branch
    if ! git show ${from_branch}:${file} > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ File ${file} does not exist in ${from_branch}${NC}"
        return 1
    fi
    
    # Check if file is excluded
    if is_excluded "$file"; then
        echo -e "${YELLOW}⚠ File ${file} is excluded (version-specific)${NC}"
        return 1
    fi
    
    # Show diff if not dry run
    if [ "$DRY_RUN" = false ]; then
        echo -e "${BLUE}Syncing ${file} from ${from_branch} to ${to_branch}${NC}"
        
        # Create backup if file exists in target
        if git show ${to_branch}:${file} > /dev/null 2>&1; then
            git show ${to_branch}:${file} > /tmp/sync_backup_${file##*/}
        fi
        
        # Copy file from source to target
        git show ${from_branch}:${file} > /tmp/sync_temp_${file##*/}
        
        # Switch to target branch temporarily
        local current_branch=$(git branch --show-current)
        git checkout ${to_branch} > /dev/null 2>&1
        
        # Copy the file
        mkdir -p "$(dirname "$file")"
        cp /tmp/sync_temp_${file##*/} "$file"
        
        # Switch back to original branch
        git checkout ${current_branch} > /dev/null 2>&1
        
        # Clean up temp files
        rm -f /tmp/sync_temp_${file##*/} /tmp/sync_backup_${file##*/}
        
        echo -e "${GREEN}✓ Synced ${file}${NC}"
    else
        echo -e "${BLUE}Would sync: ${file}${NC}"
        
        # Show diff in dry run mode
        if git show ${to_branch}:${file} > /dev/null 2>&1; then
            echo -e "${YELLOW}Differences:${NC}"
            git diff ${to_branch}:${file} ${from_branch}:${file} || true
        else
            echo -e "${YELLOW}File would be created in ${to_branch}${NC}"
        fi
    fi
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --from)
            FROM_BRANCH="$2"
            shift 2
            ;;
        --to)
            TO_BRANCH="$2"
            shift 2
            ;;
        --files)
            SPECIFIC_FILES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --interactive)
            INTERACTIVE=true
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

# Validate branches
if [[ ! "$FROM_BRANCH" =~ ^(main|suricata-8.x)$ ]]; then
    echo -e "${RED}Error: --from must be 'main' or 'suricata-8.x'${NC}"
    exit 1
fi

if [[ ! "$TO_BRANCH" =~ ^(main|suricata-8.x)$ ]]; then
    echo -e "${RED}Error: --to must be 'main' or 'suricata-8.x'${NC}"
    exit 1
fi

if [ "$FROM_BRANCH" = "$TO_BRANCH" ]; then
    echo -e "${RED}Error: Source and target branches cannot be the same${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if branches exist
if ! git show-ref --verify --quiet refs/heads/${FROM_BRANCH}; then
    echo -e "${RED}Error: Branch ${FROM_BRANCH} does not exist${NC}"
    exit 1
fi

if ! git show-ref --verify --quiet refs/heads/${TO_BRANCH}; then
    echo -e "${RED}Error: Branch ${TO_BRANCH} does not exist${NC}"
    exit 1
fi

# Store current branch
ORIGINAL_BRANCH=$(git branch --show-current)

echo -e "${BOLD}Suricata Version Sync${NC}"
echo -e "From: ${FROM_BRANCH}"
echo -e "To: ${TO_BRANCH}"
echo -e "Dry Run: ${DRY_RUN}"
echo -e "Interactive: ${INTERACTIVE}"
echo ""

# Determine files to sync
if [ -n "$SPECIFIC_FILES" ]; then
    IFS=',' read -ra FILES_TO_SYNC <<< "$SPECIFIC_FILES"
else
    FILES_TO_SYNC=("${SYNCABLE_FILES[@]}")
fi

# Sync files
SYNCED_COUNT=0
SKIPPED_COUNT=0

for file in "${FILES_TO_SYNC[@]}"; do
    if [ "$INTERACTIVE" = true ]; then
        echo -e "${YELLOW}Sync ${file}? (y/n/d for diff): ${NC}"
        read -n 1 -r REPLY
        echo
        
        case $REPLY in
            [Yy])
                if sync_file "$file" "$FROM_BRANCH" "$TO_BRANCH"; then
                    ((SYNCED_COUNT++))
                else
                    ((SKIPPED_COUNT++))
                fi
                ;;
            [Dd])
                # Show diff
                if git show ${TO_BRANCH}:${file} > /dev/null 2>&1; then
                    git diff ${TO_BRANCH}:${file} ${FROM_BRANCH}:${file} || true
                else
                    echo -e "${YELLOW}File does not exist in ${TO_BRANCH}${NC}"
                fi
                ((SKIPPED_COUNT++))
                ;;
            *)
                echo -e "${YELLOW}Skipped ${file}${NC}"
                ((SKIPPED_COUNT++))
                ;;
        esac
    else
        if sync_file "$file" "$FROM_BRANCH" "$TO_BRANCH"; then
            ((SYNCED_COUNT++))
        else
            ((SKIPPED_COUNT++))
        fi
    fi
done

# Restore original branch
git checkout ${ORIGINAL_BRANCH} > /dev/null 2>&1

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${BOLD}${GREEN}Sync Complete!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo -e "Files synced: ${SYNCED_COUNT}"
echo -e "Files skipped: ${SKIPPED_COUNT}"

if [ "$DRY_RUN" = false ] && [ "$SYNCED_COUNT" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Review changes in ${TO_BRANCH} branch"
    echo -e "2. Test both versions: ./scripts/build-versions.sh --version both --test"
    echo -e "3. Commit changes if satisfied"
    echo ""
    echo -e "${BLUE}Review changes:${NC}"
    echo -e "git checkout ${TO_BRANCH}"
    echo -e "git status"
    echo -e "git diff"
fi

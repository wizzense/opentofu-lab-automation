#!/bin/bash
# Smart Branch Cleanup Script
# Preserves important branches and reduces clutter by keeping one branch per hour

set -e

# Configuration
REPO_OWNER="wizzense"
REPO_NAME="opentofu-lab-automation"
DRY_RUN=${DRY_RUN:-true} # Set to false to actually delete branches
PRESERVE_HOURS=24 # Keep one branch per hour for last N hours
MAX_BRANCHES_PER_HOUR=1 # Maximum branches to keep per hour

# Color codes for output
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

# Always preserve these branches (patterns)
ALWAYS_PRESERVE=(
 "main"
 "master"
 "develop"
 "feature/deployment-wrapper-gui"
 "advanced-testing"
 "*-patch-*"
 "feature/*"
 "hotfix/*"
 "release/*"
)

# Function to check if a branch should be preserved
should_preserve_branch() {
 local branch="$1"
  # Remove remotes/origin/ prefix and trim whitespace
 branch_name=$(echo "$branch" | sed 's|remotes/origin/||g' | sed 's|^[[:space:]]*||;s|[[:space:]]*$||')
 
 # Check against preserve patterns
 for pattern in "${ALWAYS_PRESERVE[@]}"; do
 case "$branch_name" in
 $pattern) return 0 ;; # Preserve
 esac
 done
 
 return 1 # Don't preserve
}

# Function to get branch creation timestamp (approximation using first commit)
get_branch_timestamp() {
 local branch="$1"
 git log --format="%ct" "$branch" | tail -1 2>/dev/null || echo "0"
}

# Function to format timestamp for display
format_timestamp() {
 local timestamp="$1"
 if [[ "$timestamp" == "0" ]]; then
 echo "unknown"
 else
 date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown"
 fi
}

# Function to group branches by hour
group_branches_by_hour() {
 local -A hour_groups
 local current_time=$(date +%s)
 local preserve_cutoff=$((current_time - PRESERVE_HOURS * 3600))
 
 log_info "Analyzing branches for cleanup..."
 
 # Get all remote branches except HEAD
 while IFS= read -r branch; do
 # Remove leading/trailing whitespace and skip HEAD
 branch=$(echo "$branch" | sed 's|^[[:space:]]*||;s|[[:space:]]*$||')
 [[ "$branch" == *"HEAD"* ]] && continue
 [[ -z "$branch" ]] && continue
 
 # Skip if should be preserved
 if should_preserve_branch "$branch"; then
 log_success "Preserving important branch: $(echo "$branch" | sed 's|remotes/origin/||g')"
 continue
 fi
 
 # Get branch timestamp
 timestamp=$(get_branch_timestamp "$branch")
 [[ "$timestamp" == "0" ]] && continue
 
 # Skip recent branches (within preserve window)
 if [[ "$timestamp" -gt "$preserve_cutoff" ]]; then
 log_success "Preserving recent branch: $(echo "$branch" | sed 's|remotes/origin/||g') ($(format_timestamp "$timestamp"))"
 continue
 fi
 
 # Group by hour
 hour_key=$(date -d "@$timestamp" "+%Y%m%d%H" 2>/dev/null || date -r "$timestamp" "+%Y%m%d%H" 2>/dev/null || echo "unknown")
 if [[ "$hour_key" != "unknown" ]]; then
 hour_groups["$hour_key"]+="$branch|$timestamp "
 fi
 
 done < <(git branch -r | grep -v HEAD | sort)
 
 # Process each hour group
 local total_to_delete=0
 for hour_key in "${!hour_groups[@]}"; do
 local branches_in_hour=(${hour_groups[$hour_key]})
 local branch_count=${#branches_in_hour[@]}
 
 if [[ $branch_count -gt $MAX_BRANCHES_PER_HOUR ]]; then
 log_info "Hour $hour_key has $branch_count branches, keeping $MAX_BRANCHES_PER_HOUR"
 
 # Sort branches by timestamp (newest first) and keep only the first one
 IFS=$'\n' sorted=($(printf '%s\n' "${branches_in_hour[@]}" | sort -t'|' -k2 -nr))
 
 # Mark branches for deletion (skip the first one)
 for ((i=MAX_BRANCHES_PER_HOUR; i<${#sorted[@]}; i++)); do
 local branch_info="${sorted[$i]}"
 local branch_name=$(echo "$branch_info" | cut -d'|' -f1)
 local timestamp=$(echo "$branch_info" | cut -d'|' -f2)
 
 echo "$branch_name|$(format_timestamp "$timestamp")"
 ((total_to_delete++))
 done
 fi
 done
 
 log_info "Found $total_to_delete branches that can be safely deleted"
}

# Function to delete a remote branch
delete_remote_branch() {
 local branch="$1"
 local branch_name=$(echo "$branch" | sed 's|remotes/origin/||g')
 
 if [[ "$DRY_RUN" == "true" ]]; then
 log_warning "[DRY RUN] Would delete: $branch_name"
 else
 log_info "Deleting remote branch: $branch_name"
 if git push origin --delete "$branch_name" 2>/dev/null; then
 log_success "Deleted: $branch_name"
 else
 log_error "Failed to delete: $branch_name"
 fi
 fi
}

# Main cleanup function
main() {
 log_info "� Starting Smart Branch Cleanup"
 log_info "Repository: $REPO_OWNER/$REPO_NAME"
 log_info "Dry Run: $DRY_RUN"
 log_info "Preserve Hours: $PRESERVE_HOURS"
 log_info "Max Branches Per Hour: $MAX_BRANCHES_PER_HOUR"
 echo ""
 
 # Check if we're in the right repository
 if ! git remote get-url origin | grep -q "$REPO_OWNER/$REPO_NAME"; then
 log_error "Not in the correct repository. Expected: $REPO_OWNER/$REPO_NAME"
 exit 1
 fi
 
 # Fetch latest remote information
 log_info "Fetching latest remote information..."
 git fetch --prune
 
 # Get branches to delete
 log_info "Analyzing branches..."
 branches_to_delete=$(group_branches_by_hour)
 
 if [[ -z "$branches_to_delete" ]]; then
 log_success "No branches need cleanup! "
 exit 0
 fi
 
 echo ""
 log_info "Branches scheduled for deletion:"
 echo "$branches_to_delete" | while IFS='|' read -r branch timestamp; do
 printf " %-50s %s\n" "$(echo "$branch" | sed 's|remotes/origin/||g')" "$timestamp"
 done
 
 echo ""
 if [[ "$DRY_RUN" == "true" ]]; then
 log_warning "This is a DRY RUN. No branches will be deleted."
 log_info "To actually delete branches, run: DRY_RUN=false $0"
 else
 read -p "Do you want to proceed with deletion? (y/N): " -n 1 -r
 echo
 if [[ ! $REPLY =~ ^[Yy]$ ]]; then
 log_info "Cleanup cancelled."
 exit 0
 fi
 
 # Delete branches
 echo "$branches_to_delete" | while IFS='|' read -r branch timestamp; do
 delete_remote_branch "$branch"
 done
 fi
 
 echo ""
 log_success "Branch cleanup completed! "
}

# Show usage if help requested
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
 cat << EOF
Smart Branch Cleanup Script

This script intelligently cleans up old branches while preserving important ones.

Configuration:
 DRY_RUN=true/false Whether to actually delete branches (default: true)
 PRESERVE_HOURS=24 Keep one branch per hour for last N hours (default: 24)
 MAX_BRANCHES_PER_HOUR=1 Maximum branches to keep per hour (default: 1)

Always Preserved:
 - main, master, develop branches
 - feature/, hotfix/, release/ branches
 - *-patch-* branches
 - Branches modified in the last $PRESERVE_HOURS hours

Usage:
 $0 # Dry run (show what would be deleted)
 DRY_RUN=false $0 # Actually delete branches
 
Examples:
 $0 # Safe dry run
 DRY_RUN=false $0 # Delete branches
 PRESERVE_HOURS=48 $0 # Keep 48 hours of branches
 MAX_BRANCHES_PER_HOUR=2 $0 # Keep 2 branches per hour

The script uses intelligent heuristics to:
1. Preserve all important branch types
2. Keep recent branches (last $PRESERVE_HOURS hours)
3. Reduce historical branches to $MAX_BRANCHES_PER_HOUR per hour
4. Maintain a good historical sampling for code archaeology
EOF
 exit 0
fi

main "$@"

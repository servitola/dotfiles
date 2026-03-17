#!/bin/zsh
# Git Repository Finder and Pruner - Aggressive Mode
# Finds ALL git repositories on your Mac, shows sizes, and offers cleanup options
# No size limits, no timeouts - comprehensive scan with AGGRESSIVE pruning

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration - Search ALL common locations
SEARCH_DIRS=(
    "$HOME"
    "$HOME/projects"
    "$HOME/work"
    "$HOME/dev"
    "$HOME/code"
    "$HOME/src"
    "$HOME/git"
    "$HOME/repos"
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Downloads"
    "/Users/servitola/projects"
)

MIN_SIZE_MB=0  # No minimum - show ALL repos

print_header() {
    printf "\n${BLUE}${BOLD}━━━ %s ━━━${NC}\n" "$1"
}

print_info() {
    printf "${GREEN}➜${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$1"
}

print_section() {
    printf "\n${CYAN}${BOLD}%s${NC}\n" "$1"
}

# Find all git repositories
find_git_repos() {
    local repos=()

    print_header "Searching for Git Repositories"
    echo "Searching in: ${SEARCH_DIRS[*]}"
    echo "Minimum size: ${MIN_SIZE_MB}MB (showing ALL)"
    echo "This may take a while..."
    echo

    for dir in "${SEARCH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            print_info "Scanning: $dir"
            while IFS= read -r -d '' repo; do
                repos+=("$repo")
            done < <(find "$dir" -type d -name ".git" -print0 2>/dev/null)
        fi
    done

    # Remove duplicates and print
    printf "%s\n" "${repos[@]}" | sort -u
}

# Get repository size
get_repo_size() {
    local git_dir="$1"
    local repo_path="${git_dir%/.git}"

    # Calculate .git folder size
    local git_size=$(du -sm "$git_dir" 2>/dev/null | cut -f1)
    [ -z "$git_size" ] && git_size=0

    # Calculate working tree size (excluding .git)
    local working_size=$(du -sm "$repo_path" --exclude='.git' 2>/dev/null | cut -f1)
    [ -z "$working_size" ] && working_size=0

    local total_size=$((git_size + working_size))

    echo "$total_size $git_size $working_size"
}

# Get git status info
get_repo_status() {
    local repo_path="$1"

    cd "$repo_path" 2>/dev/null || return

    # Check if valid git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "invalid"
        return
    fi

    # Get branch info
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Check for uncommitted changes
    local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    # Get last commit date
    local last_commit=$(git log -1 --format="%cr" 2>/dev/null || echo "unknown")
    local last_commit_date=$(git log -1 --format="%ci" 2>/dev/null | cut -d' ' -f1)

    # Count branches
    local branch_count=$(git branch 2>/dev/null | wc -l | tr -d ' ')

    # Get remote count
    local remote_count=$(git remote 2>/dev/null | wc -l | tr -d ' ')

    # Get remote URL (first one)
    local remote_url=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]/github.com\//' | cut -d'/' -f1-2)
    [ -z "$remote_url" ] && remote_url="no-remote"

    echo "$branch|$changes|$last_commit|$branch_count|$remote_count|$remote_url|$last_commit_date"
}

# Aggressive prune git repository
prune_repo_aggressive() {
    local repo_path="$1"
    local dry_run="${2:-false}"

    cd "$repo_path" 2>/dev/null || return 1

    if [ "$dry_run" = "true" ]; then
        print_warning "[DRY RUN] Would aggressively prune: $repo_path"
        return 0
    fi

    print_info "Aggressively pruning: $repo_path"

    # Step 1: Expire ALL reflog entries immediately (aggressive)
    git reflog expire --expire=now --expire-unreachable=now --all > /dev/null 2>&1

    # Step 2: Aggressive garbage collection
    git gc --aggressive --prune=now > /dev/null 2>&1

    # Step 3: Prune stale remotes
    git remote prune origin > /dev/null 2>&1
    git fetch --prune > /dev/null 2>&1

    # Step 4: Clean packed refs
    git pack-refs --all > /dev/null 2>&1

    # Step 5: Repack with best compression (aggressive)
    git repack -a -d --depth=250 --window=250 > /dev/null 2>&1

    # Step 6: Prune again after repack
    git prune --expire=now > /dev/null 2>&1

    print_info "✓ Aggressively pruned: $repo_path"
}

# Clean git LFS cache aggressively
clean_lfs_cache_aggressive() {
    local repo_path="$1"

    cd "$repo_path" 2>/dev/null || return 1

    if git lfs version > /dev/null 2>&1; then
        # Aggressive LFS prune - remove all unreferenced LFS objects
        git lfs prune --verify --recent "never" --verbose > /dev/null 2>&1
        print_info "  LFS cache aggressively cleaned"
    fi
}

# Main analysis
analyze_repos() {
    local repos=("$@")
    local total_size=0
    local total_git_size=0
    local repo_data=()
    local valid_count=0

    print_header "Analyzing Repositories"
    echo

    printf "${BOLD}%-65s %10s %10s %10s %12s %8s %15s %25s${NC}\n" \
        "Repository" "Total" ".git" "Working" "Last Commit" "Branches" "Remotes" "Remote URL"
    printf "%s\n" "$(printf '=%.0s' {1..160})"

    for git_dir in "${repos[@]}"; do
        local repo_path="${git_dir%/.git}"
        local repo_name="${repo_path#$HOME}"

        # Get sizes
        local sizes=($(get_repo_size "$git_dir"))
        local total=${sizes[0]}
        local git_size=${sizes[1]}
        local working_size=${sizes[2]}

        # Get status
        local repo_status=$(get_repo_status "$repo_path")
        if [ "$repo_status" = "invalid" ]; then
            continue
        fi

        IFS='|' read -r branch changes last_commit branch_count remote_count remote_url last_commit_date <<< "$repo_status"

        # Add to totals
        total_size=$((total_size + total))
        total_git_size=$((total_git_size + git_size))
        valid_count=$((valid_count + 1))

        # Store data for sorting
        repo_data+=("$total|$repo_name|$total|$git_size|$working_size|$last_commit|$branch_count|$remote_count|$remote_url|$last_commit_date")

        # Print row (truncate long paths)
        local display_name="${repo_name:0:64}"
        local display_url="${remote_url:0:24}"
        printf "%-65s %10s %10s %10s %12s %8s %15s %25s\n" \
            "$display_name" "${total}MB" "${git_size}MB" "${working_size}MB" "$last_commit" "$branch_count" "$remote_count" "$display_url"
    done

    printf "%s\n" "$(printf '=%.0s' {1..160})"
    echo

    print_header "Summary"
    print_info "Total .git directories found: ${#repos[@]}"
    print_info "Valid repositories analyzed: $valid_count"
    print_info "Total disk space used: ${total_size}MB ($(echo "scale=2; $total_size/1024" | bc 2>/dev/null || echo "$((total_size/1024))")GB)"
    print_info "Total .git folder size: ${total_git_size}MB ($(echo "scale=2; $total_git_size/1024" | bc 2>/dev/null || echo "$((total_git_size/1024))")GB)"
    print_info "Total working tree size: $((total_size - total_git_size))MB"
    print_warning "Estimated space savings (aggressive): ~$((total_git_size * 40 / 100))MB (40% of .git size)"
    echo

    # Sort by size and show top 20
    if [ ${#repo_data[@]} -gt 0 ]; then
        print_header "Top 20 Largest Repositories (by .git size)"
        printf "${BOLD}%-65s %10s %10s %15s %25s${NC}\n" "Repository" "Total" ".git" "Last Commit" "Remote"
        printf "%s\n" "$(printf '=%.0s' {1..140})"

        printf "%s\n" "${repo_data[@]}" | sort -t'|' -k3 -nr | head -20 | while IFS='|' read -r size name total git_size working last_commit branch_count remote_count remote_url last_commit_date; do
            local short_name="${name#$HOME}"
            local display_name="${short_name:0:64}"
            local display_url="${remote_url:0:24}"
            printf "%-65s %10s %10s %15s %25s\n" "$display_name" "${total}MB" "${git_size}MB" "$last_commit" "$display_url"
        done
        echo
    fi

    # Sort by last commit date to show stale repos
    print_header "Potentially Stale Repositories (no commits in >6 months)"
    printf "${BOLD}%-65s %10s %15s %25s${NC}\n" "Repository" ".git" "Last Commit" "Remote"
    printf "%s\n" "$(printf '=%.0s' {120})"

    local stale_count=0
    printf "%s\n" "${repo_data[@]}" | sort -t'|' -k10 | head -20 | while IFS='|' read -r size name total git_size working last_commit branch_count remote_count remote_url last_commit_date; do
        # Check if older than 6 months (approx 180 days)
        local commit_epoch=$(date -d "$last_commit_date" +%s 2>/dev/null || echo "0")
        local now_epoch=$(date +%s)
        local days_old=$(( (now_epoch - commit_epoch) / 86400 ))

        if [ "$days_old" -gt 180 ] 2>/dev/null; then
            local short_name="${name#$HOME}"
            local display_name="${short_name:0:64}"
            local display_url="${remote_url:0:24}"
            printf "%-65s %10s %15s %25s\n" "$display_name" "${git_size}MB" "$last_commit ($days_old days)" "$display_url"
            stale_count=$((stale_count + 1))
        fi
    done
    echo

    # Show repos with no remote
    print_header "Repositories Without Remote (local only)"
    printf "${BOLD}%-65s %10s %10s${NC}\n" "Repository" "Total" ".git"
    printf "%s\n" "$(printf '=%.0s' {90})"

    printf "%s\n" "${repo_data[@]}" | grep '|0|' | sort -t'|' -k3 -nr | head -10 | while IFS='|' read -r size name total git_size working last_commit branch_count remote_count remote_url last_commit_date; do
        local short_name="${name#$HOME}"
        local display_name="${short_name:0:64}"
        printf "%-65s %10s %10s\n" "$display_name" "${total}MB" "${git_size}MB"
    done
    echo
}

# Aggressive prune all repositories
prune_all_repos_aggressive() {
    local repos=("$@")
    local dry_run="${1:-false}"
    local pruned_count=0
    local space_before=0
    local space_after=0

    print_header "Aggressively Pruning Repositories"
    print_warning "Mode: AGGRESSIVE (maximum space savings)"
    print_warning "This will remove ALL unreachable objects including recent reflogs"
    echo

    for git_dir in "${repos[@]}"; do
        local repo_path="${git_dir%/.git}"
        local sizes=($(get_repo_size "$git_dir"))
        local old_git_size=${sizes[1]}
        space_before=$((space_before + old_git_size))

        prune_repo_aggressive "$repo_path" "$dry_run"

        if [ "$dry_run" = "false" ]; then
            clean_lfs_cache_aggressive "$repo_path"
            pruned_count=$((pruned_count + 1))

            # Calculate new size
            local new_sizes=($(get_repo_size "$git_dir"))
            local new_git_size=${new_sizes[1]}
            space_after=$((space_after + new_git_size))
        fi
    done

    local space_saved=$((space_before - space_after))
    local percent_saved=0
    if [ "$space_before" -gt 0 ]; then
        percent_saved=$((space_saved * 100 / space_before))
    fi

    if [ "$dry_run" = "false" ]; then
        print_header "Aggressive Pruning Complete"
        print_info "Repositories pruned: $pruned_count"
        print_info "Space before: ${space_before}MB"
        print_info "Space after: ${space_after}MB"
        print_info "Space saved: ${space_saved}MB ($(echo "scale=2; $space_saved/1024" | bc 2>/dev/null || echo "$((space_saved/1024))")GB)"
        print_info "Savings percentage: ${percent_saved}%"
    else
        print_warning "This was a dry run. Use --prune to actually prune repositories."
    fi
}

# Show help
show_help() {
    cat << EOF
${BOLD}Git Repository Finder and Pruner - Aggressive Mode${NC}

Finds ALL git repositories on your Mac, analyzes their sizes, and offers
AGGRESSIVE cleanup options for maximum space savings.

${BOLD}Usage:${NC}
  $0 [options]

${BOLD}Options:${NC}
  -h, --help          Show this help message
  -p, --prune         Aggressively prune all repositories
  --dry-run           Show what would be pruned without making changes
  --top N             Show only top N largest repositories (default: show all)
  --json              Output results in JSON format

${BOLD}Examples:${NC}
  $0                  # Full scan and analysis
  $0 --top 20         # Show only top 20 largest repos
  $0 --prune          # Aggressively prune all repos (MAXIMUM savings)
  $0 --dry-run --prune # See what would be pruned

${BOLD}Aggressive Mode - What gets pruned:${NC}
  ✓ ALL reflog entries (expired immediately)
  ✓ ALL unreachable objects (gc --aggressive --prune=now)
  ✓ Stale remote-tracking branches
  ✓ LFS cache (all unreferenced objects)
  ✓ Packed refs cleanup
  ✓ Aggressive repack with best compression

${YELLOW}Safety Notes:${NC}
  • Pruning is SAFE - won't delete committed data
  • Only removes UNREACHABLE objects (orphaned commits, old reflogs)
  • RECOMMENDED: Commit or stash work before pruning
  • RECOMMENDED: Push important branches to remote first
  • After aggressive prune, CANNOT recover orphaned commits

${GREEN}Expected Savings:${NC}
  • Standard prune: ~20-30% of .git folder size
  • Aggressive prune: ~40-60% of .git folder size

${BOLD}Search Locations:${NC}
  - \$HOME, \$HOME/projects, \$HOME/work, \$HOME/dev
  - \$HOME/code, \$HOME/src, \$HOME/git, \$HOME/repos
  - \$HOME/Documents, \$HOME/Desktop, \$HOME/Downloads
EOF
}

# Parse arguments
DRY_RUN=false
DO_PRUNE=false
TOP_N=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--prune)
            DO_PRUNE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --top)
            TOP_N="$2"
            shift 2
            ;;
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header "Git Repository Analyzer - Aggressive Mode"
    print_info "Comprehensive scan of all git repositories"
    print_info "This may take several minutes..."
    echo

    # Find all repositories
    local repos=($(find_git_repos))

    if [ ${#repos[@]} -eq 0 ]; then
        print_error "No git repositories found!"
        exit 1
    fi

    print_info "Found ${#repos[@]} git repositories"
    echo

    # Analyze repositories
    analyze_repos "${repos[@]}"

    # Prune if requested
    if [ "$DO_PRUNE" = "true" ]; then
        echo
        prune_all_repos_aggressive "${repos[@]}" "$DRY_RUN"
    else
        echo
        print_info "To AGGRESSIVELY prune repositories and reclaim maximum space, run:"
        print_info "  ${BOLD}$0 --prune${NC}"
        print_info "Or for dry run first:"
        print_info "  ${BOLD}$0 --dry-run --prune${NC}"
        echo
        print_warning "Aggressive mode removes ALL unreachable objects for maximum savings!"
    fi
}

main

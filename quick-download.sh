#!/bin/bash
# Quick Download Script - Automatically detects the current branch
# Usage: ./quick-download.sh [file]

set -e

# Default repository details
REPO="wizzense/opentofu-lab-automation"
DEFAULT_BRANCH="main"

# Function to get the current branch being viewed
get_current_branch() {
    # If we're in a git repository, get the current branch
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git branch --show-current 2>/dev/null || echo "$DEFAULT_BRANCH"
    else
        echo "$DEFAULT_BRANCH"
    fi
}

# Function to download a file
download_file() {
    local file="$1"
    local branch="${2:-$(get_current_branch)}"
    local url="https://raw.githubusercontent.com/${REPO}/${branch}/${file}"
    
    echo "📥 Downloading ${file} from branch '${branch}'..."
    
    if command -v curl >/dev/null 2>&1; then
        curl -LO "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget "$url"
    else
        echo "❌ Error: Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    echo "✅ Downloaded: ${file}"
}

# Main script
main() {
    local file="${1:-deploy.py}"
    local branch="$(get_current_branch)"
    
    echo "🚀 OpenTofu Lab Automation - Quick Download"
    echo "Repository: ${REPO}"
    echo "Branch: ${branch}"
    echo ""
    
    case "$file" in
        "all")
            echo "📦 Downloading all deployment files..."
            download_file "deploy.py" "$branch"
            download_file "gui.py" "$branch"
            download_file "deploy.sh" "$branch"
            download_file "launch-gui.sh" "$branch"
            chmod +x *.py *.sh
            echo ""
            echo "✅ All files downloaded and made executable!"
            echo "🚀 Run: python3 deploy.py"
            echo "🎨 Run: python3 gui.py"
            ;;
        "gui")
            download_file "gui.py" "$branch"
            chmod +x gui.py
            echo "🎨 Run: python3 gui.py"
            ;;
        *)
            download_file "$file" "$branch"
            if [[ "$file" == *.py ]] || [[ "$file" == *.sh ]]; then
                chmod +x "$file"
            fi
            echo "🚀 Run: python3 $file"
            ;;
    esac
}

# Show usage if help requested
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    cat << EOF
Usage: $0 [file|command]

Commands:
  deploy.py       Download main deployment script (default)
  gui.py          Download GUI application
  all             Download all deployment files
  
Examples:
  $0              # Download deploy.py
  $0 gui.py       # Download GUI
  $0 all          # Download everything

The script automatically detects the current git branch and downloads
files from that branch. If not in a git repo, uses the main branch.
EOF
    exit 0
fi

main "$@"

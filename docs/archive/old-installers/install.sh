#!/bin/bash
# OpenTofu Lab Automation - Unix Installer
# Works on Linux, macOS, WSL, and any Unix-like system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

show_header() {
    echo -e "${BLUE}${BOLD}"
    echo "======================================================"
    echo "  OpenTofu Lab Automation - Unix/Linux Installer"
    echo "======================================================"
    echo -e "${NC}"
}

detect_platform() {
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    echo -e "${YELLOW}🖥️  Platform Information:${NC}"
    echo "   OS: $OS"
    echo "   Architecture: $ARCH"
    
    # Check if GUI is available
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        echo "   GUI: Available"
        GUI_AVAILABLE=true
    else
        echo "   GUI: Not available (headless)"
        GUI_AVAILABLE=false
    fi
    echo
}

check_internet() {
    echo -e "${BLUE}🌐 Checking internet connectivity...${NC}"
    
    if command -v curl &> /dev/null; then
        if curl -s --head --request GET https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/README.md | grep "200 OK" > /dev/null; then
            echo -e "${GREEN}✅ Internet connection confirmed${NC}"
            DOWNLOAD_CMD="curl"
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget --spider -q https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/README.md; then
            echo -e "${GREEN}✅ Internet connection confirmed${NC}"
            DOWNLOAD_CMD="wget"
            return 0
        fi
    fi
    
    echo -e "${RED}❌ No internet connection or download tool available${NC}"
    echo "Please install curl or wget and check your network connection"
    return 1
}

download_file() {
    local url="$1"
    local output_file="$2"
    
    echo -e "${BLUE}📥 Downloading: $output_file${NC}"
    
    if [ "$DOWNLOAD_CMD" = "curl" ]; then
        if curl -L -o "$output_file" "$url"; then
            echo -e "${GREEN}✅ Downloaded successfully: $output_file${NC}"
            return 0
        fi
    elif [ "$DOWNLOAD_CMD" = "wget" ]; then
        if wget -O "$output_file" "$url"; then
            echo -e "${GREEN}✅ Downloaded successfully: $output_file${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}❌ Download failed: $output_file${NC}"
    return 1
}

install_components() {
    local component="${1:-launcher}"
    local base_url="https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD"
    
    echo -e "${BLUE}📦 Downloading components...${NC}"
    echo
    
    case "$component" in
        "launcher"|"")
            download_file "$base_url/launcher.py" "launcher.py" || return 1
            chmod +x launcher.py
            ;;
        "gui")
            download_file "$base_url/gui.py" "gui.py" || return 1
            ;;
        "deploy")
            download_file "$base_url/deploy.py" "deploy.py" || return 1
            ;;
        "all")
            download_file "$base_url/launcher.py" "launcher.py" || return 1
            download_file "$base_url/gui.py" "gui.py" || return 1
            download_file "$base_url/deploy.py" "deploy.py" || return 1
            download_file "$base_url/README.md" "README.md" || return 1
            chmod +x launcher.py
            ;;
        *)
            echo -e "${RED}❌ Unknown component: $component${NC}"
            return 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}✅ Download completed successfully!${NC}"
    return 0
}

check_python() {
    echo -e "${BLUE}🐍 Checking Python availability...${NC}"
    
    for cmd in python3 python; do
        if command -v "$cmd" &> /dev/null; then
            local version=$($cmd --version 2>&1)
            if echo "$version" | grep -q "Python 3\.[0-9]"; then
                echo -e "${GREEN}✅ Python found: $version${NC}"
                PYTHON_CMD="$cmd"
                return 0
            fi
        fi
    done
    
    echo -e "${YELLOW}⚠️  Python 3.7+ not found${NC}"
    PYTHON_CMD=""
    return 1
}

show_install_instructions() {
    echo
    echo -e "${YELLOW}📥 Python Installation Instructions:${NC}"
    
    if [ "$OS" = "Darwin" ]; then
        echo "• Install with Homebrew: brew install python3"
        echo "• Or download from: https://python.org"
    elif [ "$OS" = "Linux" ]; then
        # Detect Linux distribution
        if [ -f /etc/debian_version ]; then
            echo "• Ubuntu/Debian: sudo apt update && sudo apt install python3"
        elif [ -f /etc/redhat-release ]; then
            echo "• CentOS/RHEL: sudo yum install python3"
        elif [ -f /etc/arch-release ]; then
            echo "• Arch Linux: sudo pacman -S python"
        else
            echo "• Use your distribution's package manager to install python3"
        fi
    else
        echo "• Use your system's package manager to install Python 3.7+"
    fi
}

show_usage_instructions() {
    echo
    echo -e "${GREEN}🎯 Next Steps:${NC}"
    
    if [ -n "$PYTHON_CMD" ]; then
        echo "   1. Run: $PYTHON_CMD launcher.py"
        echo "   2. Select 'Deploy Lab Environment' for first-time setup"
        if $GUI_AVAILABLE; then
            echo "   3. Use 'Launch GUI Interface' for graphical management"
        else
            echo "   3. Use command line interface (GUI not available)"
        fi
    else
        echo "   1. Install Python 3.7+ (see instructions above)"
        echo "   2. Run: python3 launcher.py"
    fi
    
    echo
    echo -e "${BLUE}📚 Available Commands:${NC}"
    echo "   ./launcher.py          # Interactive menu"
    echo "   ./launcher.py deploy   # Deploy lab environment"
    echo "   ./launcher.py gui      # Launch GUI interface"
    echo "   ./launcher.py health   # Run health check"
    echo "   ./launcher.py validate # Validate setup"
}

main() {
    show_header
    detect_platform
    
    check_internet || exit 1
    echo
    
    # Parse command line arguments
    COMPONENT="${1:-launcher}"
    NO_MENU="${2}"
    
    install_components "$COMPONENT" || exit 1
    
    check_python
    if [ -z "$PYTHON_CMD" ]; then
        show_install_instructions
    fi
    
    show_usage_instructions
    
    # Auto-launch if Python is available and not in no-menu mode
    if [ -n "$PYTHON_CMD" ] && [ "$NO_MENU" != "--no-menu" ] && [ -f "launcher.py" ]; then
        echo
        echo -e "${GREEN}🚀 Launching interactive menu...${NC}"
        echo
        $PYTHON_CMD launcher.py
    fi
}

# Show help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "OpenTofu Lab Automation - Unix Installer"
    echo
    echo "Usage: $0 [component] [--no-menu]"
    echo
    echo "Components:"
    echo "  launcher (default) - Download unified launcher"
    echo "  gui               - Download GUI only"  
    echo "  deploy            - Download deploy script only"
    echo "  all               - Download everything"
    echo
    echo "Options:"
    echo "  --no-menu         - Don't auto-launch interactive menu"
    echo "  --help, -h        - Show this help"
    echo
    echo "Examples:"
    echo "  $0                    # Download launcher and run interactive menu"
    echo "  $0 all                # Download all components"
    echo "  $0 launcher --no-menu # Download launcher only, don't auto-run"
    exit 0
fi

main "$@"

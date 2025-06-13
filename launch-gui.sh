#!/bin/bash
# Unix/Linux/macOS GUI Launcher for OpenTofu Lab Automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}"
echo "========================================"
echo "  OpenTofu Lab Automation - GUI Launcher"
echo "========================================"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo -e "${RED}ERROR: Python is not installed or not in PATH${NC}"
        echo ""
        echo "Please install Python 3.7+ using your package manager:"
        echo "  Ubuntu/Debian: sudo apt-get install python3"
        echo "  CentOS/RHEL:   sudo yum install python3"
        echo "  macOS:         brew install python3"
        echo ""
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

# Check for tkinter
if ! $PYTHON_CMD -c "import tkinter" &> /dev/null; then
    echo -e "${RED}ERROR: tkinter is not available${NC}"
    echo ""
    echo "Please install tkinter:"
    echo "  Ubuntu/Debian: sudo apt-get install python3-tk"
    echo "  CentOS/RHEL:   sudo yum install tkinter"
    echo "  macOS:         tkinter should be included with Python"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Dependencies verified${NC}"
echo -e "${BLUE}Starting GUI...${NC}"
echo ""

# Launch GUI
if $PYTHON_CMD "$SCRIPT_DIR/gui.py"; then
    echo ""
    echo -e "${GREEN}${BOLD}GUI closed successfully${NC}"
else
    echo ""
    echo -e "${RED}${BOLD}GUI encountered an error${NC}"
    exit 1
fi

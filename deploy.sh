#!/bin/bash
# Unix/Linux/macOS Shell Wrapper for OpenTofu Lab Automation
# Provides simple deployment for Unix-like systems

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}"
echo "==============================================="
echo "  OpenTofu Lab Automation - Unix Deployment  "
echo "==============================================="
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo -e "${RED}ERROR: Python is not installed or not in PATH${NC}"
        echo ""
        echo "Please install Python 3.7+ using your package manager:"
        echo "  Ubuntu/Debian: sudo apt install python3"
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

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || [ "$PYTHON_MAJOR" -eq 3 -a "$PYTHON_MINOR" -lt 7 ]; then
    echo -e "${RED}ERROR: Python 3.7+ required, found $PYTHON_VERSION${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Python $PYTHON_VERSION found${NC}"

# Run the deployment script
echo -e "${BLUE}Starting deployment...${NC}"
echo ""

if $PYTHON_CMD "$SCRIPT_DIR/deploy.py" "$@"; then
    echo ""
    echo -e "${GREEN}${BOLD}*** Deployment completed successfully ***${NC}"
else
    echo ""
    echo -e "${RED}${BOLD}*** Deployment encountered errors ***${NC}"
    exit 1
fi

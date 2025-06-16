#!/bin/bash
set -e

# OpenTofu Lab Automation - Quick Start (Bash version)
# Universal installer for Linux/macOS/Windows Subsystem for Linux

echo " OpenTofu Lab Automation - Quick Start"
echo "========================================="

# Check if Python is available
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
 echo "[FAIL] ERROR: Python 3.7+ is required but not found"
 echo "Please install Python first:"
 echo " - Ubuntu/Debian: sudo apt update && sudo apt install python3"
 echo " - CentOS/RHEL: sudo yum install python3"
 echo " - macOS: brew install python3"
 exit 1
fi

# Determine Python command
if command -v python3 &> /dev/null; then
 PYTHON_CMD="python3"
else
 PYTHON_CMD="python"
fi

echo "✓ Found Python: $PYTHON_CMD"

# Download the quick-start script
echo "� Downloading quick-start script..."
if command -v curl &> /dev/null; then
 curl -sSL -o quick-start.py https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-start.py
elif command -v wget &> /dev/null; then
 wget -q -O quick-start.py https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-start.py
else
 echo "[FAIL] ERROR: Neither curl nor wget found"
 echo "Please install one of them or download manually:"
 echo "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-start.py"
 exit 1
fi

echo "✓ Downloaded quick-start.py"

# Make executable and run
chmod +x quick-start.py
echo " Starting OpenTofu Lab Automation..."
$PYTHON_CMD quick-start.py

#!/bin/bash
# OpenTofu Lab Automation - Unified Launcher (Unix Wrapper)
# This script replaces all previous deploy/launch scripts

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Run the unified launcher
exec python3 "$SCRIPT_DIR/launcher.py" "$@"

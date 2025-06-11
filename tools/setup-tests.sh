#!/usr/bin/env bash
# Wrapper to invoke setup-tests.ps1 using PowerShell
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PWSH="${PWSH:-pwsh}"

if ! command -v "$PWSH" >/dev/null 2>&1; then
  echo "PowerShell not found. Install PowerShell 7+ to continue." >&2
  exit 1
fi

"$PWSH" -NoLogo -NoProfile -File "$SCRIPT_DIR/setup-tests.ps1" "$@"

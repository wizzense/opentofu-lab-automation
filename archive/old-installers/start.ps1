#!/usr/bin/env pwsh
# OpenTofu Lab Automation - Unified Launcher (PowerShell Wrapper)
# This script replaces all previous deploy/launch scripts

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcherPath = Join-Path $scriptDir "launcher.py"

if (Get-Command python3 -ErrorAction SilentlyContinue) {
    & python3 $launcherPath @Arguments
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python $launcherPath @Arguments
} else {
    Write-Error "Python is not installed or not in PATH"
    exit 1
}

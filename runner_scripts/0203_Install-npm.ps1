<#
.SYNOPSIS
    Install frontend project dependencies using npm.

.DESCRIPTION
    - Finds the frontend project folder (from config or default)
    - Runs `npm install` inside it
    - Logs results to console and optionally exits on failure

.CONFIG FORMAT
{
  "Node_Dependencies": {
    "InstallNpm": true,
    "NpmPath": "C:\\Projects\\vde-mvp\\frontend"
  }
}

.PARAMETER Config
    The config object passed in from runner.ps1

.EXAMPLE
    .\0203-InstallNpm.ps1 -Config $Config
#>

param(
    [Parameter(Mandatory)]
    [hashtable]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

$ErrorActionPreference = "Stop"
Write-Log "==== [0203] Installing Frontend npm Dependencies ===="

# Determine npm project path
$npmPath = if ($Config.Node_Dependencies.NpmPath) {
    $Config.Node_Dependencies.NpmPath
} else {
    Join-Path $PSScriptRoot "..\frontend"
}

if (-not (Test-Path $npmPath)) {
    Write-Error "ERROR: Frontend folder not found at: $npmPath"
    exit 1
}

if (-not (Test-Path (Join-Path $npmPath "package.json"))) {
    Write-Error "ERROR: No package.json found in frontend folder. Cannot run npm install."
    exit 1
}

Push-Location $npmPath

try {
    Write-Log "Running npm install in $npmPath ..."
    npm install
    Write-Log "✅ npm install completed."
} catch {
    Write-Error "ERROR: npm install failed: $_"
    exit 1
}

Pop-Location
Write-Log "==== Frontend dependency installation complete ===="

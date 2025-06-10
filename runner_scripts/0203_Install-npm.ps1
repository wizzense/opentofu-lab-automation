Param([pscustomobject]$Config)

function Install-NpmDependencies {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([pscustomobject]$Config)

    $StepConfig = $Config
    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
    Invoke-LabStep -Config $StepConfig -Body {
    param($Config)
    Write-CustomLog 'Running 0203_Install-npm.ps1'

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

Write-Output "Config parameter is: $Config"

Write-CustomLog "==== [0203] Installing Frontend npm Dependencies ===="

if ($Config -is [hashtable]) {
    if (-not $Config.ContainsKey('Node_Dependencies')) {
        Write-CustomLog "Config missing Node_Dependencies; skipping npm install."
        return
    }
} elseif (-not $Config.PSObject.Properties.Match('Node_Dependencies')) {
    Write-CustomLog "Config missing Node_Dependencies; skipping npm install."
    return
}

# default to true when InstallNpm is not specified
$installNpm = $true
if ($Config.Node_Dependencies -is [hashtable]) {
    if ($Config.Node_Dependencies.ContainsKey('InstallNpm')) {
        $installNpm = [bool]$Config.Node_Dependencies['InstallNpm']
    }
} elseif ($Config.Node_Dependencies.PSObject.Properties.Match('InstallNpm').Count -gt 0) {
    $installNpm = [bool]$Config.Node_Dependencies.InstallNpm
}

if ($installNpm) {

# Determine frontend path
$frontendPath = if ($Config.Node_Dependencies.NpmPath) {

    $Config.Node_Dependencies.NpmPath
} else {
    Join-Path $PSScriptRoot "..\frontend"
}

$createPath = $false
if ($Config.Node_Dependencies -is [hashtable]) {
    if ($Config.Node_Dependencies.ContainsKey('CreateNpmPath')) {
        $createPath = [bool]$Config.Node_Dependencies['CreateNpmPath']
    }
} elseif ($Config.Node_Dependencies.PSObject.Properties.Match('CreateNpmPath').Count -gt 0) {
    $createPath = [bool]$Config.Node_Dependencies.CreateNpmPath
}

if (-not (Test-Path $frontendPath)) {
    if ($createPath) {
        Write-CustomLog "Creating missing frontend folder at: $frontendPath"
        New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null
    } else {
        Write-CustomLog "Frontend folder not found at: $frontendPath. Skipping npm install."
        return
    }
}

if (-not (Test-Path (Join-Path $frontendPath "package.json"))) {
    if ($createPath) {
        '{}' | Set-Content -Path (Join-Path $frontendPath 'package.json')
    } else {
        Write-CustomLog "No package.json found in $frontendPath. Skipping npm install."
        return
    }
}

Push-Location $frontendPath

try {
    Write-CustomLog "Running npm install in $frontendPath ..."

    npm install
    Write-CustomLog "npm install completed."

} catch {
    Write-Error "ERROR: npm install failed: $_"
    exit 1
}

Pop-Location
Write-CustomLog "==== Frontend dependency installation complete ===="
} else {
    Write-CustomLog "InstallNpm flag is disabled. Skipping project dependency installation."
}
}
}
if ($MyInvocation.InvocationName -ne '.') { Install-NpmDependencies @PSBoundParameters }

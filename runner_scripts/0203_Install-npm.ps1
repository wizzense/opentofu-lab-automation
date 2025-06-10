Param([pscustomobject]$Config)

function Install-NpmDependencies {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([pscustomobject]$Config)

    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
    Invoke-LabStep -Config $Config -Body {
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

$nodeDeps = if ($Config -is [hashtable]) { $Config['Node_Dependencies'] } else { $Config.Node_Dependencies }
if (-not $nodeDeps) {
    Write-CustomLog "Config missing Node_Dependencies; skipping npm install."
    return
}

if ($nodeDeps.InstallNpm) {

# Determine frontend path
$frontendPath = if ($nodeDeps.NpmPath) {

    $nodeDeps.NpmPath
} else {
    Join-Path $PSScriptRoot "..\frontend"
}

if (-not (Test-Path $frontendPath)) {
    if ($nodeDeps.CreateNpmPath) {
        Write-CustomLog "Creating missing frontend folder at: $frontendPath"
        if ($PSCmdlet.ShouldProcess($frontendPath, 'Create NpmPath')) {
            New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null
        }
    } else {
        Write-CustomLog "Frontend folder not found at: $frontendPath. Skipping npm install."
        return
    }
}

if (-not (Test-Path (Join-Path $frontendPath "package.json"))) {
    Write-CustomLog "No package.json found in $frontendPath. Skipping npm install."
    return
}

Push-Location $frontendPath

try {
    Write-CustomLog "Running npm install in $frontendPath ..."

    if ($PSCmdlet.ShouldProcess($frontendPath, 'Run npm install')) {
        npm install
    }
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

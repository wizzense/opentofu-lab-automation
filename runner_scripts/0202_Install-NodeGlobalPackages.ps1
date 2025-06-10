Param([pscustomobject]$Config)

function Install-GlobalPackage {
    [CmdletBinding(SupportsShouldProcess)]

    param(
        [string]$package
    )

    . "$PSScriptRoot/../runner_utility_scripts/Logger.ps1"

    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-CustomLog "Installing npm package: $package..."
        if ($PSCmdlet.ShouldProcess($package, 'Install npm package') -and -not $WhatIfPreference) {
            npm install -g $package
        }
    } else {
        Write-Error "npm is not available. Node.js may not have installed correctly."
    }
}

function Install-NodeGlobalPackages {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([pscustomobject]$Config)

    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
    Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0202_Install-NodeGlobalPackages.ps1'
<#
.SYNOPSIS
    Installs global npm packages like yarn, vite, and nodemon using config-based logic.

.DESCRIPTION
    - Assumes Node.js is already installed
    - Installs any npm packages flagged as true in the Node_Dependencies section
    - Must be used in combination with 0201-InstallNodeCore.ps1

.CONFIG FORMAT
{
  "Node_Dependencies": {
    "InstallYarn": true,
    "InstallVite": true,
    "InstallNodemon": true
  }
}

.PARAMETER Config
    Hashed config object passed from runner.ps1

.EXAMPLE
    .\0202_Install-NodeGlobalPackages.ps1 -Config $Config
#>

Write-Output "Config parameter is: $Config"

Write-CustomLog "==== [0202] Installing Global npm Packages ===="

$nodeDeps = if ($Config -is [hashtable]) { $Config['Node_Dependencies'] } else { $Config.Node_Dependencies }
if (-not $nodeDeps) {
    Write-CustomLog "Config missing Node_Dependencies; skipping global package install."
    return
}

$packages = @()

if ($nodeDeps -is [hashtable] -and $nodeDeps.ContainsKey('GlobalPackages')) {
    $packages = $nodeDeps['GlobalPackages']
} elseif ($nodeDeps.PSObject.Properties.Name -contains 'GlobalPackages') {
    $packages = $nodeDeps.GlobalPackages
}

if (-not $packages) {
    if ($nodeDeps -is [hashtable]) {
        if ($nodeDeps['InstallYarn']) { $packages += 'yarn' } else { Write-CustomLog "InstallYarn flag is disabled. Skipping yarn installation." }
        if ($nodeDeps['InstallVite']) { $packages += 'vite' } else { Write-CustomLog "InstallVite flag is disabled. Skipping vite installation." }
        if ($nodeDeps['InstallNodemon']) { $packages += 'nodemon' } else { Write-CustomLog "InstallNodemon flag is disabled. Skipping nodemon installation." }
    } else {
        if ($nodeDeps.InstallYarn) { $packages += 'yarn' } else { Write-CustomLog "InstallYarn flag is disabled. Skipping yarn installation." }
        if ($nodeDeps.InstallVite) { $packages += 'vite' } else { Write-CustomLog "InstallVite flag is disabled. Skipping vite installation." }
        if ($nodeDeps.InstallNodemon) { $packages += 'nodemon' } else { Write-CustomLog "InstallNodemon flag is disabled. Skipping nodemon installation." }
    }
}

foreach ($pkg in $packages) {
    Install-GlobalPackage $pkg
}

Write-CustomLog "==== Global npm package installation complete ===="
}
}
if ($MyInvocation.InvocationName -ne '.') { Install-NodeGlobalPackages @PSBoundParameters }

Param([pscustomobject]$Config)

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


function Install-GlobalPackage {
    [CmdletBinding(SupportsShouldProcess)]
    
    param(
        [string]$package
    )

    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-CustomLog "Installing npm package: $package..."
        if ($PSCmdlet.ShouldProcess($package, 'Install npm package')) {
            npm install -g $package
        }
    } else {
        Write-Error "npm is not available. Node.js may not have installed correctly."
    }
}

Write-CustomLog "==== [0202] Installing Global npm Packages ===="

if ($Config -is [hashtable]) {
    if (-not $Config.ContainsKey('Node_Dependencies')) {
        Write-CustomLog "Config missing Node_Dependencies; skipping global package install."
        return
    }
} elseif (-not $Config.PSObject.Properties.Match('Node_Dependencies')) {
    Write-CustomLog "Config missing Node_Dependencies; skipping global package install."
    return
}

$packages = @()
if ($Config.Node_Dependencies.PSObject.Properties.Name -contains 'GlobalPackages') {
    $packages = $Config.Node_Dependencies.GlobalPackages
} else {
    if ($Config.Node_Dependencies.InstallYarn) {
        $packages += 'yarn'
    } else {
        Write-CustomLog "InstallYarn flag is disabled. Skipping yarn installation."
    }

    if ($Config.Node_Dependencies.InstallVite) {
        $packages += 'vite'
    } else {
        Write-CustomLog "InstallVite flag is disabled. Skipping vite installation."
    }

    if ($Config.Node_Dependencies.InstallNodemon) {
        $packages += 'nodemon'
    } else {
        Write-CustomLog "InstallNodemon flag is disabled. Skipping nodemon installation."
    }
}

foreach ($pkg in $packages) {
    Install-GlobalPackage $pkg
}

Write-CustomLog "==== Global npm package installation complete ===="
}
}
if ($MyInvocation.InvocationName -ne '.') { Install-NodeGlobalPackages @PSBoundParameters }

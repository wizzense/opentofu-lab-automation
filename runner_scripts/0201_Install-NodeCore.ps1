Param([pscustomobject]$Config)

function Install-NodeCore {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([pscustomobject]$Config)

    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
    Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0201_Install-NodeCore.ps1'
<#
.SYNOPSIS
    Installs Node.js via MSI, using the existing config framework.

.DESCRIPTION
    Downloads Node.js installer and installs silently.
    Uses config.Node_Dependencies.Node.InstallerUrl if specified.

.PARAMETER Config
    Hashed config object passed from runner.ps1

.EXAMPLE
    .\0201_Install-NodeCore.ps1 -Config $Config
#>

Write-Output "Config parameter is: $Config"


Write-CustomLog "==== [0201] Installing Node.js Core ===="

$nodeDeps = if ($Config -is [hashtable]) { $Config['Node_Dependencies'] } else { $Config.Node_Dependencies }
if (-not $nodeDeps) {
    Write-CustomLog "Config missing Node_Dependencies; skipping Node.js installation."
    return
}

if ($nodeDeps.InstallNode) {
    try {
        $url = if ($nodeDeps.Node.InstallerUrl) {
            $nodeDeps.Node.InstallerUrl
        } else {
            "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
        }

        $installerPath = Join-Path $env:TEMP "node-installer.msi"
        Write-CustomLog "Downloading Node.js from: $url"
        Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing

        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -NoNewWindow
        Remove-Item $installerPath -Force

        if (Get-Command node -ErrorAction SilentlyContinue) {
            Write-CustomLog "Node.js installed successfully."
            node -v
        } else {
            Write-Error "Node.js installation failed."
            exit 1
        }
    } catch {
        Write-Warning "Failed to install Node.js: $_"
    }
} else {
    Write-CustomLog "InstallNode flag is disabled. Skipping Node.js installation."
}
}
}
if ($MyInvocation.InvocationName -ne '.') { Install-NodeCore @PSBoundParameters }

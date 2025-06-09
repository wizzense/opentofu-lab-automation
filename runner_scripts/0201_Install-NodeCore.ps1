Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
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

if ($Config.Node_Dependencies.InstallNode) {
    $url = if ($Config.Node_Dependencies.Node.InstallerUrl) {
        $Config.Node_Dependencies.Node.InstallerUrl
    } else {
        "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
    }

    $installerPath = Join-Path $env:TEMP "node-installer.msi"
    Write-CustomLog "Downloading Node.js from: $url"
    Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing

    Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -NoNewWindow
    Remove-Item $installerPath -Force

    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-CustomLog "✅Node.js installed successfully."
        node -v
    } else {
        Write-Error "Node.js installation failed."
        exit 1
    }
} else {
    Write-CustomLog "InstallNode flag is disabled. Skipping Node.js installation."
}
}

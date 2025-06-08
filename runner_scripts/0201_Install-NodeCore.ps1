<#
.SYNOPSIS
    Installs Node.js via MSI, using the existing config framework.

.DESCRIPTION
    Downloads Node.js installer and installs silently.
    Uses config.Dependencies.Node.InstallerUrl if specified.

.PARAMETER Config
    Hashed config object passed from runner.ps1

.EXAMPLE
    .\0201_Install-NodeCore.ps1 -Config $Config
#>

param(
    [Parameter(Mandatory)]
    [hashtable]$Config
)

$ErrorActionPreference = "Stop"

Write-Host "==== [0201] Installing Node.js Core ===="

$url = if ($Config.Dependencies.Node.InstallerUrl) {
    $Config.Dependencies.Node.InstallerUrl
} else {
    "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
}

$installerPath = Join-Path $env:TEMP "node-installer.msi"
Write-Host "Downloading Node.js from: $url"
Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing

Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -NoNewWindow
Remove-Item $installerPath -Force

if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "✅Node.js installed successfully."
    node -v
} else {
    Write-Error "Node.js installation failed."
    exit 1
}

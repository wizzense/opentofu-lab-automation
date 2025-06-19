<#
.SYNOPSIS
    Super quick CoreApp launcher - minimal typing required

.DESCRIPTION
    Ultra-short script name for fast CoreApp relaunching.
    Just type: .\go.ps1

.EXAMPLE
    .\go.ps1

.EXAMPLE
    .\go.ps1 -Force
#>

[CmdletBinding()]
param([switch]$Force)

Write-Host "⚡ Quick launching CoreApp..." -ForegroundColor Yellow

# Use the comprehensive relaunch script
if (Test-Path ".\Relaunch-CoreApp.ps1") {
    & ".\Relaunch-CoreApp.ps1" -Force:$Force
} elseif (Test-Path ".\Start-CoreApp.ps1") {
    & ".\Start-CoreApp.ps1" -Force:$Force
} else {
    Write-Error "No CoreApp launcher found. Run .\kicker-git.ps1 first."
}

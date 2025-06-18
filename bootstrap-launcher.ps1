<#
.SYNOPSIS
    Minimal web launcher for OpenTofu Lab Automation bootstrap.

.DESCRIPTION
    This is a minimal script that downloads and executes the full bootstrap script.
    It's designed to be used in one-liner web downloads for quick setup.

.PARAMETER Branch
    The branch to download from (default: main).

.PARAMETER ConfigFile
    Path to custom configuration file to pass to the bootstrap script.

.PARAMETER Arguments
    Additional arguments to pass to the full bootstrap script.

.EXAMPLE
    # One-liner download and execute
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/bootstrap-launcher.ps1' -OutFile '.\bootstrap-launcher.ps1'; .\bootstrap-launcher.ps1"

.EXAMPLE
    # Download and run with custom branch
    .\bootstrap-launcher.ps1 -Branch "develop"

.EXAMPLE
    # Download and run with custom config and non-interactive mode
    .\bootstrap-launcher.ps1 -ConfigFile "my-config.json" -Arguments "-NonInteractive", "-Verbosity", "detailed"
#>

[CmdletBinding()]
param(
    [string]$Branch = 'main',
    [string]$ConfigFile,
    [string[]]$Arguments = @()
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Constants
$RepoUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation'
$BootstrapUrl = "$RepoUrl/$Branch/kicker-git.ps1"

Write-Host "OpenTofu Lab Automation - Bootstrap Launcher" -ForegroundColor Green
Write-Host "Downloading bootstrap script from: $BootstrapUrl" -ForegroundColor Cyan

try {
    # Download the full bootstrap script
    $tempPath = [System.IO.Path]::GetTempPath()
    $bootstrapScript = Join-Path $tempPath "opentofu-lab-bootstrap-$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    
    Invoke-WebRequest -Uri $BootstrapUrl -OutFile $bootstrapScript -UseBasicParsing
    
    Write-Host "✓ Bootstrap script downloaded successfully" -ForegroundColor Green
    Write-Host "Executing bootstrap script..." -ForegroundColor Cyan
    
    # Prepare arguments
    $scriptArgs = @()
    
    if ($ConfigFile) {
        $scriptArgs += @('-ConfigFile', $ConfigFile)
    }
    
    if ($Arguments) {
        $scriptArgs += $Arguments
    }
    
    # Execute the full bootstrap script
    & $bootstrapScript @scriptArgs
    
    # Cleanup
    Remove-Item $bootstrapScript -ErrorAction SilentlyContinue
    
    Write-Host "✓ Bootstrap completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Bootstrap failed: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($bootstrapScript -and (Test-Path $bootstrapScript)) {
        Remove-Item $bootstrapScript -ErrorAction SilentlyContinue
    }
    
    exit 1
}

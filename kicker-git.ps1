#Requires -Version 7.0

<#
.SYNOPSIS
    Entry point script for OpenTofu Lab Automation bootstrap process
    
.DESCRIPTION
    This script downloads and executes the main kicker-bootstrap.ps1 from the repository.
    It serves as the public entry point that users will download and run.
    
.PARAMETER ConfigFile
    Optional path to a custom configuration file
    
.PARAMETER Quiet
    Run in quiet mode with minimal output
    
.PARAMETER WhatIf
    Show what would be done without actually doing it
    
.PARAMETER NonInteractive
    Run without user prompts (for automation)
    
.PARAMETER Verbosity
    Set the verbosity level: silent, normal, or detailed
    
.EXAMPLE
    .\kicker-git.ps1
    
.EXAMPLE
    .\kicker-git.ps1 -ConfigFile "custom-config.json" -Verbosity detailed
    
.NOTES
    This is the public entry point for the OpenTofu Lab Automation project.
    It will download the latest kicker-bootstrap.ps1 and execute it.
#>

param(
    [string]$ConfigFile,
    [switch]$Quiet,
    [switch]$WhatIf,
    [switch]$NonInteractive,
    [ValidateSet('silent','normal','detailed')]
    [string]$Verbosity = 'normal'
)

# Configuration
$ErrorActionPreference = 'Stop'
$targetBranch = 'main'
$baseUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/'
$bootstrapScript = "${baseUrl}${targetBranch}/core-runner/kicker-bootstrap.ps1"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    if ($Quiet -and $Verbosity -ne 'detailed') { return }
    Write-Host $Message -ForegroundColor $Color
}

# Function to get cross-platform temp path
function Get-CrossPlatformTempPath {
    if ($env:TEMP) {
        return $env:TEMP
    } else {
        return [System.IO.Path]::GetTempPath()
    }
}

# Main execution
try {
    Write-ColorOutput "OpenTofu Lab Automation - Kicker Script" "Cyan"
    Write-ColorOutput "=======================================" "Cyan"
    Write-ColorOutput ""
    
    if ($WhatIf) {
        Write-ColorOutput "WHAT-IF MODE: Would download and execute:" "Yellow"
        Write-ColorOutput "  Source: $bootstrapScript" "Yellow"
        Write-ColorOutput "  Parameters: ConfigFile=$ConfigFile, Quiet=$Quiet, NonInteractive=$NonInteractive, Verbosity=$Verbosity" "Yellow"
        return
    }
    
    # Download the bootstrap script
    $tempPath = Get-CrossPlatformTempPath
    $localBootstrap = Join-Path $tempPath "kicker-bootstrap.ps1"
    
    Write-ColorOutput "Downloading bootstrap script..." "Green"
    Write-ColorOutput "  From: $bootstrapScript" "Gray"
    Write-ColorOutput "  To: $localBootstrap" "Gray"
    
    # Use appropriate download method
    if (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue) {
        Invoke-WebRequest -Uri $bootstrapScript -OutFile $localBootstrap -UseBasicParsing
    } elseif (Get-Command curl -ErrorAction SilentlyContinue) {
        & curl -L -o $localBootstrap $bootstrapScript
    } elseif (Get-Command wget -ErrorAction SilentlyContinue) {
        & wget -O $localBootstrap $bootstrapScript
    } else {
        throw "No suitable download tool found (Invoke-WebRequest, curl, or wget)"
    }
    
    if (-not (Test-Path $localBootstrap)) {
        throw "Failed to download bootstrap script"
    }
    
    Write-ColorOutput "Bootstrap script downloaded successfully" "Green"
    Write-ColorOutput "Executing bootstrap script..." "Green"
    Write-ColorOutput ""
    
    # Prepare parameters for the bootstrap script
    $params = @{}
    if ($ConfigFile) { $params['ConfigFile'] = $ConfigFile }
    if ($Quiet) { $params['Quiet'] = $true }
    if ($NonInteractive) { $params['NonInteractive'] = $true }
    if ($Verbosity -ne 'normal') { $params['Verbosity'] = $Verbosity }
    
    # Execute the bootstrap script
    & $localBootstrap @params
    
    Write-ColorOutput ""
    Write-ColorOutput "Bootstrap process completed" "Green"
    
} catch {
    Write-ColorOutput ""
    Write-ColorOutput "ERROR: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Stack trace:" "Red"
    Write-ColorOutput $_.ScriptStackTrace "Red"
    exit 1
} finally {
    # Clean up temp file
    if ($localBootstrap -and (Test-Path $localBootstrap)) {
        try {
            Remove-Item $localBootstrap -Force -ErrorAction SilentlyContinue
        } catch {
            # Ignore cleanup errors
        }
    }
}

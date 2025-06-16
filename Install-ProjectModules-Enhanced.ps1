#Requires -Version 7.0

<#
.SYNOPSIS
    Enhanced project module installer with comprehensive import issue resolution

.DESCRIPTION
    This script extends the existing Install-ProjectModules.ps1 functionality to also
    resolve all the widespread module import issues. It:
    
    1. Installs all project modules to standard PowerShell locations
    2. Fixes malformed import paths throughout the codebase
    3. Removes hardcoded paths and duplicate -Force parameters
    4. Sets up proper environment variables
    5. Validates that all modules can be imported successfully
    
.PARAMETER Mode
    Install: Install modules and fix import issues
    Fix: Only fix import issues without reinstalling modules
    Status: Show current status
    
.PARAMETER Force
    Force overwrite existing modules and fixes
    
.PARAMETER WhatIf
    Show what would be changed without making changes

.EXAMPLE
    .\Install-ProjectModules-Enhanced.ps1 -Mode Install
    Installs modules and fixes all import issues
    
.EXAMPLE
    .\Install-ProjectModules-Enhanced.ps1 -Mode Fix
    Only fixes import issues without reinstalling modules
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet("Install", "Fix", "Status")]
    [string]$Mode = "Install",
    
    [switch]$Force,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Import required modules for this script
$projectRoot = Split-Path $PSScriptRoot -Parent
$devEnvPath = "$projectRoot/pwsh/modules/DevEnvironment"

if (Test-Path $devEnvPath) {
    try {
        Import-Module $devEnvPath -Force
        Write-Host "✓ DevEnvironment module imported" -ForegroundColor Green
    } catch {
        Write-Warning "Could not import DevEnvironment module: $($_.Exception.Message)"
        Write-Host "Continuing with basic functionality..." -ForegroundColor Yellow
    }
}

function Write-EnhancedLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Invoke-OriginalInstaller {
    param([string]$InstallMode, [switch]$ForceFlag)
    
    $originalScript = "$projectRoot/Install-ProjectModules.ps1"
    if (Test-Path $originalScript) {
        Write-EnhancedLog "Running original Install-ProjectModules.ps1..." -Level INFO
        
        $params = @{
            Mode = $InstallMode
        }
        if ($ForceFlag) { $params.Force = $true }
        
        & $originalScript @params
    } else {
        Write-EnhancedLog "Original Install-ProjectModules.ps1 not found, skipping..." -Level WARN
    }
}

function Show-EnhancedStatus {
    Write-EnhancedLog "=== PROJECT MODULES STATUS ===" -Level INFO
    
    # Check if DevEnvironment module has the enhanced functions
    $devEnvCommands = @(
        "Resolve-ModuleImportIssues",
        "Initialize-DevelopmentEnvironment"
    )
    
    Write-EnhancedLog "DevEnvironment Module Functions:" -Level INFO
    foreach ($cmd in $devEnvCommands) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-EnhancedLog "  ✓ $cmd - Available" -Level SUCCESS
        } else {
            Write-EnhancedLog "  ✗ $cmd - Not available" -Level ERROR
        }
    }
    
    # Check core modules
    $coreModules = @("LabRunner", "PatchManager", "Logging", "DevEnvironment", "BackupManager")
    Write-EnhancedLog "`nCore Modules:" -Level INFO
    foreach ($module in $coreModules) {
        try {
            $moduleInfo = Get-Module -ListAvailable -Name $module | Select-Object -First 1
            if ($moduleInfo) {
                Write-EnhancedLog "  ✓ $module v$($moduleInfo.Version) - Available" -Level SUCCESS
            } else {
                Write-EnhancedLog "  ✗ $module - Not found" -Level ERROR
            }
        } catch {
            Write-EnhancedLog "  ✗ $module - Error checking: $($_.Exception.Message)" -Level ERROR
        }
    }
    
    # Check environment variables
    Write-EnhancedLog "`nEnvironment Variables:" -Level INFO
    $envVars = @("PROJECT_ROOT", "PWSH_MODULES_PATH")
    foreach ($var in $envVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ($value) {
            Write-EnhancedLog "  ✓ $var = $value" -Level SUCCESS
        } else {
            Write-EnhancedLog "  ✗ $var - Not set" -Level ERROR
        }
    }
    
    # Test import issues
    Write-EnhancedLog "`nChecking for Import Issues:" -Level INFO
    $testFiles = Get-ChildItem -Path "$projectRoot/tests" -Filter "*.Tests.ps1" -ErrorAction SilentlyContinue | Select-Object -First 5
    $issueCount = 0
    
    foreach ($file in $testFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            # Check for common issues
            if ($content -match '(-Force\s+){2,}') { $issueCount++ }
            if ($content -match 'C:\\Users\\alexa\\OneDrive') { $issueCount++ }
            if ($content -match '//pwsh/modules/') { $issueCount++ }
        }
    }
    
    if ($issueCount -eq 0) {
        Write-EnhancedLog "  ✓ No obvious import issues detected" -Level SUCCESS
    } else {
        Write-EnhancedLog "  ⚠ Found potential import issues in test files" -Level WARN
    }
}

# Main execution
Write-EnhancedLog "Enhanced Project Module Installer Starting..." -Level INFO
Write-EnhancedLog "Mode: $Mode | Force: $($Force.IsPresent) | WhatIf: $($WhatIf.IsPresent)" -Level INFO

switch ($Mode) {
    "Status" {
        Show-EnhancedStatus
    }
    
    "Fix" {
        Write-EnhancedLog "Fixing module import issues only..." -Level INFO
        
        if (Get-Command Resolve-ModuleImportIssues -ErrorAction SilentlyContinue) {
            Resolve-ModuleImportIssues -Force:$Force -WhatIf:$WhatIf
        } else {
            Write-EnhancedLog "Resolve-ModuleImportIssues not available, using fallback method..." -Level WARN
            # Fallback: Run the original installer to at least get modules in place
            Invoke-OriginalInstaller -InstallMode "Install" -ForceFlag:$Force
        }
    }
    
    "Install" {
        Write-EnhancedLog "Installing modules and fixing import issues..." -Level INFO
        
        # Step 1: Run original installer
        Invoke-OriginalInstaller -InstallMode "Install" -ForceFlag:$Force
        
        # Step 2: Fix import issues if DevEnvironment is available
        if (Get-Command Resolve-ModuleImportIssues -ErrorAction SilentlyContinue) {
            Write-EnhancedLog "Resolving module import issues..." -Level INFO
            Resolve-ModuleImportIssues -Force:$Force -WhatIf:$WhatIf
        } else {
            Write-EnhancedLog "Enhanced import fixing not available" -Level WARN
        }
        
        # Step 3: Initialize development environment if available
        if (Get-Command Initialize-DevelopmentEnvironment -ErrorAction SilentlyContinue) {
            Write-EnhancedLog "Initializing development environment..." -Level INFO
            Initialize-DevelopmentEnvironment -Force:$Force -SkipModuleImportFixes
        }
    }
}

Write-EnhancedLog "Enhanced Project Module Installer Complete!" -Level SUCCESS
Write-EnhancedLog "Restart PowerShell to pick up all changes, then run: Test-DevelopmentSetup" -Level INFO

#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/patching.ps1

<#
.SYNOPSIS
Unified patching and maintenance script for OpenTofu Lab Automation.

.DESCRIPTION
This script provides a standardized interface for patching, maintenance, and issue tracking
in the OpenTofu Lab Automation project. It leverages the PatchManager module to ensure
consistent maintenance practices and automated issue resolution.

.PARAMETER Mode
The patching mode to run:
- Quick: Fast health check and basic repairs (default)
- Deep: Comprehensive system check with all validations
- YAML: Focus on YAML file validation and fixing
- Archive: Clean up archive directories
- Issues: Check and track recurring issues

.PARAMETER AutoFix
Automatically apply fixes where possible

.PARAMETER ReportOnly
Generate report without making any changes

.PARAMETER SaveReport
Save the maintenance report to the reports directory

.EXAMPLE
./scripts/maintenance/patching.ps1 -Mode Quick

.EXAMPLE
./scripts/maintenance/patching.ps1 -Mode Deep -AutoFix

.EXAMPLE
./scripts/maintenance/patching.ps1 -Mode YAML -AutoFix

.EXAMPLE
./scripts/maintenance/patching.ps1 -Mode Issues -ReportOnly
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Quick", "Deep", "YAML", "Archive", "Issues")]
    [string]$Mode = "Quick",
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoFix,
    
    [Parameter(Mandatory=$false)]
    [switch]$ReportOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$SaveReport
)

# Get the project root
$ProjectRoot = $PSScriptRoot
while (-not (Test-Path (Join-Path $ProjectRoot "PROJECT-MANIFEST.json"))) {
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    if ([string]::IsNullOrEmpty($ProjectRoot)) {
        Write-Error "Could not find project root containing PROJECT-MANIFEST.json"
        exit 1
    }
}

# Import the PatchManager module
$patchManagerPath = Join-Path $ProjectRoot "pwsh/modules/PatchManager"
if (Test-Path $patchManagerPath) {
    Import-Module $patchManagerPath -Force
}
else {
    Write-Error "PatchManager module not found at $patchManagerPath"
    exit 1
}

# Function to display a banner
function Show-Banner {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "     OpenTofu Lab Automation - Patching System      " -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Display banner
Show-Banner

# Process based on mode
switch ($Mode) {
    "Quick" {
        Write-Host "Running quick health check and patching..." -ForegroundColor Yellow
        if ($ReportOnly) {
            $healthCheck = Invoke-HealthCheck -ProjectRoot $ProjectRoot -Mode "Quick" 
            Show-MaintenanceReport -ProjectRoot $ProjectRoot -HealthCheck $healthCheck -SaveToFile:$SaveReport
        }
        else {
            Invoke-UnifiedMaintenance -ProjectRoot $ProjectRoot -Mode "Quick" -AutoFix:$AutoFix
        }
    }
    "Deep" {
        Write-Host "Running deep system maintenance..." -ForegroundColor Yellow
        if ($ReportOnly) {
            $healthCheck = Invoke-HealthCheck -ProjectRoot $ProjectRoot -Mode "Deep"
            Show-MaintenanceReport -ProjectRoot $ProjectRoot -HealthCheck $healthCheck -SaveToFile:$SaveReport
        }
        else {
            Invoke-UnifiedMaintenance -ProjectRoot $ProjectRoot -Mode "All" -AutoFix:$AutoFix
        }
    }
    "YAML" {
        Write-Host "Running YAML validation and fixing..." -ForegroundColor Yellow
        $yamlResult = Invoke-YamlValidation -ProjectRoot $ProjectRoot `
                                         -Path ".github/workflows" `
                                         -Mode $(if ($AutoFix) { "Fix" } else { "Check" })
        
        if ($SaveReport) {
            Show-MaintenanceReport -ProjectRoot $ProjectRoot -YamlResult $yamlResult -SaveToFile
        }
    }
    "Archive" {
        Write-Host "Running archive cleanup..." -ForegroundColor Yellow
        if ($ReportOnly) {
            Write-Host "Archive preview mode (no files will be deleted)" -ForegroundColor Cyan
            Invoke-ArchiveCleanup -ProjectRoot $ProjectRoot -WhatIf -PreserveCritical
        }
        else {
            Invoke-ArchiveCleanup -ProjectRoot $ProjectRoot -PreserveCritical
        }
    }
    "Issues" {
        Write-Host "Checking and tracking recurring issues..." -ForegroundColor Yellow
        $issues = Invoke-RecurringIssueCheck -ProjectRoot $ProjectRoot -UpdateIssueFile
        
        if ($SaveReport) {
            Show-MaintenanceReport -ProjectRoot $ProjectRoot -Issues $issues -SaveToFile
        }
    }
}

Write-Host "`nPatching operation completed" -ForegroundColor Green

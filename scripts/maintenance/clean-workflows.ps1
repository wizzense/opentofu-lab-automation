#!/usr/bin/env pwsh
# clean-workflows.ps1
# This script helps identify and archive redundant or unnecessary workflow files

param(
    switch$Archive,  # When set, moves redundant workflows to an archive folder
    switch$WhatIf    # Show what would happen without making changes
)








$ErrorActionPreference = 'Stop'

$workflowDir = Join-Path $PSScriptRoot ".github/workflows"
$archiveDir = Join-Path $PSScriptRoot ".github/workflows/archive"

# Core workflows that should be kept
$coreWorkflows = @(
    "unified-ci.yml",                 # Main CI workflow
    "comprehensive-health-monitor.yml", # Health monitoring
    "workflow-health-monitor.yml"     # Workflow health monitoring
)

# Ensure the directory exists
if (-not (Test-Path $workflowDir)) {
    Write-Error "Workflow directory not found: $workflowDir"
    exit 1
}

# Check if the archive directory exists, create it if needed and -Archive was specified
if ($Archive -and -not (Test-Path $archiveDir)) {
    if (-not $WhatIf) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
Write-Host "Created archive directory: $archiveDir" -ForegroundColor Green
    }
    else {
        Write-Host "Would create archive directory: $archiveDir" -ForegroundColor Yellow
    }
}

# Get all workflow files
$workflows = Get-ChildItem -Path $workflowDir -Filter "*.yml" | Where-Object{ $_.Name -ne ".gitkeep" }

Write-Host "Found $($workflows.Count) workflow files in $workflowDir" -ForegroundColor Cyan

$redundantWorkflows = @()

foreach ($workflow in $workflows) {
    if ($coreWorkflows -contains $workflow.Name) {
        Write-Host "Core workflow (keep): $($workflow.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "Non-core workflow (candidate for archive): $($workflow.Name)" -ForegroundColor Yellow
        $redundantWorkflows += $workflow
    }
}

Write-Host "`nFound $($redundantWorkflows.Count) workflow files that could be archived" -ForegroundColor Cyan

if ($redundantWorkflows.Count -gt 0 -and $Archive) {
    foreach ($workflow in $redundantWorkflows) {
        $destPath = Join-Path $archiveDir $workflow.Name
        
        if ($WhatIf) {
            Write-Host "Would archive: $($workflow.FullName) -> $destPath" -ForegroundColor Yellow
        }
        else {
            Move-Item -Path $workflow.FullName -Destination $destPath -Force
            Write-Host "Archived: $($workflow.Name) -> $archiveDir" -ForegroundColor Green
        }
    }
}

Write-Host "`nWorkflow cleanup complete." -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "No changes were made (WhatIf mode). Run with -Archive to apply changes." -ForegroundColor Yellow
}






#!/usr/bin/env pwsh
<#
.SYNOPSIS
Mark legacy workflows for archival and update the workflow structure

.DESCRIPTION
This script helps consolidate workflows by marking legacy ones for archival
and ensuring the new mega-consolidated workflow is properly set up.
#>

CmdletBinding()
param(
 switch$Execute,
 switch$WhatIf
)

$ErrorActionPreference = 'Stop'

Write-Host " Workflow Consolidation Script" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Workflows that can be safely archived/disabled
$LegacyWorkflows = @(
 "auto-test-generation.yml",
 "auto-test-generation-consolidated.yml", 
 "unified-ci.yml",
 "unified-testing.yml",
 "unified-utilities.yml",
 "system-health-monitor.yml"
)

# Workflows to keep
$KeepWorkflows = @(
 "mega-consolidated.yml",
 "validate-workflows.yml",
 "release.yml",
 "package-labctl.yml",
 "copilot-auto-fix.yml",
 "changelog.yml",
 "auto-merge.yml",
 "issue-on-fail.yml"
)

$WorkflowDir = ".github/workflows"

Write-Host "`n Analysis:" -ForegroundColor Yellow

if (Test-Path $WorkflowDir) {
 $AllWorkflows = Get-ChildItem "$WorkflowDir/*.yml" | ForEach-Object{ $_.Name }
 
 Write-Host "Total workflows found: $($AllWorkflows.Count)" -ForegroundColor Green
 Write-Host "Workflows to archive: $($LegacyWorkflows.Count)" -ForegroundColor Yellow
 Write-Host "Workflows to keep: $($KeepWorkflows.Count)" -ForegroundColor Green
 
 Write-Host "`n Legacy workflows to archive:" -ForegroundColor Red
 foreach ($workflow in $LegacyWorkflows) {
 if ($workflow -in $AllWorkflows) {
 Write-Host " FAIL $workflow" -ForegroundColor Red
 }
 }
 
 Write-Host "`nPASS Workflows to keep:" -ForegroundColor Green
 foreach ($workflow in $KeepWorkflows) {
 if ($workflow -in $AllWorkflows) {
 Write-Host " PASS $workflow" -ForegroundColor Green
 } else {
 Write-Host " WARN $workflow (not found)" -ForegroundColor Yellow
 }
 }
 
 if ($Execute -and -not $WhatIf) {
 Write-Host "`n Executing archival..." -ForegroundColor Cyan
 
 # Create archive directory
 $ArchiveDir = ".github/archived_workflows"
 if (-not (Test-Path $ArchiveDir)) {
 New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-NullWrite-Host "Created archive directory: $ArchiveDir" -ForegroundColor Green
 }
 
 # Move legacy workflows
 foreach ($workflow in $LegacyWorkflows) {
 $sourcePath = "$WorkflowDir/$workflow"
 $destPath = "$ArchiveDir/$workflow"
 
 if (Test-Path $sourcePath) {
 Move-Item $sourcePath $destPath -Force
 Write-Host "Archived: $workflow" -ForegroundColor Yellow
 }
 }
 
 # Create archive README
 $readmeContent = @"
# Archived Workflows

These workflows have been consolidated into the mega-consolidated workflow.
They are kept here for reference purposes only.

## Archived on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

 Original Workflow  Consolidated Into 
-------------------------------------
 auto-test-generation.yml  mega-consolidated.yml 
 auto-test-generation-consolidated.yml  mega-consolidated.yml 
 unified-ci.yml  mega-consolidated.yml 
 unified-testing.yml  mega-consolidated.yml 
 unified-utilities.yml  mega-consolidated.yml 
 system-health-monitor.yml  mega-consolidated.yml 

The new mega-consolidated workflow provides:
- All testing functionality
- Linting and validation
- Utilities and maintenance
- Health monitoring
- Issue creation
- Auto-merging

To restore any of these workflows, copy them back to .github/workflows/
"@
 
 Set-Content "$ArchiveDir/README.md" $readmeContent
 Write-Host "Created archive README" -ForegroundColor Green
 
 Write-Host "`nPASS Archival complete!" -ForegroundColor Green
 } else { Write-Host "`nWARN WHAT-IF MODE - No changes made" -ForegroundColor Yellow
 Write-Host "Use -Execute to actually archive workflows" -ForegroundColor Yellow
 }
} else {
 Write-Error "Workflow directory not found: $WorkflowDir"
}

Write-Host "`n Summary:" -ForegroundColor Cyan
Write-Host "The mega-consolidated workflow combines functionality from:" -ForegroundColor White
Write-Host "- CI/CD Pipeline (unified-ci.yml)" -ForegroundColor Gray
Write-Host "- Cross-Platform Testing (unified-testing.yml)" -ForegroundColor Gray
Write-Host "- Utilities & Maintenance (unified-utilities.yml)" -ForegroundColor Gray
Write-Host "- System Health Monitor (system-health-monitor.yml)" -ForegroundColor Gray
Write-Host "- Auto Test Generation (auto-test-generation*.yml)" -ForegroundColor Gray

Write-Host "`nThis reduces workflow complexity while maintaining all functionality." -ForegroundColor Green


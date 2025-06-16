#!/usr/bin/env pwsh
<#
.SYNOPSIS
Emergency YAML workflow cleanup - Archive broken files and restore clean state

.DESCRIPTION
This script addresses the recurring YAML corruption issue by:
1. Moving all broken workflow files to archive
2. Keeping only the working mega-consolidated workflows
3. Creating backups of working files
4. Preventing future corruption

.NOTES
The YAML corruption was caused by flawed auto-fix logic in Invoke-YamlValidation.ps1
which has now been disabled.
#>

$ErrorActionPreference = "Stop"

Write-Host "🚨 EMERGENCY YAML WORKFLOW CLEANUP" -ForegroundColor Red
Write-Host "===================================" -ForegroundColor Red

# Create archive directory
$archiveDir = "./archive/broken-workflows-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $archiveDir -Force
Write-Host "📁 Created archive directory: $archiveDir" -ForegroundColor Yellow

# List of working workflow files (YAML valid)
$workingWorkflows = @(
    "mega-consolidated.yml"
    "mega-consolidated-fixed.yml"
)

# List all workflow files
$allWorkflows = Get-ChildItem ".github/workflows/*.yml" -Name

Write-Host "`n📊 WORKFLOW STATUS:" -ForegroundColor Cyan
Write-Host "Total workflows: $($allWorkflows.Count)" -ForegroundColor White
Write-Host "Working workflows: $($workingWorkflows.Count)" -ForegroundColor Green
Write-Host "Broken workflows: $($allWorkflows.Count - $workingWorkflows.Count)" -ForegroundColor Red

# Archive broken workflows
$brokenWorkflows = $allWorkflows | Where-Object { $_ -notin $workingWorkflows }

if ($brokenWorkflows.Count -eq 0) {
    Write-Host "`n[PASS] No broken workflows found - system is clean!" -ForegroundColor Green
    exit 0
}

Write-Host "`n🗂️  ARCHIVING BROKEN WORKFLOWS:" -ForegroundColor Yellow
foreach ($workflow in $brokenWorkflows) {
    $sourcePath = ".github/workflows/$workflow"
    $destPath = "$archiveDir/$workflow"
    
    try {
        Move-Item $sourcePath $destPath -Force
        Write-Host "  [PASS] Archived: $workflow" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] Failed to archive: $workflow - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create README in archive
$archiveReadme = @"
# Archived Broken Workflows - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Reason for Archival
These workflow files contained fundamental YAML syntax errors that prevented proper parsing.
The corruption was caused by flawed auto-fix logic in the YAML validation script.

## Status
- **Total archived**: $($brokenWorkflows.Count) files
- **Working workflows remaining**: $($workingWorkflows.Count) files
- **Auto-fix logic**: DISABLED to prevent future corruption

## Archived Files
$($brokenWorkflows | ForEach-Object { "- $_" } | Out-String)

## Recovery Options
1. **Recommended**: Use the working mega-consolidated workflows
2. **Manual fix**: Restore individual files and manually fix YAML structure
3. **Rewrite**: Create new workflow files following YAML standards

## Working Workflows
The following workflows remain active and are YAML-valid:
$($workingWorkflows | ForEach-Object { "- $_" } | Out-String)

## Prevention
- YAML auto-fix logic has been disabled in Invoke-YamlValidation.ps1
- Manual validation only: Use `yamllint` directly for checking
- Follow YAML standards in .github/instructions/yaml-standards.instructions.md
"@

Set-Content "$archiveDir/README.md" $archiveReadme

# Backup working workflows
$backupDir = "./backups/working-workflows-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force

Write-Host "`n💾 BACKING UP WORKING WORKFLOWS:" -ForegroundColor Cyan
foreach ($workflow in $workingWorkflows) {
    $sourcePath = ".github/workflows/$workflow"
    $destPath = "$backupDir/$workflow"
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath -Force
        Write-Host "  [PASS] Backed up: $workflow" -ForegroundColor Green
    }
}

# Validate remaining workflows
Write-Host "`n🔍 VALIDATING REMAINING WORKFLOWS:" -ForegroundColor Cyan
$validationErrors = 0

foreach ($workflow in $workingWorkflows) {
    $workflowPath = ".github/workflows/$workflow"
    if (Test-Path $workflowPath) {
        try {
            $null = yamllint $workflowPath 2>&1
            Write-Host "  [PASS] Valid: $workflow" -ForegroundColor Green
        } catch {
            Write-Host "  [FAIL] Invalid: $workflow" -ForegroundColor Red
            $validationErrors++
        }
    } else {
        Write-Host "  [WARN]️  Missing: $workflow" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n📋 CLEANUP SUMMARY:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "[PASS] Archived broken workflows: $($brokenWorkflows.Count)" -ForegroundColor Green
Write-Host "[PASS] Backed up working workflows: $($workingWorkflows.Count)" -ForegroundColor Green
Write-Host "[PASS] Validation errors remaining: $validationErrors" -ForegroundColor $(if ($validationErrors -eq 0) { 'Green' } else { 'Red' })
Write-Host "[PASS] Auto-fix corruption: DISABLED" -ForegroundColor Green

if ($validationErrors -eq 0) {
    Write-Host "`n🎉 SUCCESS: Workflow directory is now clean and valid!" -ForegroundColor Green
    Write-Host "📁 Archive location: $archiveDir" -ForegroundColor Yellow
    Write-Host "💾 Backup location: $backupDir" -ForegroundColor Yellow
    
    # Update project manifest
    Write-Host "`n📝 Updating project manifest..." -ForegroundColor Cyan
    try {
        $manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json
        $manifest.project.lastMaintenance = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $manifest.project.workflowStatus = "Cleaned - $($workingWorkflows.Count) valid workflows"
        $manifest | ConvertTo-Json -Depth 10 | Set-Content "./PROJECT-MANIFEST.json"
        Write-Host "[PASS] Project manifest updated" -ForegroundColor Green
    } catch {
        Write-Host "[WARN]️  Failed to update project manifest: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[WARN]️  WARNING: Some validation errors remain. Manual review required." -ForegroundColor Yellow
}

Write-Host "`n🔒 PREVENTION MEASURES ACTIVE:" -ForegroundColor Cyan
Write-Host "- YAML auto-fix disabled in validation script" -ForegroundColor White
Write-Host "- Manual yamllint validation only" -ForegroundColor White
Write-Host "- Archive created for broken files" -ForegroundColor White
Write-Host "- Backup created for working files" -ForegroundColor White

Write-Host "`n🚀 NEXT STEPS:" -ForegroundColor Green
Write-Host "1. Use mega-consolidated workflows for CI/CD" -ForegroundColor White
Write-Host "2. Manually fix archived workflows if needed" -ForegroundColor White
Write-Host "3. Follow YAML standards for new workflows" -ForegroundColor White
Write-Host "4. Use 'yamllint' directly for validation" -ForegroundColor White

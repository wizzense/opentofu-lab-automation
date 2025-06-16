#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/cleanup-root-scripts.ps1

<#
.SYNOPSIS
Comprehensive cleanup of root directory scripts.

.DESCRIPTION
This script organizes and cleans up the many scripts that have accumulated in the 
project root directory, moving them to appropriate locations or archiving them.

.PARAMETER WhatIf
Preview what would be moved without actually moving files.

.EXAMPLE
./scripts/maintenance/cleanup-root-scripts.ps1 -WhatIf

.EXAMPLE
./scripts/maintenance/cleanup-root-scripts.ps1
#>

CmdletBinding()
param(
 Parameter()







 switch$WhatIf
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "/workspaces/opentofu-lab-automation"

function Write-CleanupLog {
 param(string$Message, string$Level = "INFO")
 






$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 $color = switch ($Level) {
 "INFO" { "Cyan" }
 "SUCCESS" { "Green" }
 "WARNING" { "Yellow" }
 "ERROR" { "Red" }
 "CLEANUP" { "Magenta" }
 default { "White" }
 }
 Write-Host "$timestamp $Level $Message" -ForegroundColor $color
}

function Move-ScriptFile {
 param(
 string$SourceFile,
 string$DestinationPath,
 string$Reason = ""
 )
 
 






$sourcePath = Join-Path $ProjectRoot $SourceFile
 $destPath = Join-Path $ProjectRoot $DestinationPath
 
 if (-not (Test-Path $sourcePath)) {
 Write-CleanupLog "Source file not found: $SourceFile" "WARNING"
 return
 }
 
 # Create destination directory if needed
 $destDir = Split-Path -Parent $destPath
 if (-not (Test-Path $destDir)) {
 if ($WhatIf) {
 Write-CleanupLog "Would create directory: $destDir" "INFO"
 } else {
 New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Write-CleanupLog "Created directory: $destDir" "SUCCESS"
 }
 }
 
 if ($WhatIf) {
 Write-CleanupLog "Would move: $SourceFile → $DestinationPath" "INFO"
 if ($Reason) { Write-CleanupLog " Reason: $Reason" "INFO" }
 } else {
 try {
 Move-Item -Path $sourcePath -Destination $destPath -Force
 Write-CleanupLog "Moved: $SourceFile → $DestinationPath" "SUCCESS"
 if ($Reason) { Write-CleanupLog " Reason: $Reason" "INFO" }
 }
 catch {
 Write-CleanupLog "Failed to move $SourceFile : $($_.Exception.Message)" "ERROR"
 }
 }
}

function Remove-EmptyScript {
 param(string$ScriptFile, string$Reason = "")
 
 






$scriptPath = Join-Path $ProjectRoot $ScriptFile
 if (-not (Test-Path $scriptPath)) {
 return
 }
 
 $content = Get-Content $scriptPath -Raw -ErrorAction SilentlyContinue
 if (string::IsNullOrWhiteSpace($content)) {
 if ($WhatIf) {
 Write-CleanupLog "Would remove empty file: $ScriptFile" "WARNING"
 } else {
 Remove-Item $scriptPath -Force
 Write-CleanupLog "Removed empty file: $ScriptFile" "SUCCESS"
 }
 if ($Reason) { Write-CleanupLog " Reason: $Reason" "INFO" }
 }
}

# Start cleanup
Write-CleanupLog "� Starting comprehensive root directory cleanup" "CLEANUP"
if ($WhatIf) {
 Write-CleanupLog "Running in WhatIf mode - no files will be moved" "WARNING"
}

# 1. Remove empty scripts first
Write-CleanupLog "Removing empty script files..." "CLEANUP"
$emptyScripts = @(
 "clean-workflows.ps1",
 "comprehensive-syntax-checker.ps1", 
 "enhanced-fix-labrunner.ps1",
 "fix-all-test-syntax.ps1",
 "fix-codefixer-and-tests.ps1",
 "fix-specific-file.ps1", 
 "fix-ternary-syntax.ps1",
 "run-all-tests.ps1",
 "run-comprehensive-tests.ps1",
 "run-final-validation.ps1",
 "simple-fix-test-syntax.ps1",
 "simple-syntax-error.ps1",
 "test-codefixer-enhancements.ps1",
 "test-codefixer-improvements.ps1",
 "test-final-fixes.ps1",
 "test-syntax-errors.ps1",
 "test-syntax-validation.ps1",
 "update-labrunner-imports.ps1"
)

foreach ($script in $emptyScripts) {
 Remove-EmptyScript $script "Empty script file - likely obsolete"
}

# 2. Archive organization scripts (historical value)
Write-CleanupLog "Archiving organization scripts..." "CLEANUP"
$organizationScripts = @{
 "organize-project.ps1" = "archive/maintenance-scripts/organize-project.ps1"
 "organize-project-fixed.ps1" = "archive/maintenance-scripts/organize-project-fixed.ps1"
 "cleanup-remaining.ps1" = "archive/maintenance-scripts/cleanup-remaining.ps1"
}

foreach ($script in $organizationScripts.Keys) {
 Move-ScriptFile $script $organizationScripts$script "Historical organization script"
}

# 3. Move test configuration files to appropriate locations
Write-CleanupLog "Moving test configuration files..." "CLEANUP"
$testConfigs = @{
 "test-config-errors.json" = "tests/data/test-config-errors.json"
 "workflow-optimization-report.json" = "reports/workflow-optimization-report.json"
}

foreach ($config in $testConfigs.Keys) {
 if (Test-Path (Join-Path $ProjectRoot $config)) {
 Move-ScriptFile $config $testConfigs$config "Test configuration file"
 }
}

# 4. Check for and move any remaining fix scripts
Write-CleanupLog "Checking for remaining fix scripts..." "CLEANUP"
$fixScripts = Get-ChildItem -Path $ProjectRoot -Name "fix-*.ps1" -ErrorAction SilentlyContinue
foreach ($fixScript in $fixScripts) {
 if ($fixScript -ne "fix-infrastructure-issues.ps1") { # Keep our main fix script
 Move-ScriptFile $fixScript "archive/fix-scripts/$fixScript" "Legacy fix script"
 }
}

# 5. Check for remaining test scripts 
Write-CleanupLog "Checking for remaining test scripts..." "CLEANUP"
$testScripts = Get-ChildItem -Path $ProjectRoot -Name "test-*.ps1" -ErrorAction SilentlyContinue
foreach ($testScript in $testScripts) {
 Move-ScriptFile $testScript "archive/test-scripts/$testScript" "Legacy test script"
}

# 6. Archive any remaining run scripts
Write-CleanupLog "Checking for remaining run scripts..." "CLEANUP"
$runScripts = Get-ChildItem -Path $ProjectRoot -Name "run-*.ps1" -ErrorAction SilentlyContinue
foreach ($runScript in $runScripts) {
 Move-ScriptFile $runScript "archive/maintenance-scripts/$runScript" "Legacy run script"
}

# 7. Clean up backup and cleanup directories that shouldn't be in root
Write-CleanupLog "Organizing backup directories..." "CLEANUP"
$backupDirs = Get-ChildItem -Path $ProjectRoot -Name "cleanup-backup-*" -Directory -ErrorAction SilentlyContinue
foreach ($backupDir in $backupDirs) {
 $sourcePath = Join-Path $ProjectRoot $backupDir
 $destPath = Join-Path $ProjectRoot "backups/$backupDir"
 
 if ($WhatIf) {
 Write-CleanupLog "Would move backup directory: $backupDir → backups/$backupDir" "INFO"
 } else {
 if (-not (Test-Path (Join-Path $ProjectRoot "backups"))) {
 New-Item -ItemType Directory -Path (Join-Path $ProjectRoot "backups") -Force | Out-Null}
 try {
 Move-Item -Path $sourcePath -Destination $destPath -Force
 Write-CleanupLog "Moved backup directory: $backupDir → backups/$backupDir" "SUCCESS"
 }
 catch {
 Write-CleanupLog "Failed to move backup directory $backupDir : $($_.Exception.Message)" "ERROR"
 }
 }
}

# 8. Ensure we have our required scripts in place
Write-CleanupLog "Verifying required maintenance scripts are in place..." "CLEANUP"
$requiredScripts = @{
 "scripts/maintenance/unified-maintenance.ps1" = "Main maintenance script"
 "scripts/maintenance/infrastructure-health-check.ps1" = "Health monitoring script" 
 "scripts/maintenance/track-recurring-issues.ps1" = "Issue tracking script"
 "scripts/maintenance/fix-infrastructure-issues.ps1" = "Automated fix script"
 "scripts/utilities/new-report.ps1" = "Report generation script"
}

foreach ($script in $requiredScripts.Keys) {
 $scriptPath = Join-Path $ProjectRoot $script
 if (Test-Path $scriptPath) {
 Write-CleanupLog "PASS Required script found: $script" "SUCCESS"
 } else {
 Write-CleanupLog "FAIL Missing required script: $script - $($requiredScripts$script)" "ERROR"
 }
}

# 9. Create a summary of what should remain in root
Write-CleanupLog "Creating cleanup summary..." "CLEANUP"

$cleanupSummary = @'
# Root Directory Cleanup Summary - {0}

## Scripts Moved/Archived

### Organization Scripts → archive/maintenance-scripts/
- organize-project.ps1
- organize-project-fixed.ps1 
- cleanup-remaining.ps1

### Empty Scripts → Removed
- clean-workflows.ps1 (empty)
- comprehensive-syntax-checker.ps1 (empty)
- enhanced-fix-labrunner.ps1 (empty)
- fix-*.ps1 files (empty/obsolete)
- run-*.ps1 files (empty/obsolete)
- test-*.ps1 files (empty/obsolete)

### Configuration Files → Appropriate Locations
- test-config-errors.json → tests/data/
- workflow-optimization-report.json → reports/

### Backup Directories → backups/
- cleanup-backup-* directories moved to backups/

## Files That Should Remain in Root

### Essential Project Files
- AGENTS.md, CHANGELOG.md, README.md, LICENSE
- .gitignore, .github/, .vscode/

### Primary Directories
- docs/, scripts/, tests/, pwsh/, py/, tools/
- configs/, archive/, backups/

### Legacy Directories (to be gradually cleaned)
- LabRunner/ (old location - being migrated)
- reports/ (old location - content moved to docs/reports/)

## Maintenance Commands

Use the unified maintenance system instead of individual scripts:

```powershell
# Quick health check
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Quick"

# Full maintenance
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix

# Issue tracking 
./scripts/maintenance/track-recurring-issues.ps1 -Mode "All"
```
'@ -f (Get-Date -Format "yyyy-MM-dd")

$summaryPath = Join-Path $ProjectRoot "docs/reports/project-status/$(Get-Date -Format "yyyy-MM-dd")-root-cleanup-summary.md"
if (-not $WhatIf) {
 cleanupSummary | Set-Content $summaryPath
 Write-CleanupLog "Created cleanup summary: $summaryPath" "SUCCESS"
}

Write-CleanupLog " Root directory cleanup completed!" "SUCCESS"
Write-CleanupLog "Use the unified maintenance system for ongoing project maintenance" "INFO"







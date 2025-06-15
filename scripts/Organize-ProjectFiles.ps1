# Organize-ProjectFiles.ps1
# Script to organize, clean up, and archive deprecated files after CodeFixer module implementation
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$Force,
    [switch]$SkipBackup
)








$ErrorActionPreference = 'Stop'

# Create timestamps for organization
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRootDir = Join-Path $PSScriptRoot "backups" "cleanup-$timestamp"

# Helper function to back up files
function Backup-Files {
    param (
        [string[]]$FilePaths,
        [string]$Category
    )

    






if ($SkipBackup) {
        return
    }

    $backupDir = Join-Path $backupRootDir $Category
    if (-not (Test-Path $backupDir)) {
        if (-not $WhatIf) {
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        } else {
            Write-Host "WhatIf: Would create directory $backupDir" -ForegroundColor Yellow
        }
    }

    foreach ($file in $FilePaths) {
        if (Test-Path $file) {
            $fileName = Split-Path -Path $file -Leaf
            $backupPath = Join-Path $backupDir $fileName
            
            if ($WhatIf) {
                Write-Host "WhatIf: Would back up $file to $backupPath" -ForegroundColor Yellow
            } else {
                try {
                    Copy-Item -Path $file -Destination $backupPath -Force
                    Write-Host "Backed up $file to $backupPath" -ForegroundColor Cyan
                } catch {
                    Write-Warning "Failed to back up $file`: $($_.Exception.Message)"
                }
            }
        }
    }
}

# Helper function to move files to archive
function Move-ToArchive {
    param (
        [string[]]$FilePaths,
        [string]$Category
    )

    






$archiveDir = Join-Path $PSScriptRoot "archive" $Category
    if (-not (Test-Path $archiveDir)) {
        if (-not $WhatIf) {
            New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
        } else {
            Write-Host "WhatIf: Would create archive directory $archiveDir" -ForegroundColor Yellow
        }
    }

    foreach ($file in $FilePaths) {
        if (Test-Path $file) {
            $fileName = Split-Path -Path $file -Leaf
            $archivePath = Join-Path $archiveDir $fileName
            
            if ($WhatIf) {
                Write-Host "WhatIf: Would archive $file to $archivePath" -ForegroundColor Yellow
            } else {
                try {
                    Move-Item -Path $file -Destination $archivePath -Force
                    Write-Host "Archived $file to $archivePath" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to archive $file`: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Host "File not found: $file" -ForegroundColor Gray
        }
    }
}

# Helper function to delete files
function Remove-DeprecatedFiles {
    param (
        [string[]]$FilePaths
    )

    






foreach ($file in $FilePaths) {
        if (Test-Path $file) {
            if ($WhatIf) {
                Write-Host "WhatIf: Would delete $file" -ForegroundColor Yellow
            } else {
                try {
                    Remove-Item -Path $file -Force
                    Write-Host "Deleted $file" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to delete $file`: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Host "File already deleted or does not exist: $file" -ForegroundColor Gray
        }
    }
}

# Helper function to create placeholder README for archive directories
function New-ArchiveReadme {
    param (
        [string]$ArchiveDir,
        [string]$Category,
        [string]$Description
    )

    






$readmePath = Join-Path $ArchiveDir "README.md"
    
    $content = @"
# Archived $Category

These files were archived on $(Get-Date -Format "yyyy-MM-dd") as part of the CodeFixer module integration.

## Description
$Description

## Original Purpose
These files were originally used for standalone fixes and testing, but have been replaced by the consolidated functionality in the CodeFixer PowerShell module.

## Reference
For more information on the new approach, see:
- [CodeFixer Guide](../docs/CODEFIXER-GUIDE.md)
- [Testing Documentation](../docs/TESTING.md)
- [Integration Summary](../INTEGRATION-SUMMARY.md)
"@

    if ($WhatIf) {
        Write-Host "WhatIf: Would create README at $readmePath" -ForegroundColor Yellow
    } else {
        Set-Content -Path $readmePath -Value $content -Force
        Write-Host "Created README at $readmePath" -ForegroundColor Green
    }
}

# Begin the organization process
Write-Host "Starting file organization and cleanup process..." -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Cyan
Write-Host "Mode: $$(if (WhatIf) { 'WhatIf (simulation)' } else { 'Execution' })" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Identify and organize deprecated fix scripts
Write-Host "`n[1/5] Organizing deprecated fix scripts..." -ForegroundColor Magenta

$fixScriptsToArchive = @(
    "fix-bootstrap-script.ps1",
    "fix-runtime-execution-simple.ps1",
    "fix-test-syntax-errors.ps1",
    "fix-all-test-syntax.ps1",
    "fix-specific-file.ps1"
) | ForEach-Object { Join-Path $PSScriptRoot $_ }

$fixScriptsToDelete = @(
    "fix-ternary-syntax.ps1"
) | ForEach-Object { Join-Path $PSScriptRoot $_ }

# First back up all files
Backup-Files -FilePaths ($fixScriptsToArchive + $fixScriptsToDelete) -Category "fix-scripts"

# Archive scripts we want to keep for reference
Move-ToArchive -FilePaths $fixScriptsToArchive -Category "fix-scripts"

# Delete scripts that are completely replaced
Remove-DeprecatedFiles -FilePaths $fixScriptsToDelete

# Create README in archive directory
if (-not $WhatIf) {
    $archiveFixDir = Join-Path $PSScriptRoot "archive" "fix-scripts"
    if (Test-Path $archiveFixDir) {
        New-ArchiveReadme -ArchiveDir $archiveFixDir -Category "Fix Scripts" -Description "These scripts were used for fixing various syntax and execution issues in PowerShell scripts. They have been replaced by the CodeFixer module's Invoke-AutoFix and related functions."
    }
}

# 2. Identify and organize deprecated test scripts
Write-Host "`n[2/5] Organizing deprecated test scripts..." -ForegroundColor Magenta

$testScriptsToArchive = @(
    "test-bootstrap-fixes.py",
    "test-bootstrap-syntax.py",
    "validate-syntax.py",
    "test-all-syntax.ps1"
) | ForEach-Object { Join-Path $PSScriptRoot $_ }

# Back up all files
Backup-Files -FilePaths $testScriptsToArchive -Category "test-scripts"

# Archive scripts
Move-ToArchive -FilePaths $testScriptsToArchive -Category "test-scripts"

# Create README in archive directory
if (-not $WhatIf) {
    $archiveTestDir = Join-Path $PSScriptRoot "archive" "test-scripts"
    if (Test-Path $archiveTestDir) {
        New-ArchiveReadme -ArchiveDir $archiveTestDir -Category "Test Scripts" -Description "These scripts were used for testing and validating syntax in PowerShell and Python scripts. They have been replaced by the CodeFixer module's Invoke-ComprehensiveValidation and related functions."
    }
}

# 3. Identify and organize deprecated workflows
Write-Host "`n[3/5] Organizing deprecated workflows..." -ForegroundColor Magenta

# Define workflow categories
$primaryWorkflows = @(
    "unified-ci.yml",
    "auto-test-generation.yml",
    "auto-test-generation-setup.yml",
    "auto-test-generation-execution.yml",
    "auto-test-generation-reporting.yml"
)

$workflowsDir = Join-Path (Split-Path $PSScriptRoot -Parent) ".github" "workflows"
$allWorkflows = Get-ChildItem -Path $workflowsDir -Filter "*.yml" | Select-Object -ExpandProperty Name
$potentiallyDeprecatedWorkflows = $allWorkflows | Where-Object { $_ -notin $primaryWorkflows }

# Separate into categories
$deprecatedWorkflows = @(
    "pester.yml",
    "lint.yml",
    "ci.yml",
    "test.yml"
) | ForEach-Object { Join-Path $workflowsDir $_ }

$specializedWorkflows = $potentiallyDeprecatedWorkflows | Where-Object { 
    $_ -notin ("pester.yml", "lint.yml", "ci.yml", "test.yml") 
} | ForEach-Object { Join-Path $workflowsDir $_ }

# Back up all workflows
Backup-Files -FilePaths ($deprecatedWorkflows + $specializedWorkflows) -Category "workflows"

# Move deprecated workflows to archive
$workflowArchiveDir = Join-Path (Split-Path $PSScriptRoot -Parent) "archive" "deprecated-workflows"
if (-not (Test-Path $workflowArchiveDir) -and -not $WhatIf) {
    New-Item -Path $workflowArchiveDir -ItemType Directory -Force | Out-Null
}

foreach ($workflow in $deprecatedWorkflows) {
    if (Test-Path $workflow) {
        $workflowName = Split-Path -Path $workflow -Leaf
        $archivePath = Join-Path $workflowArchiveDir $workflowName
        
        if ($WhatIf) {
            Write-Host "WhatIf: Would archive workflow $workflow to $archivePath" -ForegroundColor Yellow
        } else {
            try {
                Move-Item -Path $workflow -Destination $archivePath -Force
                Write-Host "Archived workflow $workflow to $archivePath" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to archive workflow $workflow`: $($_.Exception.Message)"
            }
        }
    }
}

# Create README in archive directory
if (-not $WhatIf -and (Test-Path $workflowArchiveDir)) {
    $content = @"
# Deprecated GitHub Workflows

These workflow files were archived on $(Get-Date -Format "yyyy-MM-dd") as part of the CodeFixer module integration.

## Reason for Deprecation
These workflows have been consolidated into the unified-ci.yml workflow, which now handles all CI/CD processes including:
- Linting
- Testing (Pester and PyTest)
- Validation
- Health checks
- Comprehensive validation using the CodeFixer module

## Current Workflows
The project now uses the following primary workflows:
- unified-ci.yml - Main CI/CD pipeline
- auto-test-generation.yml and related workflows - Automatic test generation

For more information, see the [Integration Summary](../../INTEGRATION-SUMMARY.md).
"@
    Set-Content -Path (Join-Path $workflowArchiveDir "README.md") -Value $content -Force
    Write-Host "Created README in workflow archive directory" -ForegroundColor Green
}

# 4. Create organization READMEs
Write-Host "`n[4/5] Creating organization READMEs..." -ForegroundColor Magenta

# Create README for scripts directory
$scriptsReadmePath = Join-Path $PSScriptRoot "README.md"
$scriptsReadmeContent = @"
# Automation Scripts

This directory contains automation scripts for managing the OpenTofu Lab Automation project.

## Main Scripts

### CodeFixer Module Integration
- **Deploy-CodeFixerModule.ps1** - Master deployment script for the CodeFixer module
- **Install-CodeFixerIntegration.ps1** - Integrates the CodeFixer module with runner scripts
- **Update-Workflows.ps1** - Updates GitHub Actions workflows to use the CodeFixer module
- **Cleanup-DeprecatedFiles.ps1** - Cleans up deprecated fix scripts
- **Organize-ProjectFiles.ps1** - Organizes and archives deprecated files

### Other Automation
- Various other automation scripts for specific tasks

## Usage

Most scripts can be run with the `-WhatIf` parameter to see what changes would be made without actually applying them.

Example:
```powershell
./Deploy-CodeFixerModule.ps1 -WhatIf
```

Then run without `-WhatIf` to apply the changes:
```powershell
./Deploy-CodeFixerModule.ps1
```

## Documentation

For more information on the CodeFixer module and related automation, see:
- [CODEFIXER-GUIDE.md](../docs/CODEFIXER-GUIDE.md)
- [TESTING.md](../docs/TESTING.md)
- [INTEGRATION-SUMMARY.md](../INTEGRATION-SUMMARY.md)
"@

if ($WhatIf) {
    Write-Host "WhatIf: Would create README at $scriptsReadmePath" -ForegroundColor Yellow
} else {
    Set-Content -Path $scriptsReadmePath -Value $scriptsReadmeContent -Force
    Write-Host "Created README at $scriptsReadmePath" -ForegroundColor Green
}

# Create README for archive directory
$archiveReadmePath = Join-Path $PSScriptRoot "archive" "README.md"
$archiveReadmeContent = @"
# Archive Directory

This directory contains archived files that are no longer actively used in the project but kept for reference.

## Contents

### Deprecated Fix Scripts
Scripts that were previously used for fixing issues but have been replaced by the CodeFixer module.

### Deprecated Test Scripts
Scripts that were previously used for testing but have been replaced by the CodeFixer module's validation functions.

### Deprecated Workflows
GitHub Actions workflows that have been replaced by the unified-ci.yml workflow.

## CodeFixer Module

All the functionality provided by these archived files has been consolidated into the CodeFixer PowerShell module.

For more information, see:
- [CODEFIXER-GUIDE.md](../docs/CODEFIXER-GUIDE.md)
- [TESTING.md](../docs/TESTING.md)
- [INTEGRATION-SUMMARY.md](../INTEGRATION-SUMMARY.md)
"@

if ($WhatIf) {
    Write-Host "WhatIf: Would create README at $archiveReadmePath" -ForegroundColor Yellow
} else {
    if (-not (Test-Path (Join-Path $PSScriptRoot "archive"))) {
        New-Item -Path (Join-Path $PSScriptRoot "archive") -ItemType Directory -Force | Out-Null
    }
    Set-Content -Path $archiveReadmePath -Value $archiveReadmeContent -Force
    Write-Host "Created README at $archiveReadmePath" -ForegroundColor Green
}

# 5. Update module structure to ensure it's organized
Write-Host "`n[5/5] Organizing module structure..." -ForegroundColor Magenta

$moduleDir = Join-Path $PSScriptRoot "pwsh" "modules" "CodeFixer"
$publicDir = Join-Path $moduleDir "Public"
$privateDir = Join-Path $moduleDir "Private"

foreach ($dir in @($moduleDir, $publicDir, $privateDir)) {
    if (-not (Test-Path $dir)) {
        if ($WhatIf) {
            Write-Host "WhatIf: Would create directory $dir" -ForegroundColor Yellow
        } else {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "Created directory $dir" -ForegroundColor Green
        }
    }
}

# Create README for module
$moduleReadmePath = Join-Path $moduleDir "README.md"
$moduleReadmeContent = @"
# CodeFixer PowerShell Module

This PowerShell module provides comprehensive tools for code fixing, validation, and test generation in the OpenTofu Lab Automation project.

## Directory Structure

- **Public/** - Contains all public functions that are exported by the module
- **Private/** - Contains helper functions used internally by the module
- **CodeFixer.psd1** - Module manifest
- **CodeFixer.psm1** - Module loader script

## Key Functions

| Function | Description |
|----------|-------------|
| `Invoke-AutoFix` | Runs all available fixers in sequence |
| `Invoke-PowerShellLint` | Runs and reports on PowerShell linting |
| `Invoke-TestSyntaxFix` | Fixes common syntax errors in test files |
| `Invoke-TernarySyntaxFix` | Fixes ternary operator issues in scripts |
| `Invoke-ScriptOrderFix` | Fixes Import-Module/Param order in scripts |
| `New-AutoTest` | Generates tests for PowerShell scripts |
| `Watch-ScriptDirectory` | Watches for script changes and generates tests |
| `Invoke-ResultsAnalysis` | Parses test results and applies fixes |
| `Invoke-ComprehensiveValidation` | Runs full validation suite |

## Usage

Import the module:
```powershell
Import-Module .//pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
```

For detailed documentation, see [CODEFIXER-GUIDE.md](../../../docs/CODEFIXER-GUIDE.md).
"@

if ($WhatIf) {
    Write-Host "WhatIf: Would create README at $moduleReadmePath" -ForegroundColor Yellow
} else {
    Set-Content -Path $moduleReadmePath -Value $moduleReadmeContent -Force
    Write-Host "Created README at $moduleReadmePath" -ForegroundColor Green
}

# Summary
Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "File organization and cleanup process summary:" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

Write-Host "`nActions taken:" -ForegroundColor White
Write-Host "- Organized deprecated fix scripts" -ForegroundColor White
Write-Host "- Organized deprecated test scripts" -ForegroundColor White
Write-Host "- Organized deprecated workflows" -ForegroundColor White
Write-Host "- Created READMEs for organization" -ForegroundColor White
Write-Host "- Ensured module structure is organized" -ForegroundColor White

if ($WhatIf) {
    Write-Host "`nThis was a WhatIf simulation. Run without -WhatIf to actually perform these actions." -ForegroundColor Yellow
} else {
    Write-Host "`nOrganization and cleanup complete!" -ForegroundColor Green
}

Write-Host "`nFor details on the new project structure, see:" -ForegroundColor Cyan
Write-Host "- docs/TESTING.md" -ForegroundColor White
Write-Host "- docs/CODEFIXER-GUIDE.md" -ForegroundColor White
Write-Host "- INTEGRATION-SUMMARY.md" -ForegroundColor White




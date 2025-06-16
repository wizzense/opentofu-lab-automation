#!/usr/bin/env pwsh
# Project Organization and Cleanup Script
# This script organizes and cleans up the OpenTofu Lab Automation project structure

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$Force
)








$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    






Write-Host "📋 $Message" -ForegroundColor $Color
}

function Move-ProjectFile {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$CreateDirectory
    )
    
    






if (-not (Test-Path $Source)) {
        Write-Warning "Source file not found: $Source"
        return $false
    }
    
    $destDir = Split-Path -Parent $Destination
    if ($CreateDirectory -and -not (Test-Path $destDir)) {
        try {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            Write-Host "  📁 Created directory: $destDir" -ForegroundColor Gray
        } catch {
            Write-Warning "Failed to create directory $destDir`: $_"
            return $false
        }
    }
    
    try {
        if ($WhatIf) {
            Write-Host "  📋 Would move: $Source -> $Destination" -ForegroundColor Yellow
        } else {
            Move-Item -Path $Source -Destination $Destination -Force:$Force
            Write-Host "  [PASS] Moved: $Source -> $Destination" -ForegroundColor Green
        }
        return $true
    } catch {
        Write-Warning "Failed to move file $Source to $Destination`: $_"
        return $false
    }
}

function Copy-ProjectFile {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$CreateDirectory
    )
    
    






if (-not (Test-Path $Source)) {
        Write-Warning "Source file not found: $Source"
        return $false
    }
    
    $destDir = Split-Path -Parent $Destination
    if ($CreateDirectory -and -not (Test-Path $destDir)) {
        try {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            Write-Host "  📁 Created directory: $destDir" -ForegroundColor Gray
        } catch {
            Write-Warning "Failed to create directory $destDir`: $_"
            return $false
        }
    }
    
    try {
        if ($WhatIf) {
            Write-Host "  📋 Would copy: $Source -> $Destination" -ForegroundColor Yellow
        } else {
            Copy-Item -Path $Source -Destination $Destination -Force:$Force
            Write-Host "  [PASS] Copied: $Source -> $Destination" -ForegroundColor Green
        }
        return $true
    } catch {
        Write-Warning "Failed to copy file $Source to $Destination`: $_"
        return $false
    }
}

function Archive-ProjectFile {
    param(
        [string]$Source,
        [string]$ArchiveDir = "archive"
    )
    
    






if (-not (Test-Path $Source)) {
        Write-Warning "Source file not found: $Source"
        return $false
    }
    
    $fileName = Split-Path -Leaf $Source
    $destination = Join-Path $ArchiveDir $fileName
    
    if (-not (Test-Path $ArchiveDir)) {
        try {
            New-Item -Path $ArchiveDir -ItemType Directory -Force | Out-Null
            Write-Host "  📁 Created archive directory: $ArchiveDir" -ForegroundColor Gray
        } catch {
            Write-Warning "Failed to create archive directory $ArchiveDir`: $_"
            return $false
        }
    }
    
    try {
        if ($WhatIf) {
            Write-Host "  📋 Would archive: $Source -> $destination" -ForegroundColor Yellow
        } else {
            Move-Item -Path $Source -Destination $destination -Force:$Force
            Write-Host "  🗄️ Archived: $Source -> $destination" -ForegroundColor Magenta
        }
        return $true
    } catch {
        Write-Warning "Failed to archive file $Source`: $_"
        return $false
    }
}

# Start the cleanup process
$rootDir = $PSScriptRoot
Write-Host "🧹 Starting OpenTofu Lab Automation project cleanup and organization" -ForegroundColor Cyan
Write-Host "Working directory: $rootDir" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "Running in WhatIf mode - no changes will be made" -ForegroundColor Yellow
}
Write-Host "=============================================================" -ForegroundColor Cyan

# 1. Create necessary directories if they don't exist
Write-Step "Creating directory structure"
$directories = @(
    "scripts/validation",
    "scripts/maintenance",
    "scripts/testing",
    "tools/validation",
    "tools/automation",
    "tools/linting",
    "archive/fix-scripts",
    "archive/test-scripts"
)

foreach ($dir in $directories) {
    $dirPath = Join-Path $rootDir $dir
    if (-not (Test-Path $dirPath)) {
        if ($WhatIf) {
            Write-Host "  📋 Would create directory: $dir" -ForegroundColor Yellow
        } else {
            try {
                New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
                Write-Host "  📁 Created directory: $dir" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to create directory $dir`: $_"
            }
        }
    } else {
        Write-Host "   Directory already exists: $dir" -ForegroundColor Gray
    }
}

# 2. Move validation and verification scripts
Write-Step "Moving validation and verification scripts"
$validationScripts = @{
    "run-final-validation.ps1" = "scripts/validation/run-validation.ps1"
    "final-verification.ps1" = "scripts/validation/verify-system.ps1"
    "comprehensive-lint.ps1" = "scripts/validation/run-lint.ps1"
    "comprehensive-health-check.ps1" = "scripts/validation/health-check.ps1"
    "test-codefixer-enhancements.ps1" = "tools/validation/test-codefixer.ps1"
    "invoke-comprehensive-validation.ps1" = "scripts/validation/invoke-validation.ps1"
}

foreach ($script in $validationScripts.Keys) {
    $source = Join-Path $rootDir $script
    $destination = Join-Path $rootDir $validationScripts[$script]
    
    Move-ProjectFile -Source $source -Destination $destination -CreateDirectory
}

# 3. Move test scripts
Write-Step "Moving test scripts"
$testScripts = @{
    "run-all-tests.ps1" = "scripts/testing/run-all-tests.ps1"
    "run-comprehensive-tests.ps1" = "scripts/testing/run-comprehensive-tests.ps1"
    "test-all-syntax.ps1" = "scripts/testing/test-syntax.ps1"
    "test-final-fixes.ps1" = "tools/validation/test-fixes.ps1"
    "test-codefixer-improvements.ps1" = "tools/validation/test-codefixer-full.ps1"
}

foreach ($script in $testScripts.Keys) {
    $source = Join-Path $rootDir $script
    $destination = Join-Path $rootDir $testScripts[$script]
    
    Move-ProjectFile -Source $source -Destination $destination -CreateDirectory
}

# 4. Move maintenance scripts
Write-Step "Moving maintenance scripts"
$maintenanceScripts = @{
    "create-validation-system.ps1" = "scripts/maintenance/setup-validation.ps1"
    "fix-runner-execution.ps1" = "scripts/maintenance/fix-runner.ps1"
    "fix-runtime-execution-simple.ps1" = "scripts/maintenance/simple-runtime-fix.ps1"
    "update-labrunner-imports.ps1" = "scripts/maintenance/update-imports.ps1"
}

foreach ($script in $maintenanceScripts.Keys) {
    $source = Join-Path $rootDir $script
    $destination = Join-Path $rootDir $maintenanceScripts[$script]
    
    Move-ProjectFile -Source $source -Destination $destination -CreateDirectory
}

# 5. Archive test files and obsolete scripts
Write-Step "Archiving test files and obsolete scripts"
$archiveFiles = @(
    "simple-syntax-error.ps1",
    "test-param-issue.ps1",
    "test-syntax-errors.ps1",
    "test-config-errors.json",
    "test-bootstrap-fixes.py",
    "test-bootstrap-syntax.py",
    "test-cross-platform-executor.ps1",
    "test-syntax-validation.ps1",
    "validate-syntax.py",
    "enhanced-fix-labrunner.ps1",
    "fix-test-syntax-errors.ps1",
    "fix-specific-file.ps1",
    "fix-all-test-syntax.ps1",
    "fix-bootstrap-script.ps1",
    "fix-codefixer-and-tests.ps1", 
    "fix-ternary-syntax.ps1",
    "fix-powershell-syntax.ps1",
    "simple-fix-test-syntax.ps1",
    "auto-fix.ps1",
    "final-automation-test.ps1"
)

$archiveTestDir = Join-Path $rootDir "archive/test-scripts"
$archiveFixDir = Join-Path $rootDir "archive/fix-scripts"

foreach ($file in $archiveFiles) {
    $source = Join-Path $rootDir $file
    
    # Choose the appropriate archive directory based on the file prefix
    $archiveDir = if ($file -like "test-*" -or $file -like "simple-*") { $archiveTestDir
       } else { $archiveFixDir
       }
    
    if (-not (Test-Path $source)) {
        Write-Host "  [WARN]️ File not found: $file" -ForegroundColor Yellow
        continue
    }

    if (-not (Test-Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }
    
    $destination = Join-Path $archiveDir $file
    
    if ($WhatIf) {
        Write-Host "  📋 Would archive: $file -> $destination" -ForegroundColor Yellow
    } else {
        try {
            Move-Item -Path $source -Destination $destination -Force:$Force
            Write-Host "  🗄️ Archived: $file -> $destination" -ForegroundColor Magenta
        } catch {
            Write-Warning "Failed to archive file $file`: $_"
        }
    }
}

# 6. Update the CLEANUP-SUMMARY.md file
Write-Step "Updating CLEANUP-SUMMARY.md"

$cleanupSummary = @"
# OpenTofu Lab Automation Project Cleanup Summary

## 🚀 Project Organization Cleanup

This document summarizes the cleanup and organization work performed on the OpenTofu Lab Automation project to improve maintainability and workflow integration.

## 📁 Directory Structure

The project has been organized into the following structure:

```
/workspaces/opentofu-lab-automation/
├── pwsh/
│   ├── modules/
│   │   ├── CodeFixer/        # CodeFixer module for automation fixes
│   │   │   ├── Public/       # Public functions
│   │   │   ├── Private/      # Private helper functions
│   │   │   ├── CodeFixer.psd1
│   │   │   └── CodeFixer.psm1
│   │   │
│   │   └── LabRunner/        # Lab automation runner module (moved from lab_utils)
│   │       ├── LabRunner.psd1
│   │       └── LabRunner.psm1
│   │
│   ├── runner_scripts/       # Core automation runner scripts
│   └── runner.ps1            # Main execution script
│
├── scripts/                  # Operational/workflow scripts
│   ├── validation/           # Scripts for validation and verification
│   ├── maintenance/          # Maintenance and cleanup scripts
│   └── testing/              # Test execution scripts
│
├── tools/                    # Helper tools and utilities
│   ├── linting/              # Linting and code quality tools
│   └── validation/           # Validation helpers and testers
│
├── tests/                    # Test files and frameworks
│   ├── helpers/              # Test helper utilities
│   └── *.Tests.ps1           # Pester test files
│
└── archive/                  # Archived/obsolete scripts and files
    ├── fix-scripts/          # Old fix scripts
    └── test-scripts/         # Old test scripts
```

## 🔄 Scripts Cleanup Summary

### [PASS] Scripts Consolidated into CodeFixer Module

The following scripts have been incorporated into the CodeFixer module:

| Original Script | Module Function | Description |
|-----------------|-----------------|-------------|
| fix-powershell-syntax.ps1 | Invoke-PowerShellLint | PowerShell syntax checking and linting |
| fix-test-syntax-errors.ps1 | Invoke-TestSyntaxFix | Fix common test syntax errors |
| fix-ternary-syntax.ps1 | Invoke-TernarySyntaxFix | Fix ternary operator syntax issues |
| comprehensive-lint.ps1 | Invoke-ComprehensiveValidation | Run comprehensive validation |
| enhanced-fix-labrunner.ps1 | Invoke-ImportAnalysis | Fix import paths and dependencies |

### [PASS] Scripts Moved to Operational Directories

The following scripts have been moved to appropriate operational directories:

| Original Location | New Location | Description |
|-------------------|--------------|-------------|
| run-final-validation.ps1 | scripts/validation/run-validation.ps1 | Run full validation suite |
| final-verification.ps1 | scripts/validation/verify-system.ps1 | Verify system functionality |
| comprehensive-lint.ps1 | scripts/validation/run-lint.ps1 | Run linting checks |
| comprehensive-health-check.ps1 | scripts/validation/health-check.ps1 | Run health checks |
| run-all-tests.ps1 | scripts/testing/run-all-tests.ps1 | Run all test suites |
| run-comprehensive-tests.ps1 | scripts/testing/run-comprehensive-tests.ps1 | Run comprehensive tests |
| test-all-syntax.ps1 | scripts/testing/test-syntax.ps1 | Test syntax of all scripts |
| create-validation-system.ps1 | scripts/maintenance/setup-validation.ps1 | Set up validation system |
| fix-runner-execution.ps1 | scripts/maintenance/fix-runner.ps1 | Fix runner execution |
| fix-runtime-execution-simple.ps1 | scripts/maintenance/simple-runtime-fix.ps1 | Simple runtime fixes |
| update-labrunner-imports.ps1 | scripts/maintenance/update-imports.ps1 | Update import paths |

### [PASS] Scripts Archived

The following obsolete or redundant scripts have been archived:

| Script | Reason |
|--------|--------|
| simple-syntax-error.ps1 | Test file, no longer needed |
| test-param-issue.ps1 | Test file, functionality now in tests |
| test-syntax-errors.ps1 | Test file, functionality now in CodeFixer |
| test-bootstrap-fixes.py | Test script, functionality now automated |
| test-bootstrap-syntax.py | Python test, functionality now in CodeFixer |
| test-cross-platform-executor.ps1 | Test script, functionality integrated |
| test-syntax-validation.ps1 | Test script, functionality in CodeFixer |
| fix-bootstrap-script.ps1 | Fix script, functionality in CodeFixer |
| fix-codefixer-and-tests.ps1 | Fix script, functionality in CodeFixer |
| fix-ternary-syntax.ps1 | Fix script, functionality in CodeFixer |
| fix-powershell-syntax.ps1 | Fix script, functionality in CodeFixer |
| fix-all-test-syntax.ps1 | Fix script, functionality in CodeFixer |
| fix-specific-file.ps1 | One-time fix, no longer needed |
| auto-fix.ps1 | Replaced by Invoke-AutoFix function |
| simple-fix-test-syntax.ps1 | Simple fix script, functionality in CodeFixer |
| enhanced-fix-labrunner.ps1 | Fix script, functionality in CodeFixer |
| final-automation-test.ps1 | Test script, functionality in test framework |

## 🚀 Benefits of Reorganization

1. **Improved Maintainability**: Clear directory structure with logical organization
2. **Reduced Duplication**: Consolidated overlapping functionality into modules
3. **Better Discoverability**: Scripts are now located in meaningful directories
4. **Cleaner Root Directory**: Reduced clutter in the project root
5. **Consistent Naming**: Applied consistent naming conventions
6. **Integration with CI/CD**: Simplified paths for CI/CD workflows

## 📋 Next Steps

1. Update GitHub Actions workflows to use the new script paths
2. Update documentation to reflect new structure
3. Run validation to ensure all scripts work in their new locations
"@

if ($WhatIf) {
    Write-Host "  📋 Would update CLEANUP-SUMMARY.md" -ForegroundColor Yellow
} else {
    try {
        Set-Content -Path (Join-Path $rootDir "CLEANUP-SUMMARY.md") -Value $cleanupSummary -Force
        Write-Host "  [PASS] Updated CLEANUP-SUMMARY.md" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to update CLEANUP-SUMMARY.md`: $_"
    }
}

# Summary
Write-Host "`n[PASS] Project organization and cleanup completed!" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "WhatIf mode was enabled - no actual changes were made." -ForegroundColor Yellow
    Write-Host "Run the script again without -WhatIf to apply the changes." -ForegroundColor Yellow
} else {
    Write-Host "The project structure has been reorganized according to the plan." -ForegroundColor Green
    Write-Host "Please review the CLEANUP-SUMMARY.md file for details." -ForegroundColor Green
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Update GitHub Actions workflows to reference new script paths" -ForegroundColor White
Write-Host "2. Run validation to ensure all scripts work in their new locations" -ForegroundColor White
Write-Host "3. Update documentation to reflect new structure" -ForegroundColor White




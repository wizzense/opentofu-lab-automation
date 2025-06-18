---
applyTo: "**/PatchManager/**"
description: "Comprehensive PatchManager usage guide and development standards"
---

# PatchManager Module Instructions and Usage Guide

## Overview
This document provides comprehensive instructions for using, developing, and testing the PatchManager module in the OpenTofu Lab Automation project. PatchManager is the primary tool for Git-controlled patching, branch management, and automated issue tracking.

## Core PatchManager Functions and Usage

### 1. Basic Git Operations with PatchManager

#### Creating a Branch and Committing Changes
```powershell
# Step 1: Import required modules
Import-Module 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\core-runner\modules\Logging' -Force
Import-Module 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\core-runner\modules\PatchManager' -Force

# Step 2: Use GitControlledPatch for comprehensive workflow
Invoke-GitControlledPatch -PatchDescription "feat: comprehensive project restructure and cleanup" -CreatePullRequest

# Step 3: Alternative - Use basic Git operations directly
. 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\core-runner\modules\PatchManager\Public\GitOperations.ps1'
CreatePatchBranch -BranchName "feat/project-restructure" -BaseBranch "main"
git add .
CommitChanges -CommitMessage "feat(project): comprehensive restructure"
```

#### Enhanced Git Operations with Conflict Resolution
```powershell
# Use enhanced Git operations for complex merges
Invoke-EnhancedGitOperations -Operation "MergeMain" -ValidateAfter
Invoke-EnhancedGitOperations -Operation "ResolveConflicts" -Force
```

### 2. Comprehensive Patch Management Workflow

#### Full Automated Patch Workflow
```powershell
# Complete patch management with validation and PR creation
Invoke-GitControlledPatch `
    -PatchDescription "refactor(modules): update logging integration" `
    -PatchOperation { 
        # Your patch operations here
        Write-CustomLog "Applying module updates..." -Level INFO
    } `
    -AffectedFiles @("core-runner/modules/Logging/Logging.psm1") `
    -CreatePullRequest `
    -AutoMerge
```

#### Dry Run Mode for Testing
```powershell
# Test patch operations without making changes
Invoke-GitControlledPatch `
    -PatchDescription "test: validate new feature" `
    -DryRun `
    -SkipValidation
```

### 3. Enhanced Patch Manager with Issue Tracking

#### Patch with Automatic Issue Creation
```powershell
Invoke-EnhancedPatchManager `
    -PatchDescription "fix: resolve module import issues" `
    -AutoValidate `
    -CreateIssue `
    -CreatePullRequest
```

#### Mass File Operations
```powershell
# Apply fixes to multiple files at once
$filesToFix = @(
    "core-runner/modules/LabRunner/LabRunner.psm1",
    "core-runner/modules/BackupManager/BackupManager.psm1"
)

Invoke-MassFileFix `
    -FilePaths $filesToFix `
    -FixOperation { 
        param($FilePath)
        # Your fix logic here
        (Get-Content $FilePath) -replace 'old-pattern', 'new-pattern' | Set-Content $FilePath
    } `
    -Description "fix: standardize module imports" `
    -CreateBackup
```

### 4. Error Handling and Issue Tracking

#### Monitored Execution with Auto-Issue Creation
```powershell
Invoke-MonitoredExecution `
    -ScriptBlock {
        # Your risky operation here
        Import-Module "SomeModule" -Force
        Invoke-SomeOperation
    } `
    -ErrorHandling "CreateIssue" `
    -Context "Module import testing"
```

#### Manual Error Tracking
```powershell
try {
    # Some operation
} catch {
    Invoke-AutomatedErrorTracking `
        -SourceFunction "MyFunction" `
        -ErrorRecord $_ `
        -Context "Manual testing" `
        -Priority "High" `
        -AlwaysCreateIssue
}
```

### 5. Rollback Operations

#### Quick Rollback Options
```powershell
# Rollback to last commit
Invoke-QuickRollback -RollbackType "LastCommit" -CreateBackup

# Rollback to specific commit
Invoke-QuickRollback -RollbackType "SpecificCommit" -TargetCommit "abc123def" -Force

# Emergency rollback
Invoke-PatchRollback -RollbackTarget "Emergency" -CreateBackup
```

### 6. Maintenance and Cleanup

#### Comprehensive Cleanup
```powershell
Invoke-ComprehensiveCleanup `
    -CleanupMode "Standard" `
    -ExcludePatterns @("*.log", "*.backup") `
    -DryRun
```

#### Unified Maintenance
```powershell
Invoke-UnifiedMaintenance -Mode "Full"
```

## Module Import Patterns

### Standard Module Import
```powershell
# Always import Logging first
Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force -ErrorAction SilentlyContinue

# Then import PatchManager
Import-Module "$env:PROJECT_ROOT/core-runner/modules/PatchManager" -Force

# Verify successful import
Get-Command Invoke-GitControlledPatch -ErrorAction SilentlyContinue
```

### Environment Setup
```powershell
# Set project root if not already set
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation'
}

# Initialize cross-platform environment
Initialize-CrossPlatformEnvironment
```

## Common Workflows

### 1. Feature Development Workflow
```powershell
# 1. Create feature branch and apply changes
Invoke-GitControlledPatch `
    -PatchDescription "feat(labrunner): add parallel execution support" `
    -PatchOperation {
        # Apply your feature changes
        Write-CustomLog "Implementing parallel execution..." -Level INFO
    } `
    -CreatePullRequest

# 2. Monitor for Copilot suggestions
Invoke-CopilotSuggestionHandler -PullRequestNumber 123 -AutoCommit

# 3. Validate and merge
# (Human review required before merge)
```

### 2. Bug Fix Workflow
```powershell
# 1. Create hotfix branch
Invoke-GitControlledPatch `
    -PatchDescription "fix(patchmanager): resolve import dependency issue" `
    -BaseBranch "main" `
    -Force `
    -CreatePullRequest

# 2. Apply fix with validation
Invoke-EnhancedPatchManager `
    -PatchDescription "fix(patchmanager): resolve import dependency issue" `
    -AutoValidate `
    -AutoResolveConflicts `
    -CreateIssue
```

### 3. Emergency Rollback Workflow
```powershell
# 1. Quick emergency rollback
Invoke-QuickRollback -RollbackType "Emergency" -CreateBackup

# 2. Validate system state
Invoke-EnhancedGitOperations -Operation "CheckoutMain" -ValidateAfter

# 3. Create issue for investigation
Invoke-ComprehensiveIssueTracking `
    -Operation "EmergencyRollback" `
    -Title "Emergency rollback performed" `
    -Priority "Critical"
```

## Testing PatchManager

### Unit Test Execution
```powershell
# Run specific PatchManager tests
Invoke-Pester -Path "tests/unit/modules/PatchManager/" -Output Detailed

# Run with tiered testing
Invoke-TieredPesterTests -Tier "Critical" -BlockOnFailure
```

### Integration Testing
```powershell
# Test PatchManager integration with other modules
Invoke-Pester -Path "tests/integration/" -Tag "PatchManager" -Output Detailed
```

## Development Standards

### Function Development
- **PowerShell Version**: Use `#Requires -Version 7.0` 
- **Cross-Platform**: Use forward slashes for paths, avoid Windows-specific cmdlets
- **Logging**: Use `Write-CustomLog` with levels: INFO, WARN, ERROR, SUCCESS, DEBUG
- **Error Handling**: Implement comprehensive try-catch with meaningful messages
- **Parameter Validation**: Use `[CmdletBinding(SupportsShouldProcess)]`

### Module Structure
```
PatchManager/
├── PatchManager.psd1          # Module manifest
├── PatchManager.psm1          # Main module file
├── Public/                    # Public functions
│   ├── Invoke-GitControlledPatch.ps1
│   ├── Invoke-EnhancedPatchManager.ps1
│   └── ...
└── Private/                   # Private helper functions
    ├── Initialize-CrossPlatformEnvironment.ps1
    └── ...
```

### Testing Standards
- **Pester 5.0+**: Use `#Requires -Module Pester`
- **Structure**: Describe-Context-It with BeforeAll/AfterAll
- **Mocking**: Mock `Write-CustomLog`, external commands, file operations
- **Cross-Platform**: Test on Windows, Linux, macOS
- **Coverage**: Minimum 80% code coverage

## Code Quality Checklist

- [ ] PowerShell 7.0+ compatibility verified
- [ ] Cross-platform path handling implemented
- [ ] Proper error handling with try-catch blocks
- [ ] Write-CustomLog used for all logging
- [ ] Module imports use absolute paths with -Force
- [ ] No emojis used (project policy)
- [ ] Parameter validation implemented
- [ ] SupportsShouldProcess used where appropriate
- [ ] Comprehensive help documentation included
- [ ] Pester tests cover success and failure scenarios

## Troubleshooting Common Issues

### Module Import Failures
```powershell
# Check if Logging module is available
if (-not (Get-Module Logging -ListAvailable)) {
    Write-Warning "Logging module not found. Check path: $env:PROJECT_ROOT/core-runner/modules/Logging"
}

# Manual path-based import
$loggingPath = Join-Path $env:PROJECT_ROOT "core-runner/modules/Logging"
Import-Module $loggingPath -Force -Global
```

### Git Operation Failures
```powershell
# Check git status
git status

# Resolve conflicts manually then continue
Invoke-EnhancedGitOperations -Operation "ResolveConflicts" -Force

# Emergency reset if needed
Invoke-QuickRollback -RollbackType "Emergency"
```

### Syntax Errors in Functions
```powershell
# Validate PowerShell syntax
Test-PowerShellSyntax -Path "path/to/file.ps1"

# Use script analyzer
Invoke-ScriptAnalyzer -Path "core-runner/modules/PatchManager/" -Recurse
```

## Quick Reference Commands

### Most Common Operations
```powershell
# Create branch and commit changes
git checkout -b "feat/new-feature"
git add .
git commit -m "feat(scope): description"
git push origin feat/new-feature

# Using PatchManager wrapper
Invoke-GitControlledPatch -PatchDescription "feat(scope): description" -CreatePullRequest

# Emergency rollback
Invoke-QuickRollback -RollbackType "Emergency" -CreateBackup

# Import modules safely
Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force -ErrorAction SilentlyContinue
Import-Module "$env:PROJECT_ROOT/core-runner/modules/PatchManager" -Force
```

### Environment Variables
```powershell
$env:PROJECT_ROOT = 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation'
$env:PWSH_MODULES_PATH = "$env:PROJECT_ROOT/core-runner/modules"
```

## Function Reference Quick Guide

### Main Functions
- **`Invoke-GitControlledPatch`** - Primary function for Git-controlled patching
- **`Invoke-EnhancedPatchManager`** - Enhanced patch management with auto-validation
- **`Invoke-EnhancedGitOperations`** - Enhanced Git operations with conflict resolution
- **`Invoke-MassFileFix`** - Apply fixes to multiple files
- **`Invoke-QuickRollback`** - Quick rollback operations
- **`Invoke-MonitoredExecution`** - Execute with automatic error tracking

### Utility Functions
- **`CreatePatchBranch`** - Basic branch creation
- **`CommitChanges`** - Basic commit operation
- **`Initialize-CrossPlatformEnvironment`** - Environment setup
- **`Invoke-ComprehensiveCleanup`** - System cleanup
- **`Invoke-AutomatedErrorTracking`** - Error tracking and issue creation

### Testing Functions
- **`Invoke-TieredPesterTests`** - Run tiered tests
- **`Test-PowerShellSyntax`** - Validate PowerShell syntax
- **`Invoke-PatchValidation`** - Validate patch operations

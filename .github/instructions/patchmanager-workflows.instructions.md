---
applyTo: "**/*.ps1"
description: "PatchManager workflows and common scenarios - UPDATED FOR CONSOLIDATED VERSION"
---

# PatchManager Workflows & Instructions (Consolidated v2.0)

This file provides comprehensive guidance for using the **NEW CONSOLIDATED PatchManager** in the OpenTofu Lab Automation project.

## 🎯 Core PatchManager Functions (4 Total)

### Main Workflow Function (Primary)

Use `Invoke-PatchWorkflow` for ALL patch operations - this is the single entry point:

```powershell
# Complete patch workflow with issue and PR creation
Invoke-PatchWorkflow -PatchDescription "Fix non-interactive mode issues" -PatchOperation {
    # Your code changes here
    Write-Host "Making changes..."
} -CreateIssue -CreatePR -Priority "Medium"

# Patch with testing validation
Invoke-PatchWorkflow -PatchDescription "Update module exports" -PatchOperation {
    # Code changes
    Update-ModuleManifest -Path "Module.psd1" -FunctionsToExport @("Function1")
} -TestCommands @("pwsh -Command 'Import-Module ./core-runner/modules/LabRunner -Force'") -CreateIssue -CreatePR

# Simple patch without GitHub integration
Invoke-PatchWorkflow -PatchDescription "Quick fix" -PatchOperation {
    # Your changes
} -DryRun
```

### Individual Component Functions

Use these for specific operations:

```powershell
# Create issue only
New-PatchIssue -Description "Fix module loading" -Priority "High" -AffectedFiles @("Module.psm1")

# Create PR only (with optional issue linking)
New-PatchPR -Description "Fix module loading" -BranchName "patch/fix-loading" -IssueNumber 123

# Rollback operations
Invoke-PatchRollback -RollbackType "LastCommit" -CreateBackup
Invoke-PatchRollback -RollbackType "SpecificCommit" -CommitHash "abc123def" -DryRun
```

## ⚠️ IMPORTANT: Legacy Functions Archived

**These functions are NO LONGER available** (moved to Legacy folder):

- ❌ `Invoke-SimplifiedPatchWorkflow` → Use `Invoke-PatchWorkflow`
- ❌ `Invoke-GitControlledPatch` → Use `Invoke-PatchWorkflow`
- ❌ `New-SimpleIssueForPatch` → Use `New-PatchIssue`
- ❌ `New-SimplePRForPatch` → Use `New-PatchPR`
- ❌ `Invoke-QuickRollback` → Use `Invoke-PatchRollback`
- ❌ All other legacy functions (23 total)

## Common Scenarios

### 1. Module Development & Testing

When working on modules, always use the new workflow:

```powershell
# Test a module change safely
Invoke-PatchWorkflow -PatchDescription "Update LabRunner exports" -PatchOperation {
    # Make your changes
    Update-ModuleManifest -Path "core-runner/modules/LabRunner/LabRunner.psd1" -FunctionsToExport @("Function1")
} -TestCommands @(
    "pwsh -Command 'Import-Module ./core-runner/modules/LabRunner -Force'",
    "pwsh -File ./tests/unit/modules/LabRunner/LabRunner.Tests.ps1"
) -CreateIssue -CreatePR
```

### 2. Non-Interactive Testing

For testing non-interactive scenarios:

```powershell
# Test core-runner in non-interactive mode
Invoke-PatchWorkflow -PatchDescription "Fix non-interactive mode" -PatchOperation {
    & "./core-runner/core_app/core-runner.ps1" -NonInteractive -Auto -WhatIf
} -TestCommands @("./test-noninteractive-fix.ps1 -TestMode All") -CreateIssue
```

### 3. Bulk Module Updates

When updating multiple modules:

```powershell
Invoke-PatchWorkflow -PatchDescription "Standardize module error handling" -PatchOperation {
    Get-ChildItem "core-runner/modules" -Filter "*.psm1" -Recurse | ForEach-Object {
        # Apply standardized error handling
        $content = Get-Content $_.FullName -Raw
        # Make updates...
        Set-Content $_.FullName -Value $updatedContent
    }
} -TestCommands @(
    "pwsh -File ./tests/Run-AllModuleTests.ps1",
    "pwsh -File ./tests/Run-BulletproofTests.ps1 -TestSuite Unit"
) -CreateIssue -CreatePR
```

### 4. Configuration Changes

For configuration file updates:

```powershell
Invoke-PatchWorkflow -PatchDescription "Update default configuration" -PatchOperation {
    $config = Get-Content "configs/default-config.json" | ConvertFrom-Json
    $config.newProperty = "newValue"
    $config | ConvertTo-Json -Depth 10 | Set-Content "configs/default-config.json"
} -TestCommands @(
    "pwsh -Command 'Test-Json (Get-Content configs/default-config.json -Raw)'",
    "pwsh -File ./core-runner/core_app/core-runner.ps1 -WhatIf -Auto"
) -CreateIssue -CreatePR
```

## VS Code Tasks Integration

Use these VS Code tasks for common PatchManager workflows:

- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Create Feature Patch"**
- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Test Current Changes"**
- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Emergency Rollback"**
- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Validate All Modules"**

## Best Practices

1. **Use the main workflow** for most patch operations: `Invoke-PatchWorkflow`
2. **Always use descriptive patch descriptions** that explain the what and why
3. **Create issues and PRs together** using `-CreateIssue -CreatePR` for proper auto-closing
4. **Include test commands** when possible to validate your changes
5. **Use DryRun mode first** to preview changes without executing them: `-DryRun`
6. **No emoji/Unicode output** - the new workflow follows project standards
7. **Explicit control** - create issues and PRs only when needed, not automatically

## Error Handling Patterns

```powershell
# Pattern 1: Safe execution with rollback
try {
    Invoke-PatchWorkflow -PatchDescription "Risky change" -PatchOperation {
        # Risky code here
    } -TestCommands @("validation-command") -CreateIssue
} catch {
    Write-Error "Patch failed: $($_.Exception.Message)"
    # Use rollback if needed
    Invoke-PatchRollback -RollbackType "LastCommit" -CreateBackup
}

# Pattern 2: Emergency rollback
Invoke-PatchRollback -RollbackType "LastCommit" -CreateBackup -Force
```

## Testing Integration

Always run these tests after PatchManager operations:

```powershell
# Quick validation
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "Unit" -CI

# Full validation
pwsh -File "./tests/Run-AllModuleTests.ps1" -Parallel

# Core-runner specific tests
pwsh -File "./test-noninteractive-fix.ps1" -TestMode All
```

## Log File Locations

PatchManager operations create logs in:

- `logs/patchmanager-operations-{date}.log`
- `logs/automated-error-tracking.json`

Always check these logs after operations for detailed execution information.

Always use PowerShell 7.0+ cross-platform syntax with forward slashes for paths.

---
applyTo: "**/*.ps1"
description: "PatchManager workflows and common scenarios"
---

# PatchManager Workflows & Instructions

This file provides comprehensive guidance for using PatchManager effectively in the OpenTofu Lab Automation project.

## Core PatchManager Commands

### Simplified Patch Workflow (Recommended)
Use `Invoke-SimplifiedPatchWorkflow` for clean, focused patch operations:

```powershell
# Basic patch with issue and PR creation
Invoke-SimplifiedPatchWorkflow -PatchDescription "Fix non-interactive mode issues" -PatchOperation {
    # Your code changes here
    Write-Host "Making changes..."
} -CreateIssue -CreatePullRequest -Priority "Medium"

# Patch with testing
Invoke-SimplifiedPatchWorkflow -PatchDescription "Update module exports" -PatchOperation {
    # Code changes
} -TestCommands @("pwsh -Command 'Import-Module ./core-runner/modules/LabRunner -Force'") -CreateIssue -CreatePullRequest
```

### Individual Components (Advanced Use)
Use these for granular control:

```powershell
# Create issue only
New-SimpleIssueForPatch -PatchDescription "Fix module loading" -Priority "High"

# Create PR only (with issue linking)
New-SimplePRForPatch -PatchDescription "Fix module loading" -BranchName "patch/fix-loading" -IssueNumber 123
```

### Legacy Git-Controlled Patching (Still Supported)
Use `Invoke-GitControlledPatch` for backward compatibility:

```powershell
# Basic patch workflow
Invoke-GitControlledPatch -PatchDescription "Fix non-interactive mode issues" -PatchOperation {
    # Your code changes here
    Write-Host "Making changes..."
} -TestCommands @("pwsh -Command 'Import-Module ./core-runner/modules/LabRunner -Force'")
```

## Common Scenarios

### 1. Module Development & Testing
When working on modules, always use git-controlled patches:

```powershell
# Test a module change safely
Invoke-GitControlledPatch -PatchDescription "Update LabRunner exports" -PatchOperation {
    # Make your changes
    Add-Content -Path "core-runner/modules/LabRunner/LabRunner.psm1" -Value "# New function"
} -TestCommands @(
    "pwsh -Command 'Import-Module ./core-runner/modules/LabRunner -Force'",
    "pwsh -File ./tests/unit/modules/LabRunner/LabRunner.Tests.ps1"
)
```

### 2. Non-Interactive Testing
For testing non-interactive scenarios:

```powershell
# Test core-runner in non-interactive mode with monitoring
Invoke-MonitoredExecution -ScriptBlock {
    & "./core-runner/core_app/core-runner.ps1" -NonInteractive -Auto -WhatIf
} -Context @{TestType = "NonInteractive"; Component = "CoreRunner"} -CreateIssues
```

### 3. Bulk Module Updates
When updating multiple modules:

```powershell
Invoke-GitControlledPatch -PatchDescription "Standardize module error handling" -PatchOperation {
    Get-ChildItem "core-runner/modules" -Filter "*.psm1" -Recurse | ForEach-Object {
        # Apply standardized error handling
        $content = Get-Content $_.FullName -Raw
        # Make updates...
        Set-Content $_.FullName -Value $updatedContent
    }
} -TestCommands @(
    "pwsh -File ./tests/Run-AllModuleTests.ps1",
    "pwsh -File ./tests/Run-BulletproofTests.ps1 -TestSuite Unit"
)
```

### 4. Configuration Changes
For configuration file updates:

```powershell
Invoke-GitControlledPatch -PatchDescription "Update default configuration" -PatchOperation {
    $config = Get-Content "configs/default-config.json" | ConvertFrom-Json
    $config.newProperty = "newValue"
    $config | ConvertTo-Json -Depth 10 | Set-Content "configs/default-config.json"
} -TestCommands @(
    "pwsh -Command 'Test-Json (Get-Content configs/default-config.json -Raw)'",
    "pwsh -File ./core-runner/core_app/core-runner.ps1 -WhatIf -Auto"
)
```

## VS Code Tasks Integration

Use these VS Code tasks for common PatchManager workflows:

- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Create Feature Patch"**
- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Test Current Changes"**
- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Emergency Rollback"**
- **Ctrl+Shift+P → Tasks: Run Task → "PatchManager: Validate All Modules"**

## Best Practices

1. **Use the simplified workflow** for most patch operations: `Invoke-SimplifiedPatchWorkflow`
2. **Always use descriptive patch descriptions** that explain the what and why
3. **Create issues and PRs together** using `-CreateIssue -CreatePullRequest` for proper auto-closing
4. **Include test commands** when possible to validate your changes
5. **Use DryRun mode first** to preview changes without executing them: `-DryRun`
6. **No emoji/Unicode output** - the simplified workflow follows project standards
7. **Explicit control** - create issues and PRs only when needed, not automatically

## Error Handling Patterns

```powershell
# Pattern 1: Safe execution with rollback
try {
    Invoke-GitControlledPatch -PatchDescription "Risky change" -PatchOperation {
        # Risky code here
    } -TestCommands @("validation-command")
} catch {
    Write-Error "Patch failed: $($_.Exception.Message)"
    # Manual rollback if needed
}

# Pattern 2: Monitored execution with issue creation
Invoke-MonitoredExecution -ScriptBlock {
    # Code that might fail
} -ErrorHandling "Comprehensive" -CreateIssues -Context @{
    Component = "PatchManager"
    Operation = "TestOperation"
    Environment = "Development"
}
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
- `logs/monitored-execution-{date}.log`
- `logs/automated-error-tracking.json`

Always check these logs after operations for detailed execution information.

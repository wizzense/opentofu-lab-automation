---
applyTo: "**/*.ps1"
description: "PatchManager workflows and common scenarios"
---

# PatchManager Workflows & Instructions

This file provides comprehensive guidance for using PatchManager effectively in the OpenTofu Lab Automation project.

## Core PatchManager Commands

### Git-Controlled Patching
Use `Invoke-GitControlledPatch` for safe, tracked changes:

```powershell
# Basic patch workflow
Invoke-GitControlledPatch -PatchDescription "Fix non-interactive mode issues" -PatchOperation {
    # Your code changes here
    Write-Host "Making changes..."
} -TestCommands @("pwsh -Command 'Import-Module ./core-runner/modules/LabRunner -Force'")

# Advanced patch with auto-commit
Invoke-GitControlledPatch -PatchDescription "Update module exports" -PatchOperation {
    # Code changes
} -AutoCommitUncommitted -CreatePullRequest
```

### Monitored Execution
Use `Invoke-MonitoredExecution` for error tracking:

```powershell
Invoke-MonitoredExecution -ScriptBlock {
    # Risky operations
    Import-Module SomeModule -Force
} -Context @{Operation = "Module Import"; Component = "Testing"} -CreateIssues
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

1. **Always use descriptive patch descriptions** that explain the what and why
2. **Include comprehensive test commands** that validate your changes
3. **Use WhatIf mode first** to preview changes without executing them
4. **Test non-interactive scenarios** especially for core-runner changes
5. **Capture error context** with monitored execution for debugging
6. **Create issues automatically** for tracking recurring problems

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

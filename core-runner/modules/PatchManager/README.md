# PatchManager Module

Simplified and reliable patch management with 4 core functions: workflow orchestration, issue creation, PR creation, and rollback capabilities.

## Overview

The PatchManager module (v2.1) provides a streamlined approach to managing code changes with automatic Git operations, GitHub integration, and comprehensive error handling. It handles dirty working trees automatically and creates issues by default for proper tracking.

## Features

- **One-command workflow** - Single function handles entire patch process
- **Automatic dirty tree handling** - No more failures on uncommitted changes
- **Default issue creation** - Tracks all changes unless explicitly disabled
- **Unicode sanitization** - Removes problematic characters automatically
- **PR integration** - Links pull requests to issues automatically
- **Rollback support** - Easy recovery from failed changes
- **Cross-platform** - Works on Windows, Linux, and macOS

## Installation

The module is automatically available when you import it:

```powershell
Import-Module "./core-runner/modules/PatchManager" -Force
```

## Core Functions (4 Total)

### Invoke-PatchWorkflow

Main workflow function - your single entry point for all patch operations.

```powershell
# Complete patch workflow with automatic handling
Invoke-PatchWorkflow -PatchDescription "Fix module loading" -PatchOperation {
    # Your code changes here
    $content = Get-Content "module.ps1" -Raw
    $content = $content -replace "old", "new"
    Set-Content "module.ps1" -Value $content
} -CreatePR

# Simple local patch without GitHub integration
Invoke-PatchWorkflow -PatchDescription "Quick local fix" -CreateIssue:$false -PatchOperation {
    # Your changes
}

# Patch with testing validation
Invoke-PatchWorkflow -PatchDescription "Update exports" -PatchOperation {
    Update-ModuleManifest -Path "Module.psd1" -FunctionsToExport @("New-Function")
} -TestCommands @("pwsh -Command 'Import-Module ./Module -Force'") -CreatePR

# Emergency patch with high priority
Invoke-PatchWorkflow -PatchDescription "Critical security fix" -PatchOperation {
    # Critical changes
} -CreatePR -Priority "Critical"

# Dry run to preview changes
Invoke-PatchWorkflow -PatchDescription "Test changes" -PatchOperation {
    # Changes to preview
} -DryRun
```

**Parameters:**
- **PatchDescription** (Required): Description of what the patch does
- **PatchOperation** (Required): ScriptBlock containing your changes
- **CreatePR**: Create pull request after changes (default: false)
- **CreateIssue**: Create GitHub issue for tracking (default: true)
- **Priority**: Issue priority - Low, Medium, High, Critical (default: Medium)
- **TestCommands**: Array of commands to validate changes
- **DryRun**: Preview changes without executing

**Key Features:**
- ✅ Auto-commits existing changes before starting
- ✅ Creates branch automatically
- ✅ Creates issue by default (unless `-CreateIssue:$false`)
- ✅ Sanitizes Unicode/emoji characters
- ✅ Commits your changes
- ✅ Optionally creates linked PR

### New-PatchIssue

Creates a GitHub issue for tracking changes.

```powershell
# Create issue for patch tracking
$issueNumber = New-PatchIssue -Description "Fix module loading" -Priority "High"

# Create issue with affected files list
New-PatchIssue -Description "Update exports" -AffectedFiles @("Module.psm1", "Module.psd1")

# Create low-priority issue
New-PatchIssue -Description "Refactor helper functions" -Priority "Low"
```

**Parameters:**
- **Description** (Required): Issue description
- **Priority**: Low, Medium, High, Critical (default: Medium)
- **AffectedFiles**: Array of files that will be changed

**Returns:** Issue number (integer)

### New-PatchPR

Creates a pull request, optionally linking to an issue.

```powershell
# Create PR without issue
New-PatchPR -Description "Fix module loading" -BranchName "patch/fix-loading"

# Create PR linked to issue
New-PatchPR -Description "Fix module loading" -BranchName "patch/fix-loading" -IssueNumber 123

# Create PR with custom parameters
New-PatchPR -Description "Major refactor" -BranchName "patch/refactor" -Base "develop"
```

**Parameters:**
- **Description** (Required): PR description
- **BranchName** (Required): Name of the branch for PR
- **IssueNumber**: Issue number to link (automatically closes on merge)
- **Base**: Base branch for PR (default: main)

**Returns:** PR number (integer)

### Invoke-PatchRollback

Rolls back changes when needed.

```powershell
# Rollback last commit
Invoke-PatchRollback -RollbackType "LastCommit" -CreateBackup

# Rollback to specific commit
Invoke-PatchRollback -RollbackType "SpecificCommit" -CommitHash "abc123def"

# Preview rollback without executing
Invoke-PatchRollback -RollbackType "LastCommit" -DryRun

# Rollback branch (delete branch)
Invoke-PatchRollback -RollbackType "Branch" -BranchName "patch/failed-attempt"

# Force rollback without confirmation
Invoke-PatchRollback -RollbackType "LastCommit" -Force
```

**Rollback Types:**
- **LastCommit**: Undo the most recent commit
- **SpecificCommit**: Revert to a specific commit
- **Branch**: Delete a branch (local and optionally remote)
- **WorkingTree**: Reset working tree to last commit

**Parameters:**
- **RollbackType** (Required): Type of rollback to perform
- **CommitHash**: Hash for SpecificCommit rollback
- **BranchName**: Branch name for Branch rollback
- **CreateBackup**: Create backup before rollback
- **DryRun**: Preview rollback without executing
- **Force**: Skip confirmation prompts

## Key Improvements in v2.1

### ✅ Automatic Dirty Working Tree Handling
No more failures when you have uncommitted changes:

```powershell
# Before v2.1: Would fail if you had uncommitted changes
# After v2.1: Automatically commits existing changes first

Invoke-PatchWorkflow -PatchDescription "My fix" -PatchOperation {
    # Your changes
}
# ✅ Auto-commits any existing changes, then applies your patch
```

### ✅ Issue Creation by Default
Issues are created automatically unless you explicitly disable:

```powershell
# Creates issue automatically
Invoke-PatchWorkflow -PatchDescription "Fix bug" -PatchOperation { ... }

# Disable issue creation for quick local changes
Invoke-PatchWorkflow -PatchDescription "Local test" -CreateIssue:$false -PatchOperation { ... }
```

### ✅ Unicode Sanitization
Automatically removes problematic Unicode and emoji characters:

```powershell
# Files are automatically sanitized before committing
# No more PowerShell 5.1 compatibility issues
# No emoji in commit messages or file content
```

## Usage Examples

### Quick Bug Fix

```powershell
# Import module
Import-Module "./core-runner/modules/PatchManager" -Force

# Fix and create PR in one command
Invoke-PatchWorkflow -PatchDescription "Fix parameter validation" -PatchOperation {
    $content = Get-Content "./MyScript.ps1" -Raw
    $content = $content -replace '\[ValidateNotNull\]', '[ValidateNotNullOrEmpty()]'
    Set-Content "./MyScript.ps1" -Value $content
} -CreatePR
```

### Feature Development

```powershell
# Develop feature with testing
Invoke-PatchWorkflow -PatchDescription "Add new configuration validator" -PatchOperation {
    # Create new function file
    @'
function Test-Configuration {
    param([string]$Path)
    # Implementation
}
'@ | Set-Content "./Public/Test-Configuration.ps1"
    
    # Update manifest
    Update-ModuleManifest -Path "./Module.psd1" -FunctionsToExport @("Test-Configuration")
} -TestCommands @(
    "pwsh -Command 'Import-Module ./Module -Force'",
    "pwsh -File ./tests/Test-Configuration.Tests.ps1"
) -CreatePR -Priority "Medium"
```

### Emergency Hotfix

```powershell
# Critical fix with high priority
Invoke-PatchWorkflow -PatchDescription "Fix security vulnerability in auth" -PatchOperation {
    # Security fix
    $content = Get-Content "./Auth.ps1" -Raw
    $content = $content -replace 'ConvertTo-SecureString -AsPlainText', 'ConvertTo-SecureString -AsPlainText -Force'
    Set-Content "./Auth.ps1" -Value $content
} -CreatePR -Priority "Critical"
```

### Local Experimentation

```powershell
# Quick local test without GitHub tracking
Invoke-PatchWorkflow -PatchDescription "Test new approach" -CreateIssue:$false -PatchOperation {
    # Experimental changes
    Write-Host "Testing new implementation..."
}
```

### Rollback Failed Changes

```powershell
# If patch fails or causes issues
Invoke-PatchRollback -RollbackType "LastCommit" -CreateBackup

# Or rollback to specific working state
Invoke-PatchRollback -RollbackType "SpecificCommit" -CommitHash "abc123" -DryRun  # Preview first
Invoke-PatchRollback -RollbackType "SpecificCommit" -CommitHash "abc123"  # Execute
```

## Integration with Core Runner

PatchManager works seamlessly with the core runner:

```powershell
# Run core runner after patch
./core-runner.ps1 -NonInteractive -Scripts "0200_Get-SystemInfo" -Verbosity detailed
```

## Workflow Philosophy

### Before v2.1 (Multi-step, failure-prone)
```powershell
git add .
git commit -m "Save work"  # Manual step
Invoke-PatchWorkflow ...   # Could fail on dirty tree
```

### After v2.1 (Single-step, always works)
```powershell
Invoke-PatchWorkflow -PatchDescription "Fix it" -PatchOperation { ... } -CreatePR
# ✅ Handles everything automatically
```

## Best Practices

1. **Use descriptive patch descriptions** - Explain what and why
2. **Include test commands** when possible to validate changes
3. **Create PRs for team review** using `-CreatePR`
4. **Use DryRun first** for complex changes: `-DryRun`
5. **Disable issue creation** only for quick local experiments: `-CreateIssue:$false`
6. **Set appropriate priority** for proper triage
7. **Always backup before rollback** using `-CreateBackup`

## Error Handling

All functions include comprehensive error handling:

```powershell
try {
    Invoke-PatchWorkflow -PatchDescription "Complex change" -PatchOperation {
        # Complex operations
    } -CreatePR
} catch {
    Write-Error "Patch failed: $($_.Exception.Message)"
    
    # Rollback if needed
    Invoke-PatchRollback -RollbackType "LastCommit" -CreateBackup
}
```

## Log File Locations

PatchManager operations create logs in:

- **Operations log**: `logs/patchmanager-operations-{date}.log`
- **Error tracking**: `logs/automated-error-tracking.json`

## Configuration Requirements

PatchManager requires:

- **Git installed** and in PATH
- **GitHub CLI (gh)** for issue/PR creation
- **Write access** to repository
- **Valid Git configuration** (user.name, user.email)

## Testing Integration

Test your changes after patching:

```powershell
# Quick validation
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "Unit"

# Full validation
pwsh -File "./tests/Run-AllModuleTests.ps1" -Parallel

# Core runner tests
pwsh -File "./test-noninteractive-fix.ps1" -TestMode "All"
```

## Troubleshooting

### Patch workflow fails
- Check Git status: `git status`
- Verify GitHub authentication: `gh auth status`
- Review logs in `logs/patchmanager-operations-*.log`

### Issue creation fails
- Verify GitHub CLI is installed: `gh --version`
- Check authentication: `gh auth login`
- Verify repository permissions

### PR creation fails
- Ensure branch is pushed: `git push origin branch-name`
- Check if PR already exists: `gh pr list`
- Verify base branch exists

## Legacy Functions

**Note:** PatchManager v2.0 consolidated 23 legacy functions into 4 core functions. Legacy functions are archived in the `Legacy/` folder but are no longer maintained or exported.

## Version History

- **2.1.0**: Auto-commit dirty trees, default issue creation, improved workflow
- **2.0.0**: Consolidated to 4 core functions, improved reliability
- **1.0.0**: Initial release with multiple specialized functions

## Related Modules

- [Logging](../Logging/) - Used for all PatchManager operations
- [TestingFramework](../TestingFramework/) - Validate changes after patching
- [UnifiedMaintenance](../UnifiedMaintenance/) - Maintenance integration

## Contributing

When adding new PatchManager features:

1. Maintain backward compatibility with existing workflows
2. Follow Git best practices for all operations
3. Include comprehensive error handling
4. Test with both local and GitHub scenarios
5. Update this README and `.github/instructions/patchmanager-workflows.instructions.md`

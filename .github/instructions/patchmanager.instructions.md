# PatchManager Module Development Standards

## Overview
This document outlines the standards and best practices for developing and testing the PatchManager module in the OpenTofu Lab Automation project.

## Development Standards
- **PowerShell Version**: Ensure compatibility with PowerShell 7.0+.
- **Cross-Platform**: Use forward slashes for paths and avoid Windows-specific cmdlets.
- **Module Structure**:
  - Public functions in `Public/` subfolder.
  - Private helper functions in `Private/` subfolder.
  - Module manifest file (.psd1) with proper metadata.
  - Module script file (.psm1) exporting public functions.
- **Logging**: Use `Write-CustomLog` for all logging with appropriate levels (INFO, WARN, ERROR, SUCCESS).
- **Error Handling**: Implement try-catch blocks with meaningful error messages.
- **Parameter Validation**: Use `[CmdletBinding(SupportsShouldProcess)]` and proper parameter validation.

## Testing Standards
- **Pester Tests**:
  - Use Pester 5.0+ with `#Requires -Module Pester`.
  - Follow Describe-Context-It structure with BeforeAll/AfterAll setup.
  - Test both success and failure scenarios.
  - Mock external dependencies like file operations and system commands.
- **Cross-Platform Testing**:
  - Validate functionality on Windows, Linux, and macOS.
  - Use TestDrive for temporary file operations.
- **Logging Tests**:
  - Mock `Write-CustomLog` to validate logging behavior.

## Documentation
- Include comprehensive help documentation for all public functions.
- Add usage examples in the module-level README.md.
- Document dependencies and prerequisites.

## Code Quality
- Verify adherence to project coding standards.
- Ensure proper error handling and logging implementation.
- Validate module imports use absolute paths and the `-Force` parameter.
- Check for proper parameter validation and SupportsShouldProcess usage.

## Commit Standards
- Use conventional commit format: `type(scope): description`.
- Reference `patchmanager` in the scope.
- Keep descriptions concise and professional.

## PatchManager Usage Guide

### Environment Setup
```powershell
# 1. Set environment variables (if not already set)
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = (Get-Location).Path  # Or your project root
}
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = "$env:PROJECT_ROOT/core-runner/modules"
}

# 2. Import required modules in order
Import-Module "$env:PWSH_MODULES_PATH/Logging" -Force
Import-Module "$env:PWSH_MODULES_PATH/PatchManager" -Force

# 3. Verify module loading
Get-Module PatchManager | Select-Object Name, Version, ModuleBase
```

### Quick Setup and Common Operations

#### Essential Environment Setup
```powershell
# Always use environment variables instead of hardcoded paths
$env:PROJECT_ROOT = if ($env:PROJECT_ROOT) { $env:PROJECT_ROOT } else { (Get-Location).Path }
$env:PWSH_MODULES_PATH = "$env:PROJECT_ROOT/core-runner/modules"

# Import modules with proper error handling
Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force -ErrorAction SilentlyContinue
Import-Module "$env:PROJECT_ROOT/core-runner/modules/PatchManager" -Force
```

#### Most Common Git Operations
```powershell
# 1. Quick branch and commit workflow
git checkout -b "feat/$(Get-Date -Format 'yyyyMMdd')-description"
git add .
git commit -m "feat(scope): description of changes"
git push origin feat/$(Get-Date -Format 'yyyyMMdd')-description

# 2. Using PatchManager functions
Invoke-GitControlledPatch -PatchDescription "feat(module): implement functionality" -CreatePullRequest

# 3. Enhanced operations with conflict resolution
Invoke-EnhancedGitOperations -Operation "MergeMain" -ValidateAfter
```

### Common PatchManager Operations

#### Quick Git Workflow (Recommended)
```powershell
# 1. Create feature branch
git checkout -b "feat/your-feature-name"

# 2. Make your changes, then stage and commit
git add .
git commit -m "feat(scope): your description following conventional commits"

# 3. Push branch
git push origin feat/your-feature-name
```

#### Using PatchManager Functions
```powershell
# 1. Git-controlled patch with automatic branch creation
Invoke-GitControlledPatch -PatchDescription "fix: resolve module import issues" -CreatePullRequest

# 2. Enhanced git operations with conflict resolution
Invoke-EnhancedGitOperations -Operation "MergeMain" -ValidateAfter

# 3. Quick commit with validation
$commitMessage = "feat(patchmanager): add new validation feature"
git add .
git commit -m $commitMessage
```

#### Branch Management
```powershell
# Create patch branch using PatchManager functions
. "$env:PWSH_MODULES_PATH/PatchManager/Public/GitOperations.ps1"
CreatePatchBranch -BranchName "feat/new-feature" -BaseBranch "main"

# Commit changes
CommitChanges -CommitMessage "feat(scope): your change description"
```

### Troubleshooting Common Issues

#### Module Import Problems
```powershell
# Check environment variables
Write-Host "PROJECT_ROOT: $env:PROJECT_ROOT"
Write-Host "PWSH_MODULES_PATH: $env:PWSH_MODULES_PATH"

# Verify paths exist
Test-Path "$env:PWSH_MODULES_PATH/Logging"
Test-Path "$env:PWSH_MODULES_PATH/PatchManager"

# Force reimport if needed
Remove-Module PatchManager -Force -ErrorAction SilentlyContinue
Remove-Module Logging -Force -ErrorAction SilentlyContinue
Import-Module "$env:PWSH_MODULES_PATH/Logging" -Force
Import-Module "$env:PWSH_MODULES_PATH/PatchManager" -Force
```

#### Git Operation Issues
```powershell
# Check git status and resolve conflicts
git status
git fetch origin main

# Use enhanced git operations for automatic resolution
Invoke-EnhancedGitOperations -Operation "ResolveConflicts" -Force
```

### Best Practices
- Always use `$env:PROJECT_ROOT` and `$env:PWSH_MODULES_PATH` instead of hardcoded paths
- Import Logging module before PatchManager (dependency requirement)
- Use conventional commit format: `type(scope): description`
- Test module imports before using PatchManager functions
- Use `-Force` parameter when importing modules for consistent behavior

## Additional Notes
- Follow the project's no-emoji policy
- Use environment variables for all paths to ensure cross-platform compatibility
- Always verify module loading before executing PatchManager operations

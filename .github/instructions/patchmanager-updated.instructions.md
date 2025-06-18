---
applyTo: "**/PatchManager/**"
description: "PatchManager development standards and usage guide"
---

# PatchManager Module Development Standards

## Overview
This document outlines the standards and best practices for developing and testing the PatchManager module in the OpenTofu Lab Automation project.

**📖 For comprehensive usage examples and workflows, see:** [patchmanager-comprehensive.instructions.md](./patchmanager-comprehensive.instructions.md)

## Quick Reference

### Most Common PatchManager Operations
```powershell
# 1. Standard Git workflow with PatchManager
git checkout -b "feat/your-feature"
git add .
git commit -m "feat(scope): description"
git push origin feat/your-feature

# 2. Or use PatchManager wrapper
Invoke-GitControlledPatch -PatchDescription "feat(scope): description" -CreatePullRequest

# 3. Emergency rollback
Invoke-QuickRollback -RollbackType "Emergency" -CreateBackup
```

### Required Module Import Pattern
```powershell
$env:PROJECT_ROOT = 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation'
Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force -ErrorAction SilentlyContinue
Import-Module "$env:PROJECT_ROOT/core-runner/modules/PatchManager" -Force
```

## Development Standards

### PowerShell Standards
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

### Code Quality Requirements
- [ ] PowerShell 7.0+ compatibility verified
- [ ] Cross-platform path handling implemented
- [ ] Proper error handling with try-catch blocks
- [ ] Write-CustomLog used for all logging
- [ ] Module imports use absolute paths with -Force
- [ ] No emojis used (project policy)
- [ ] Parameter validation implemented
- [ ] SupportsShouldProcess used where appropriate

## Testing Standards

### Pester Testing
- **Pester 5.0+**: Use `#Requires -Module Pester` and `#Requires -Version 7.0`
- **Structure**: Describe-Context-It with BeforeAll/AfterAll setup
- **Mocking**: Mock `Write-CustomLog`, external commands, file operations
- **Cross-Platform**: Test on Windows, Linux, macOS
- **Coverage**: Minimum 80% code coverage

### Test Execution
```powershell
# Run PatchManager tests
Invoke-Pester -Path "tests/unit/modules/PatchManager/" -Output Detailed

# Run with tiered testing
Invoke-TieredPesterTests -Tier "Critical" -BlockOnFailure
```

## Documentation Requirements
- Include comprehensive help documentation for all public functions
- Add usage examples in function help
- Document dependencies and prerequisites
- Maintain README.md with current examples

## Commit Standards
- Use conventional commit format: `type(scope): description`
- Common types: feat, fix, docs, style, refactor, test, chore
- Reference `patchmanager` in scope when appropriate
- Keep descriptions concise and professional (no emojis)

## Environment Variables
```powershell
$env:PROJECT_ROOT = 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation'
$env:PWSH_MODULES_PATH = "$env:PROJECT_ROOT/core-runner/modules"
```

## Key Functions Reference
- **`Invoke-GitControlledPatch`** - Primary Git-controlled patching function
- **`Invoke-EnhancedPatchManager`** - Enhanced patch management with auto-validation
- **`Invoke-QuickRollback`** - Emergency rollback operations
- **`CreatePatchBranch`** & **`CommitChanges`** - Basic Git operations
- **`Invoke-MonitoredExecution`** - Execute with automatic error tracking

## Additional Resources
- **Comprehensive Guide**: [patchmanager-comprehensive.instructions.md](./patchmanager-comprehensive.instructions.md)
- **Quick Reference**: [.github/prompts/patchmanager-quick-reference.prompt.md](../prompts/patchmanager-quick-reference.prompt.md)
- **Testing Instructions**: [comprehensive-testing.instructions.md](./comprehensive-testing.instructions.md)

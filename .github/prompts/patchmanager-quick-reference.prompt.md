# PatchManager Development Prompt

## Quick PatchManager Usage Reference

When working with PatchManager, use these common patterns:

### Basic Git Operations
```powershell
# Create branch and commit changes (most common)
git checkout -b "feat/your-feature-name"
git add .
git commit -m "feat(scope): description"
git push origin feat/your-feature-name

# Or use PatchManager wrapper
Invoke-GitControlledPatch -PatchDescription "feat(scope): description" -CreatePullRequest
```

### Module Import (Always do this first)
```powershell
# Set environment and import modules
$env:PROJECT_ROOT = 'c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation'
Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force -ErrorAction SilentlyContinue
Import-Module "$env:PROJECT_ROOT/core-runner/modules/PatchManager" -Force
```

### Emergency Rollback
```powershell
# If something goes wrong
Invoke-QuickRollback -RollbackType "Emergency" -CreateBackup
```

### Function Development Standards
- Use `#Requires -Version 7.0`
- Use `Write-CustomLog` for all logging
- Use `[CmdletBinding(SupportsShouldProcess)]` for functions
- Forward slashes for paths (cross-platform)
- No emojis (project policy)
- Comprehensive error handling with try-catch

### Testing
```powershell
# Run PatchManager tests
Invoke-Pester -Path "tests/unit/modules/PatchManager/" -Output Detailed
```

For comprehensive documentation, see: `.github/instructions/patchmanager-comprehensive.instructions.md`

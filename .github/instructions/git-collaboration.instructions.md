---
applyTo: "**"
description: Git workflow, branch management, and GitHub collaboration standards
---

# Git and GitHub Collaboration Instructions

## Quick Reference

### Branch Management
- **Create Feature Branch**: Use PatchManager module: `Import-Module "/pwsh/modules/PatchManager/" -Force; Invoke-GitControlledPatch -PatchDescription "feature: <description>" -PatchOperation { <your-changes> } -CreatePullRequest -Force`
- **Comprehensive Cleanup**: Use enhanced PatchManager: `Invoke-GitControlledPatch -PatchDescription "chore: comprehensive cleanup" -PatchOperation { <cleanup-code> } -CleanupMode "Standard" -CreatePullRequest -Force`
- **Emergency Cleanup**: For critical issues: `Invoke-GitControlledPatch -PatchDescription "fix: emergency cleanup" -PatchOperation { <fixes> } -CleanupMode "Emergency" -CreatePullRequest -Force`
- **Safe Mode**: For cautious cleanup: `Invoke-GitControlledPatch -PatchDescription "chore: safe cleanup" -PatchOperation { <changes> } -CleanupMode "Safe" -CreatePullRequest -Force`

### Commit Standards
| **Type**   | **Scope**       | **Example**                                |
|------------|-----------------|--------------------------------------------|
| feat       | codefixer       | feat(codefixer): add parallel processing   |
| fix        | labrunner       | fix(labrunner): resolve path issues        |
| docs       | readme          | docs(readme): update installation guide    |
| chore      | deps            | chore(deps): update dependencies           |

### Pre-Commit Validation
Run:
```powershell
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
Invoke-PowerShellLint -Path "./scripts/" -Parallel
```

## Detailed Instructions

### Branch Naming Conventions
Use clear, descriptive names:
- **Feature**: `feature/add-security-validation`
- **Bug Fix**: `fix/module-loading-error`
- **Documentation**: `docs/update-api-documentation`
- **Maintenance**: `chore/update-dependencies`
- **Hotfix**: `hotfix/critical-security-patch`

### Pull Request Workflow
Include:
```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Comprehensive cleanup

## Validation Checklist
- [ ] Pre-commit validation passed
- [ ] PowerShell linting passed
- [ ] YAML validation passed
- [ ] Cross-platform path issues fixed
- [ ] Emoji violations removed
- [ ] Duplicate files consolidated

## Cleanup Details (if applicable)
- **Cleanup Mode**: Standard/Aggressive/Emergency/Safe
- **Files Removed**: [number]
- **Directories Cleaned**: [number]
- **Size Reclaimed**: [amount]
- **Cross-Platform Fixes**: [count]
```

### Cleanup Modes
| **Mode** | **File Age Threshold** | **Aggressiveness** | **Use Case** |
|----------|----------------------|-------------------|--------------|
| Safe | 90 days | Low | Cautious cleanup, preserve most files |
| Standard | 30 days | Medium | Regular maintenance cleanup |
| Aggressive | 7 days | High | Major cleanup, remove recent unused files |
| Emergency | 1 day | Very High | Crisis cleanup, remove almost everything unused |

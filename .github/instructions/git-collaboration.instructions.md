---
applyTo: "**"
description: Git workflow, branch management, and GitHub collaboration standards
---

# Git and GitHub Collaboration Instructions

## Quick Reference

### Branch Management
- **Create Feature Branch**: `git checkout -b feature/<description>`
- **Push Feature Branch**: `git push -u origin feature/<description>`
- **Create Pull Request**: `gh pr create --title "feat(scope): description" --body "Detailed description"`

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

## Validation Checklist
- [ ] Pre-commit validation passed
- [ ] PowerShell linting passed
- [ ] YAML validation passed
```

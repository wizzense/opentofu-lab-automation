---
applyTo: "**"
description: Git workflow, branch management, and GitHub collaboration standards
---

# Git and GitHub Collaboration Instructions

## Quick Reference

### Branch Management
- **SAFE Auto-Commit Mode**: Works from current branch, never touches main: `Invoke-GitControlledPatch -PatchDescription "feature: <description>" -PatchOperation { <your-changes> } -AutoCommitUncommitted -CreatePullRequest`
- **Direct Commit (Current Branch)**: Safe commits to current branch: `Invoke-GitControlledPatch -PatchDescription "chore: <description>" -PatchOperation { <changes> } -DirectCommit -AutoCommitUncommitted`
- **Branch Protection Safe**: PatchManager respects protected main branch and never attempts dangerous operations
- **Emergency Rollback**: Instant recovery from current branch: `Invoke-QuickRollback -RollbackType "LastPatch" -CreateBackup`

### Safety Features (Protects Main Branch)
| **Safety Feature** | **Description** | **Benefit** |
|-------------------|-----------------|-------------|
| No Main Branch Checkout | Never checks out protected main branch | Prevents accidental main branch modifications |
| No Force Updates | Never uses `git pull --force` on main | Preserves branch protection integrity |
| Current Branch Operation | Works from current branch state | Safe for feature branch workflows |
| Protected Branch Detection | Detects and respects branch protection | Prevents policy violations |

### Auto-Commit Features (Eliminates Manual Git Steps)
| **Parameter** | **Effect** | **Use Case** |
|---------------|------------|--------------|
| `-AutoCommitUncommitted` | Auto-commits existing changes | Replaces `git add && git commit` |
| `-Force` | Auto-stashes changes | Preserves work while allowing patch |
| `-DirectCommit` | Commits directly to current branch | Skip PR for minor fixes |

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

### Commit Workflows

#### DirectCommit vs Branch Workflow
| **DirectCommit** | **Branch Workflow** |
|------------------|-------------------|
| `✓` Quick fixes and maintenance | `✓` Feature development |
| `✓` Documentation updates | `✓` Major changes requiring review |
| `✓` Emergency fixes | `✓` Breaking changes |
| `✓` Automated cleanup operations | `✓` Collaborative development |
| `✗` No peer review | `✓` Full peer review process |
| `✗` No CI validation | `✓` Complete CI/CD validation |

#### When to Use DirectCommit
```powershell
# Quick maintenance tasks
Invoke-GitControlledPatch -PatchDescription "chore: update project manifest" -PatchOperation { 
    Update-ProjectManifest 
} -DirectCommit -Force

# Emergency fixes
Invoke-GitControlledPatch -PatchDescription "fix: resolve critical path issue" -PatchOperation { 
    Fix-HardcodedPaths 
} -DirectCommit -Force -CleanupMode "Emergency"

# Documentation updates
Invoke-GitControlledPatch -PatchDescription "docs: update README with new instructions" -PatchOperation { 
    Update-Documentation 
} -DirectCommit -Force
```

### Emergency Rollback Capabilities
PatchManager now includes comprehensive rollback functionality to quickly recover from breaking changes:

```powershell
# Quick rollback to last commit
Invoke-PatchRollback -RollbackTarget "LastCommit" -Force

# Emergency rollback (resets to last known good state)
Invoke-PatchRollback -RollbackTarget "Emergency" -Force -ValidateAfterRollback

# Rollback to specific commit with backup
Invoke-PatchRollback -RollbackTarget "SpecificCommit" -CommitHash "abc123" -CreateBackup

# Selective file rollback
Invoke-PatchRollback -RollbackTarget "SelectiveFiles" -AffectedFiles @("file1.ps1", "file2.ps1")

# Rollback to last working state (finds last validated commit)
Invoke-PatchRollback -RollbackTarget "LastWorkingState" -CreateBackup -ValidateAfterRollback
```

### Rollback Safety Features
| **Feature** | **Description** |
|-------------|-----------------|
| Safety Checks | Validates rollback safety before execution |
| Backup Creation | Creates backups before destructive operations |
| Stash Management | Automatically handles uncommitted changes |
| Integrity Validation | Ensures system integrity after rollback |
| Audit Trail | Full logging of all rollback operations |
| Protected Branch Detection | Prevents dangerous operations on protected branches |

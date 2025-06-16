# GitHub Copilot Instructions for OpenTofu Lab Automation

## Project Context (Auto-Updated: 2025-06-14)

This is a cross-platform OpenTofu (Terraform alternative) lab automation project with:
- **1 PowerShell modules** for infrastructure automation
- ** YAML workflows** for CI/CD
- ** test files** for validation
- **Cross-platform deployment** via Python scripts

For guidance on writing your own repository instructions, see
[docs/copilot_docs/repository-custom-instructions.md](../docs/copilot_docs/repository-custom-instructions.md).

## Current Architecture

### Module Locations (CRITICAL - Always Use These Paths)
- **CodeFixer**: /pwsh/modules/CodeFixer/
- **LabRunner**: /pwsh/modules/LabRunner/
- **BackupManager**: /pwsh/modules/BackupManager/

### Key Functions Available
#### CodeFixer
``powershell
Import-Module "/pwsh/modules/CodeFixer/"
Invoke-AutoFix
Invoke-AutoFixCapture
Invoke-ComprehensiveAutoFix
Invoke-ComprehensiveValidation
Invoke-HereStringFix
Invoke-ImportAnalysis
Invoke-ParallelScriptAnalyzer
Invoke-PowerShellLint-clean
Invoke-PowerShellLint-corrupted
Invoke-PowerShellLint
Invoke-ResultsAnalysis
Invoke-ScriptOrderFix
Invoke-TernarySyntaxFix
Invoke-TestSyntaxFix
New-AutoTest
Test-JsonConfig
Test-OpenTofuConfig
Test-YamlConfig
Watch-ScriptDirectory
````n
#### LabRunner
``powershell
Import-Module "/pwsh/modules/LabRunner/"
Invoke-ParallelLabRunner
Test-RunnerScriptSafety-Fixed
````n
#### BackupManager
``powershell
Import-Module "/pwsh/modules/BackupManager/"
Invoke-BackupMaintenance
Invoke-BackupConsolidation
Invoke-PermanentCleanup
Get-BackupStatistics
````n


## Development Guidelines

### Always Use Project Manifest First
`powershell
# Check current state before making changes
$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json
$manifest.core.modules # View all modules
`

### Maintenance Commands (Use These for Fixes)
`powershell
# Quick health check
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Full maintenance with fixes
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix

# YAML validation
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"
`

### Code Generation Rules
1. **Module Imports**: Always use full paths from manifest
2. **Path References**: Use `/workspaces/opentofu-lab-automation/` prefix
3. **Testing**: Reference TestHelpers.ps1 with correct module paths
4. **YAML**: All workflow files auto-validated and formatted

### File Organization
- **Scripts**: `/scripts/` (maintenance, validation, utilities)
- **Modules**: `/pwsh/modules/` (LabRunner, CodeFixer)
- **Tests**: `/tests/` (Pester test files)
- **Workflows**: `/.github/workflows/` (GitHub Actions)
- **Documentation**: `/docs/` (project documentation)

### Current Capabilities
- **Performance**: < 1 minute health checks
- **Automation**: Full YAML validation and auto-fix
- **Cross-Platform**: Windows, Linux, macOS deployment
- **Real-time**: Live validation and error correction

## Advanced PatchManager Features (NEW)

### Anti-Recursive Branching Protection
PatchManager now prevents branch explosion with intelligent branch handling:

```powershell
# SAFE: Works on current branch if already on feature branch
Invoke-GitControlledPatch -PatchDescription "fix: update configuration" -PatchOperation { 
    # Your changes 
} -AutoCommitUncommitted

# Creates new branch only from main, otherwise works on current branch
# Prevents: patch/feature/sub-patch/sub-sub-patch recursive nesting
```

### Cross-Platform Environment Variables
Project now uses environment variables for cross-platform compatibility:

| **Variable** | **Description** | **Auto-Set** |
|--------------|-----------------|-------------|
| `PROJECT_ROOT` | Project root directory | [PASS] |
| `PWSH_MODULES_PATH` | PowerShell modules path | [PASS] |
| `PLATFORM` | Current platform (Windows/Linux/macOS) | [PASS] |

### Enhanced Comprehensive Cleanup
```powershell
# Includes cross-platform path fixing and emoji removal
Invoke-GitControlledPatch -PatchDescription "chore: comprehensive cleanup" -PatchOperation {
    # Cleanup runs automatically before patch
} -CleanupMode "Standard" -AutoCommitUncommitted
```

### Intelligent Branch Strategy
| **Current Branch** | **PatchManager Action** | **Prevents** |
|-------------------|------------------------|---------------|
| `main` or `master` | Creates new patch branch | Working directly on main |
| Feature branch | Works on current branch | Recursive branch explosion |
| Patch branch | Works on current branch | Nested patch branches |

### Cross-Platform Path Standards
All hardcoded paths now use environment variables:
```powershell
# OLD (environment-specific)
$modulePath = "C:\Users\user\Documents\project\pwsh\modules"

# NEW (cross-platform)
$modulePath = "$env:PWSH_MODULES_PATH"
```


## Critical Guidelines

### Never Do These:
- Don't use legacy `pwsh/modules/` paths (migrated to modules)
- Don't create files in project root without using report utility
- Don't modify workflows without YAML validation
- Don't use deprecated import patterns
- **Don't create nested branches manually** (use PatchManager anti-recursive protection)
- **Don't hardcode paths** (use environment variables)

### Always Do These:
- Check PROJECT-MANIFEST.json before making changes
- Use unified maintenance for validation
- Reference correct module paths from manifest
- Run YAML validation after workflow changes
- **Use PatchManager for all changes** (enforces standards and prevents issues)
- **Let PatchManager handle branch strategy** (prevents recursive branch explosion)

### Modern Change Control Workflow
```powershell
# Standard workflow - PatchManager handles everything
Import-Module "$env:PWSH_MODULES_PATH/PatchManager" -Force

# Single command replaces: git add, git commit, git checkout -b, git push, create PR
Invoke-GitControlledPatch -PatchDescription "feat: new functionality" -PatchOperation {
    # Your changes here
} -AutoCommitUncommitted -CreatePullRequest

# Emergency rollback if needed
Invoke-QuickRollback -RollbackType "LastPatch" -Force
```

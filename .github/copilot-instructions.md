# GitHub Copilot Instructions for OpenTofu Lab Automation

## 📋 Project Context (Auto-Updated: 2025-06-13)

This is a cross-platform OpenTofu (Terraform alternative) lab automation project with:
- **PowerShell modules** for infrastructure automation
- **YAML workflows** for CI/CD
- **Test files** for validation
- **Cross-platform deployment** via Python scripts

## 🏗️ Current Architecture

### Module Locations (CRITICAL - Always Use These Paths)
- **CodeFixer**: /pwsh/modules/CodeFixer/
- **LabRunner**: /pwsh/modules/LabRunner/

### Key Functions Available
#### CodeFixer
```powershell
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
Watch-ScriptDirectory
````n
#### LabRunner
```powershell
Import-Module "/pwsh/modules/LabRunner/"
Invoke-ParallelLabRunner
Test-RunnerScriptSafety
````n


## 🔧 Development Guidelines

### Always Use Project Manifest First
```powershell
# Check current state before making changes
$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json
$manifest.core.modules  # View all modules
```

### Maintenance Commands (Use These for Fixes)
```powershell
# Quick health check
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Full maintenance with fixes
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix

# YAML validation
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"
```

### Code Generation Rules
1. **Module Imports**: Always use full paths from manifest
2. **Path References**: Use platform-agnostic code (`Join-Path`, `$PSScriptRoot`, `os.path.join`)
3. **Testing**: Reference TestHelpers.ps1 with correct module paths
4. **YAML**: All workflow files auto-validated and formatted

### File Organization
- **Scripts**: `/scripts/` (maintenance, validation, utilities)
- **Modules**: `/pwsh/modules/` (LabRunner, CodeFixer)
- **Tests**: `/tests/` (Pester test files)
- **Workflows**: `/.github/workflows/` (GitHub Actions)
- **Documentation**: `/docs/` (project documentation)

### Critical Guidelines
- Never hardcode Linux or Windows paths; always use platform detection or relative paths.
- Always automate issue tracking from test/maintenance output.
- Add CLI/GUI menu option for repo re-clone and refresh.

---
## 🕒 Copilot Config Running Log
- **2025-06-13 23:30** – Updated Copilot instructions for cross-platform, clarified automation, and added running log section. Next: ensure all scripts/platforms are supported and issue tracking is automated.

---
*Auto-generated from PROJECT-MANIFEST.json*
*Project health: < 1 minute*
*Last update: 2025-06-13 23:30*

# GitHub Copilot Instructions for OpenTofu Lab Automation

## 📋 Project Context (Auto-Updated: 2025-06-14)

This is a cross-platform OpenTofu (Terraform alternative) lab automation project with:
- **1 PowerShell modules** for infrastructure automation
- ** YAML workflows** for CI/CD
- ** test files** for validation
- **Cross-platform deployment** via Python scripts

## 🏗️ Current Architecture

### Module Locations (CRITICAL - Always Use These Paths)
- **CodeFixer**: /pwsh/modules/CodeFixer/
- **LabRunner**: /pwsh/modules/LabRunner/

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
Watch-ScriptDirectory
````n
#### LabRunner
``powershell
Import-Module "/pwsh/modules/LabRunner/"
Invoke-ParallelLabRunner
Test-RunnerScriptSafety-Fixed
Test-RunnerScriptSafety
````n


## 🔧 Development Guidelines

### Always Use Project Manifest First
`powershell
# Check current state before making changes
$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json
$manifest.core.modules  # View all modules
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

## 🚨 Critical Guidelines

### Never Do These:
- Don't use legacy `pwsh/lab_utils/` paths (migrated to modules)
- Don't create files in project root without using report utility
- Don't modify workflows without YAML validation
- Don't use deprecated import patterns

### Always Do These:
- Check PROJECT-MANIFEST.json before making changes
- Use unified maintenance for validation
- Reference correct module paths from manifest
- Run YAML validation after workflow changes

### Report Creation (MANDATORY)
`powershell
# Use the report utility, never create manual .md files in root
./scripts/utilities/new-report.ps1 -Type "test-analysis" -Title "My Report"
`

## 🎯 Integration Points

### GitHub Actions Integration
- All workflows validated with yamllint
- PowerShell scripts syntax-checked
- Cross-platform testing enabled
- Automated deployment workflows

### Module System
- Modern PowerShell module structure
- Automated import path updates
- Dependency validation
- Performance optimized batch processing

---
*Auto-generated from PROJECT-MANIFEST.json*
*Project health: < 1 minute*
*Last update: 2025-06-14 03:07:21*

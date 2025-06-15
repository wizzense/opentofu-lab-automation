# GitHub Copilot Instructions for OpenTofu Lab Automation

## Project Context (Auto-Updated: 2025-06-14)

This is a cross-platform OpenTofu (Terraform alternative) lab automation project with:
- **1 PowerShell modules** for infrastructure automation
- ** YAML workflows** for CI/CD
- ** test files** for validation
- **Cross-platform deployment** via Python scripts

## Current Architecture

### Module Locations (CRITICAL - Always Use These Paths)
- **PatchManager**: /pwsh/modules/PatchManager/ (PRIMARY - Use for ALL maintenance/patching)
- **CodeFixer**: /pwsh/modules/CodeFixer/
- **LabRunner**: /pwsh/modules/LabRunner/
- **BackupManager**: /pwsh/modules/BackupManager/

### Key Functions Available

#### PatchManager (PRIMARY MAINTENANCE SYSTEM)
```powershell
# ALWAYS use PatchManager for ALL patching, fixes, and maintenance
Import-Module "/pwsh/modules/PatchManager/" -Force

# Main maintenance functions
Invoke-UnifiedMaintenance
Invoke-TestFileFix
Invoke-InfrastructureFix  
Invoke-YamlValidation
Invoke-PatchCleanup
Invoke-HealthCheck
Invoke-RecurringIssueCheck
Show-MaintenanceReport
Test-PatchingRequirements
```

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
- **Modules**: `/pwsh/modules/CodeFixer` (LabRunner, CodeFixer)
- **Tests**: `/tests/` (Pester test files)
- **Workflows**: `/.github/workflows/` (GitHub Actions)
- **Documentation**: `/docs/` (project documentation)

### Current Capabilities
- **Performance**: < 1 minute health checks
- **Automation**: Full YAML validation and auto-fix
- **Cross-Platform**: Windows, Linux, macOS deployment
- **Real-time**: Live validation and error correction

## Critical Guidelines

### Never Do These:
- Don't use legacy `pwsh/modules/CodeFixer` paths (migrated to modules)
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

## CRITICAL MAINTENANCE REQUIREMENTS

> **⚠️ MANDATORY**: PatchManager is the ONLY approved system for all maintenance, patching, and fixing

### Rules for ALL Code Generation and Maintenance
1. **NEVER create standalone fix scripts** in project root or anywhere else
2. **ALWAYS use PatchManager module functions** for all fixes and patches  
3. **ALWAYS update changelogs** when applying fixes using `-UpdateChangelog` parameter
4. **ALWAYS run health checks** before and after fixing using `Invoke-HealthCheck`
5. **ALWAYS consolidate scattered fixes** using `Invoke-PatchCleanup`

### Standard Troubleshooting Workflow
```powershell
# Step 1: Import PatchManager (REQUIRED)
Import-Module "/pwsh/modules/PatchManager" -Force

# Step 2: Run health check to identify issues
$issues = Invoke-HealthCheck -Mode "Comprehensive" -OutputFormat "Object"

# Step 3: Apply targeted fixes based on issue type
foreach ($issue in $issues.Where{$_.Severity -eq "High"}) {
    switch ($issue.Category) {
        "TestSyntax" { Invoke-TestFileFix -Path $issue.FilePath -UpdateChangelog }
        "ImportPaths" { Invoke-InfrastructureFix -Fix "ImportPaths" -AutoFix }
        "YamlSyntax" { Invoke-YamlValidation -Path $issue.FilePath -Mode "Fix" }
    }
}

# Step 4: Clean up any scattered fixes
Invoke-PatchCleanup -Mode "Full" -UpdateChangelog

# Step 5: Verify fixes worked
Invoke-HealthCheck -Mode "Quick"
```

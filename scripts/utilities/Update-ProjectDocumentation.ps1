#!/usr/bin/env pwsh
<#
.SYNOPSIS
 Updates AGENTS.md and copilot configuration files with current project state

.DESCRIPTION
 This script automatically updates documentation and configuration files to reflect
 the current project structure, modules, and capabilities.

.PARAMETER Force
 Force update even if files appear up-to-date

.EXAMPLE
 ./Update-ProjectDocumentation.ps1

.EXAMPLE
 ./Update-ProjectDocumentation.ps1 -Force
#>

param(
 switch$Force
)

$ErrorActionPreference = "Stop"

Write-Host " Updating project documentation and configuration..." -ForegroundColor Cyan

# Get current project state
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$manifestPath = "$ProjectRoot/PROJECT-MANIFEST.json"

if (-not (Test-Path $manifestPath)) {
 Write-Warning "PROJECT-MANIFEST.json not found, generating..."
 $updateScript = "$ProjectRoot/scripts/utilities/update-project-manifest.ps1"
 if (Test-Path $updateScript) {
 & $updateScript -Force
 } else {
 Write-Error "Cannot find update-project-manifest.ps1 script"
 return
 }
}

$manifest = Get-Content $manifestPath | ConvertFrom-Json# Update AGENTS.md
$agentsPath = "$ProjectRoot/AGENTS.md"
Write-Host " Updating AGENTS.md..." -ForegroundColor Yellow

$functionsText = ""
foreach ($moduleProperty in $manifest.core.modules.PSObject.Properties) {
 $module = $moduleProperty.Name
 $functions = $moduleProperty.Value.keyFunctions
 $functionsText += "#### $module`n"
 foreach ($func in $functions) {
 $functionsText += "- $func`n"
 }
 $functionsText += "`n"
}

$agentsContent = @"
# AI Agent Integration Documentation

## Project State Overview

**Last Updated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Project Health**: $($manifest.metrics.performance.healthCheckTime)
**Total Modules**: $($manifest.core.modules.Count)

## Current Capabilities

### Core Modules
$( ($manifest.core.modules.PSObject.Properties | ForEach-Object{
 "- **$($_.Name)**: $($_.Value.description)"
}) -join "`n" )

### Key Functions Available
$functionsText

### Performance Metrics
- **Health Check Time**: $($manifest.metrics.performance.healthCheckTime)
- **Validation Speed**: $($manifest.metrics.performance.validationSpeed)
- **File Processing**: $($manifest.metrics.performance.fileProcessingRate)

### Infrastructure Status
- **PowerShell Files**: $($manifest.structure.fileTypes.powershell) files
- **Test Files**: $($manifest.structure.fileTypes.tests) files
- **YAML Workflows**: $($manifest.structure.fileTypes.yaml) files
- **Total LOC**: $($manifest.metrics.codebase.totalLinesOfCode) lines

## Maintenance Integration

### Automated Systems
1. **Unified Maintenance**: ``./scripts/maintenance/unified-maintenance.ps1``
 - Infrastructure health checks
 - YAML validation and auto-fix
 - PowerShell syntax validation
 - Automated reporting

2. **YAML Validation**: ``./scripts/validation/Invoke-YamlValidation.ps1``
 - Real-time workflow validation
 - Automatic formatting fixes
 - Truthy value normalization

3. **CodeFixer Module**: Advanced PowerShell analysis and repair
 - Batch processing capabilities
 - Parallel execution
 - Import path modernization

### Quick Commands
```powershell
# Health check
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Full maintenance with auto-fix
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix

# YAML validation
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"

# Comprehensive validation
Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/CodeFixer/" -ForceInvoke-ComprehensiveValidation
```

## Architecture

### Module Structure
```
pwsh/modules/CodeFixer
├── LabRunner/ # Core lab automation
├── CodeFixer/ # Code analysis and repair
└── Dynamic modules # Additional capabilities
```

### Validation Pipeline
1. **Infrastructure Health** → Basic system checks
2. **YAML Validation** → Workflow file integrity
3. **PowerShell Syntax** → Code quality assurance
4. **Import Analysis** → Dependency validation
5. **Test Execution** → Functional verification

## Usage Analytics

### Common Operations
- **Quick deployment**: ``python deploy.py --quick``
- **GUI interface**: ``python gui.py``
- **Cross-platform**: Windows, Linux, macOS support

### Integration Points
- GitHub Actions workflows validated and optimized
- PowerShell module system modernized
- Cross-platform launcher scripts maintained
- Documentation auto-generated from manifest

---
*This file is automatically updated by the maintenance system*
*Last auto-update: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

Set-Content $agentsPath $agentsContent -Encoding UTF8
Write-Host "PASS Updated AGENTS.md" -ForegroundColor Green

# Update .github/copilot-instructions.md
$copilotPath = "$ProjectRoot/.github/copilot-instructions.md"
Write-Host " Updating copilot instructions..." -ForegroundColor Yellow

# Build copilot functions text
$copilotFunctionsText = ""
foreach ($moduleProperty in $manifest.core.modules.PSObject.Properties) {
 $module = $moduleProperty.Name
 $functions = $moduleProperty.Value.keyFunctions
 $modulePath = $moduleProperty.Value.path
 $copilotFunctionsText += "#### $module`n"
 $copilotFunctionsText += "````powershell`n"
 $copilotFunctionsText += "Import-Module `"$modulePath`"`n"
 foreach ($func in $functions) {
 $copilotFunctionsText += "$func`n"
 }
 $copilotFunctionsText += "````````n`n"
}

$copilotContent = @"
# GitHub Copilot Instructions for OpenTofu Lab Automation

## Project Context (Auto-Updated: $(Get-Date -Format "yyyy-MM-dd"))

This is a cross-platform OpenTofu (Terraform alternative) lab automation project with:
- **$($manifest.core.modules.Count) PowerShell modules** for infrastructure automation
- **$($manifest.structure.fileTypes.yaml) YAML workflows** for CI/CD
- **$($manifest.structure.fileTypes.tests) test files** for validation
- **Cross-platform deployment** via Python scripts

## Current Architecture

### Module Locations (CRITICAL - Always Use These Paths)
$( ($manifest.core.modules.PSObject.Properties | ForEach-Object{
 "- **$($_.Name)**: $($_.Value.path)"
}) -join "`n" )

### Key Functions Available
$copilotFunctionsText

## Development Guidelines

### Always Use Project Manifest First
```powershell
# Check current state before making changes
`$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json`$manifest.core.modules # View all modules
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
2. **Path References**: Use ``/workspaces/opentofu-lab-automation/`` prefix
3. **Testing**: Reference TestHelpers.ps1 with correct module paths
4. **YAML**: All workflow files auto-validated and formatted

### File Organization
- **Scripts**: ``/scripts/`` (maintenance, validation, utilities)
- **Modules**: ``/pwsh/modules/CodeFixer`` (LabRunner, CodeFixer)
- **Tests**: ``/tests/`` (Pester test files)
- **Workflows**: ``/.github/workflows/`` (GitHub Actions)
- **Documentation**: ``/docs/`` (project documentation)

### Current Capabilities
- **Performance**: $($manifest.metrics.performance.healthCheckTime) health checks
- **Automation**: Full YAML validation and auto-fix
- **Cross-Platform**: Windows, Linux, macOS deployment
- **Real-time**: Live validation and error correction

## Critical Guidelines

### Never Do These:
- Don't use legacy ``pwsh/modules/CodeFixer`` paths (migrated to modules)
- Don't create files in project root without using report utility
- Don't modify workflows without YAML validation
- Don't use deprecated import patterns

### Always Do These:
- Check PROJECT-MANIFEST.json before making changes
- Use unified maintenance for validation
- Reference correct module paths from manifest
- Run YAML validation after workflow changes

### Report Creation (MANDATORY)
```powershell
# Use the report utility, never create manual .md files in root
./scripts/utilities/new-report.ps1 -Type "test-analysis" -Title "My Report"
```

## Integration Points

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
*Project health: $($manifest.metrics.performance.healthCheckTime)*
*Last update: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

Set-Content $copilotPath $copilotContent -Encoding UTF8
Write-Host "PASS Updated copilot instructions" -ForegroundColor Green

Write-Host " Documentation update completed!" -ForegroundColor Green
Write-Host " - Updated AGENTS.md with current project state" -ForegroundColor White
Write-Host " - Updated .github/copilot-instructions.md with architecture" -ForegroundColor White
Write-Host " - Integrated manifest data and performance metrics" -ForegroundColor White















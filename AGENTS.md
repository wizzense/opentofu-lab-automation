# AI Agent Integration Documentation

## Project State Overview

**Last Updated**: 2025-06-14 16:45:01
**Project Health**: < 1 minute
**Total Modules**: 1

## Current Capabilities

### Core Modules
- **CodeFixer**: 
- **LabRunner**: 
- **BackupManager**: Comprehensive backup management module

### Key Functions Available
#### CodeFixer
- Invoke-AutoFix
- Invoke-AutoFixCapture
- Invoke-ComprehensiveAutoFix
- Invoke-ComprehensiveValidation
- Invoke-HereStringFix
- Invoke-ImportAnalysis
- Invoke-ParallelScriptAnalyzer
- Invoke-PowerShellLint-clean
- Invoke-PowerShellLint-corrupted
- Invoke-PowerShellLint
- Invoke-ResultsAnalysis
- Invoke-ScriptOrderFix
- Invoke-TernarySyntaxFix
- Invoke-TestSyntaxFix
- New-AutoTest
- Test-JsonConfig
- Test-OpenTofuConfig
- Test-YamlConfig
- Watch-ScriptDirectory

#### LabRunner
- Invoke-ParallelLabRunner
- Test-RunnerScriptSafety-Fixed

#### BackupManager
- Invoke-BackupMaintenance
- Invoke-BackupConsolidation
- Invoke-PermanentCleanup
- Get-BackupStatistics



### Performance Metrics
- **Health Check Time**: < 1 minute
- **Validation Speed**: 
- **File Processing**: 

### Infrastructure Status
- **PowerShell Files**:  files
- **Test Files**:  files
- **YAML Workflows**:  files
- **Total LOC**:  lines

## Maintenance Integration

### Automated Systems
1. **Unified Maintenance**: `./scripts/maintenance/unified-maintenance.ps1`
 - Infrastructure health checks
 - YAML validation and auto-fix
 - PowerShell syntax validation
 - Automated reporting

2. **YAML Validation**: `./scripts/validation/Invoke-YamlValidation.ps1`
 - Real-time workflow validation
 - Automatic formatting fixes
 - Truthy value normalization

3. **CodeFixer Module**: Advanced PowerShell analysis and repair
 - Batch processing capabilities
 - Parallel execution
 - Import path modernization

### Quick Commands
`powershell
# Health check
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Full maintenance with auto-fix
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix

# YAML validation
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"

# Comprehensive validation
Import-Module "C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation/pwsh/modules/CodeFixer/" -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force
Invoke-ComprehensiveValidation
`

## Architecture

### Module Structure
`
pwsh/modules/
├── LabRunner/ # Core lab automation
├── CodeFixer/ # Code analysis and repair
└── [Dynamic modules] # Additional capabilities
`

### Validation Pipeline
1. **Infrastructure Health** → Basic system checks
2. **YAML Validation** → Workflow file integrity
3. **PowerShell Syntax** → Code quality assurance
4. **Import Analysis** → Dependency validation
5. **Test Execution** → Functional verification

## Usage Analytics

### Common Operations
- **Quick deployment**: `python deploy.py --quick`
- **GUI interface**: `python gui.py`
- **Cross-platform**: Windows, Linux, macOS support

### Integration Points
- GitHub Actions workflows validated and optimized
- PowerShell module system modernized
- Cross-platform launcher scripts maintained
- Documentation auto-generated from manifest

---
*This file is automatically updated by the maintenance system*
*Last auto-update: 2025-06-14 16:45:01*

# AI Agent Integration Documentation

## Project State Overview

**Last Updated**: 2025-06-15 - **CRITICAL WORKFLOW CHANGE**
**Project Health**: Maintenance Required  
**Total Modules**: 4

**MANDATORY CHANGE CONTROL IMPLEMENTED**

## CRITICAL: New Git-Based Patch Management Workflow

### ALL AUTOMATED FIXES NOW REQUIRE HUMAN VALIDATION

As of 2025-06-15, **ALL automated patches and fixes MUST follow Git-based change control**:

1. **NO DIRECT COMMITS TO MAIN** - All changes go through PR review
2. **BRANCH-BASED PATCHING** - Every fix creates a dedicated patch branch  
3. **MANDATORY PR REVIEW** - Human validation required before any merge
4. **COMPREHENSIVE VALIDATION** - All patches validated before PR creation

## CRITICAL: EMOJI USAGE STRICTLY PROHIBITED

**NEVER USE EMOJIS IN ANY CODE, SCRIPTS, OR WORKFLOWS**
- Emojis break GitHub Actions workflows
- Emojis cause encoding issues in cross-platform environments  
- Emojis break PowerShell execution on some systems
- ALL code output must use plain text only
- Any existing emojis must be removed immediately

### Required Workflow for ALL Agents

```powershell
# CORRECT: Use Git-controlled patching
Import-Module "/pwsh/modules/PatchManager" -Force

# Apply syntax fixes with proper change control
Invoke-GitControlledPatch -PatchType "Syntax" -CreatePR

# Apply all fixes with proper change control  
Invoke-GitControlledPatch -PatchType "All" -BranchName "fix-critical-issues" -CreatePR

# This creates a patch branch and PR for manual review
```

```powershell
# WRONG: Direct fixes without change control
Invoke-PowerShellLint -Path "./scripts/" -AutoFix  # PROHIBITED
Set-Content -Path "file.ps1" -Value $newContent   # PROHIBITED
```

### Change Control Requirements

**Every automated change MUST:**
1. Create a new Git branch prefixed with `patch-`
2. Apply fixes in the isolated branch
3. Create a pull request for human review
4. Include comprehensive change documentation
5. Require manual approval before merging
6. Never include emojis or problematic Unicode characters

1. **Branch Creation**: All fixes must create a new branch named `patch/YYYYMMDD-HHMMSS-description`
2. **PR Template**: Use comprehensive PR template with validation checklist
3. **Human Review**: ALL PRs require manual approval before merge
4. **Validation Gates**: PowerShell, Python, YAML, and test validation must pass
5. **Backup Creation**: Automatic backup before applying any changes
6. **Audit Trail**: Full Git history of all changes with justification

### Emergency Patch Protocol

Only use for critical system-breaking issues:

```powershell
# Emergency patches still require branch creation but expedited review
Invoke-GitControlledPatch -PatchType "All" -BranchName "emergency-critical-fix" -CreatePR
# Then manually fast-track the PR review
```

## Current Capabilities

### Core Modules (ALL NOW WITH MANDATORY CHANGE CONTROL)
- **CodeFixer**: Automated code analysis and fixing with Git-controlled workflow
- **LabRunner**: Lab environment automation and management  
- **BackupManager**: Comprehensive backup management module
- **PatchManager**: **ENHANCED** Git-based patching with mandatory PR workflow

### NEW: Git-Based Patching System Architecture

The patching system now enforces Git-based change control:

1. **Git-Controlled Maintenance**: All maintenance operations use `Invoke-GitControlledPatch`
2. **Branch-Based Workflow**: Every patch creates a dedicated branch
3. **PR-Based Review**: All changes require pull request approval
4. **Comprehensive Validation**: PowerShell, Python, YAML, and test validation
5. **Human Oversight**: Mandatory manual review for all automated fixes
6. **Audit Trail**: Complete Git history with patch justification
7. **Emoji Removal**: Automatic detection and removal of workflow-breaking characters

### Patch Types Available

```powershell
# Syntax fixes (PowerShell linting, formatting)
Invoke-GitControlledPatch -PatchType "Syntax" -CreatePR

# Import path fixes (deprecated module paths)
Invoke-GitControlledPatch -PatchType "Import" -CreatePR

# Infrastructure fixes (module structure, dependencies)
Invoke-GitControlledPatch -PatchType "Infrastructure" -CreatePR

# YAML fixes (workflow files, remove emojis)
Invoke-GitControlledPatch -PatchType "YAML" -CreatePR

# All patch types combined
Invoke-GitControlledPatch -PatchType "All" -CreatePR
```

### Key Functions Available

#### PatchManager (PRIMARY MODULE - ALL FIXES GO THROUGH HERE)
```powershell
# NEW: Git-controlled patching (REQUIRED FOR ALL FIXES)
Invoke-GitControlledPatch -PatchType "All" -CreatePR

# Legacy functions (now deprecated in favor of Git-controlled versions)
Invoke-UnifiedMaintenance -Mode "All" -AutoFix  # DEPRECATED
Invoke-YamlValidation -Mode "Fix"               # DEPRECATED
Invoke-TestFileFix -Mode "Comprehensive"        # DEPRECATED
```

#### CodeFixer (INTEGRATION WITH PATCHMANAGER REQUIRED)
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

#### PatchManager
PatchManager is now the central system for all patching, test fixing, and maintenance activities:

```powershell
Import-Module "/pwsh/modules/PatchManager" -Force
```

##### Primary Entry Points
- `Invoke-UnifiedMaintenance` - Main entry point for all maintenance tasks and patching
- `Invoke-YamlValidation` - Validates and fixes YAML files
- `Invoke-TestFileFix` - Fixes common test file issues and syntax

##### Core Functions
- `Invoke-PatchCleanup` - Centralized system for managing patches (analyze, archive, migrate)
- `Invoke-InfrastructureFix` - Applies infrastructure fixes (import paths, module structures)
- `Invoke-ArchiveCleanup` - Archives and cleans up obsolete files
- `Show-MaintenanceReport` - Generates maintenance reports with change tracking
- `Invoke-HealthCheck` - Performs comprehensive health checks of the infrastructure
- `Invoke-RecurringIssueCheck` - Monitors and fixes known recurring issues
- `Test-PatchingRequirements` - Verifies system requirements for patching

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

### Primary Maintenance System: PatchManager

All maintenance, patching, and test fixing must be performed through PatchManager. 
The module provides a comprehensive framework for health checks, fixes, and validation.

```powershell
# First, always import the PatchManager module
Import-Module "/pwsh/modules/PatchManager" -Force

# Then use the appropriate function
Invoke-UnifiedMaintenance -Mode "Quick"
```

### Key Maintenance Entry Points

1. **Unified Maintenance**: 
```powershell
# Preferred module approach
Import-Module "/pwsh/modules/PatchManager" -Force
Invoke-UnifiedMaintenance -Mode "All" -AutoFix

# Legacy script approach (redirects to module)
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix
```

2. **YAML Validation**: 
```powershell
Import-Module "/pwsh/modules/PatchManager" -Force
Invoke-YamlValidation -Mode "Fix"
```

3. **Test File Fixing**:
```powershell
Import-Module "/pwsh/modules/PatchManager" -Force
Invoke-TestFileFix -Mode "Comprehensive" 
```

4. **Infrastructure Fixes**:
```powershell
Import-Module "/pwsh/modules/PatchManager" -Force
Invoke-InfrastructureFix -Fix "ImportPaths" -AutoFix
```

### Automated Integration

PatchManager is integrated with:
- GitHub Actions workflows (/.github/workflows/maintenance.yml)
- Pre-commit hooks (/.git/hooks/pre-commit)
- Scheduled maintenance (cron jobs)
- IDE extensions
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"

# Comprehensive validation with CodeFixer
Import-Module "/pwsh/modules/CodeFixer/" -Force
Invoke-ComprehensiveValidation
```

## Standardized Patching System

The project now uses a standardized patching system built around the PatchManager module:

### Module Organization

```
/pwsh/modules/PatchManager/
├── PatchManager.psd1   # Module manifest
├── PatchManager.psm1   # Module loader
├── Public/
│   ├── Invoke-UnifiedMaintenance.ps1  # Main entry point for maintenance
│   ├── Invoke-YamlValidation.ps1      # YAML validation and fixing
│   ├── Invoke-InfrastructureFix.ps1   # Infrastructure fixes
│   ├── Invoke-ArchiveCleanup.ps1      # Archive cleanup
│   ├── Show-MaintenanceReport.ps1     # Report generation
│   ├── Invoke-HealthCheck.ps1         # Health checking
│   ├── Invoke-RecurringIssueCheck.ps1 # Issue tracking
│   ├── Invoke-PatchCleanup.ps1        # Patch consolidation
│   └── Invoke-TestFileFix.ps1         # Test file fixes
└── Private/
    ├── Write-PatchLog.ps1             # Centralized logging
    ├── Import-FixScripts.ps1          # Import archived fix scripts
    ├── Repair-TestFile.ps1            # Test file repair helper
    ├── Remove-ScatteredFiles.ps1      # File cleanup helper
    └── Update-Changelog.ps1           # Changelog management
```

### Key Features

1. **Module-First Approach**: All functionality is available as module functions
   - Import with `Import-Module "/pwsh/modules/PatchManager"`
   - Functions like `Invoke-YamlValidation` are called directly
   - **CRITICAL: Never use standalone scripts for fixes or patching**

2. **Automatic Changelog Integration**: All changes are logged and tracked
   - Changelog entries created for fixes and patches
   - Reports generated in `/reports/` directory
   - Issue tracking integrated with GitHub

3. **Cross-Platform Path Handling**: All paths work on Windows, Linux, and macOS
   - Forward slashes used consistently
   - Path joining with Join-Path for platform-specific behavior

4. **Centralized Test Fixing**: All test fixes are now handled through PatchManager
   - `Invoke-TestFileFix` replaces individual test fix scripts
   - Historical fixes are preserved and migrated into the module
   - Patterns are detected and fixed automatically

5. **Integrated Patch Management**: Complete workflow for patching
   - Analyze issues with `Invoke-HealthCheck`
   - Apply fixes with `Invoke-InfrastructureFix` or `Invoke-TestFileFix`
   - Track changes with `Show-MaintenanceReport`
   - Clean up with `Invoke-ArchiveCleanup`

### Usage Examples

```powershell
# Import all maintenance modules
Import-Module "/pwsh/modules/PatchManager" -Force
Import-Module "/pwsh/modules/CodeFixer" -Force
Import-Module "/pwsh/modules/BackupManager" -Force

# Run unified maintenance
Invoke-UnifiedMaintenance -Mode "All" -AutoFix -UpdateChangelog

# Validate and fix YAML files
Invoke-YamlValidation -Path ".github/workflows" -Mode "Fix"

# Clean up archive files automatically
Invoke-ArchiveCleanup -Confirm:$false

# Check for recurring infrastructure issues
Invoke-RecurringIssueCheck -TrackIssues

# Cleanup scattered patch scripts
Invoke-PatchCleanup -Mode "Full" -UpdateChangelog

# Fix test files with common patterns
Invoke-TestFileFix -CreateReport
```

### Automated Cleanup Workflow

When you need to clean up and standardize scattered fix and test scripts:

```powershell
# Step 1: Import the PatchManager module
Import-Module "/pwsh/modules/PatchManager" -Force

# Step 2: Report on scattered files (no changes)
Invoke-PatchCleanup -Mode "Report"

# Step 3: Archive scattered files without deletion (safe mode)
Invoke-PatchCleanup -Mode "Safe"

# Step 4: Once verified, perform full cleanup
Invoke-PatchCleanup -Mode "Full" -UpdateChangelog

# Step 5: Fix test files
Invoke-TestFileFix -CreateReport

# Step 6: Run full maintenance to verify changes
Invoke-UnifiedMaintenance -Mode "All"
```
Invoke-ComprehensiveValidation
`

## Architecture

### Module Structure
`
pwsh/modules/CodeFixer
├── LabRunner/ # Core lab automation
├── CodeFixer/ # Code analysis and repair
└── Dynamic modules # Additional capabilities
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

## PatchManager - Centralized Troubleshooting System

### Overview
PatchManager is now the central module for all troubleshooting, maintenance, and patching operations. All scattered fix scripts have been migrated into this module for better organization, traceability, and consistency.

### Key Capabilities
- **Scattered File Cleanup**: Identifies and archives standalone fix scripts
- **Code Fixes**: Centralizes test and infrastructure fix logic
- **Maintenance Reporting**: Generates comprehensive reports
- **Update Tracking**: Maintains changelog entries for fixes
- **Health Monitoring**: Tracks recurring issues and alerts
- **YAML Validation**: Provides safe YAML checking and fixing

### Standard Usage Patterns

#### 1. Troubleshooting Issues
Always use PatchManager as the first step when troubleshooting:

```powershell
# Import the module
Import-Module "/pwsh/modules/PatchManager" -Force

# Run a health check to identify issues
Invoke-HealthCheck -Mode "Comprehensive"

# Apply infrastructure fixes
Invoke-InfrastructureFix -Fix "ImportPaths" -AutoFix

# Fix test files if needed
Invoke-TestFileFix -FixType "All" -TestPath "./tests"

# Generate a maintenance report
Show-MaintenanceReport -Mode "Full" -ReportPath "./reports"
```

#### 2. Cleaning Up Scattered Fix Files
When you find scattered fix scripts that aren't part of the module system:

```powershell
# Analyze scattered files (safe mode)
Invoke-PatchCleanup -Mode "Analyze" 

# Archive and migrate functionality to PatchManager
Invoke-PatchCleanup -Mode "Migrate" -UpdateChangelog
```

#### 3. YAML Workflow Validation
For validating YAML workflows:

```powershell
# Check YAML files safely (no auto-fix)
Invoke-YamlValidation -Path ".github/workflows" -Mode "Check"

# Generate detailed report of issues
Invoke-YamlValidation -Path ".github/workflows" -Mode "Report" -ReportPath "./reports"
```

#### 4. Weekly Maintenance
For regular maintenance tasks:

```powershell
# Run comprehensive health check
Invoke-UnifiedMaintenance -Mode "All" -UpdateChangelog -WhatIf:$false
```

### Integrating New Fixes
All new fixes should be added to PatchManager rather than creating standalone scripts:

1. Create function in appropriate `/Public` or `/Private` directory
2. Update changelog with `Update-Changelog`
3. Log operations with `Write-PatchLog`
4. Generate report with `Show-MaintenanceReport`

### PatchManager Directory Structure
```
/pwsh/modules/PatchManager/
├── PatchManager.psd1   # Module manifest
├── PatchManager.psm1   # Module loader
├── Public/             # Public functions
│   ├── Invoke-PatchCleanup.ps1
│   ├── Invoke-TestFileFix.ps1
│   ├── Invoke-InfrastructureFix.ps1
│   └── ...
├── Private/            # Internal helper functions
│   ├── Import-FixScripts.ps1
│   ├── Repair-TestFile.ps1
│   ├── Update-Changelog.ps1
│   └── ...
└── README.md           # Documentation
```

## Project Health Checking

## Troubleshooting and Patching Workflow

### Standard Patching Workflow

When troubleshooting issues or applying patches, always follow this workflow using PatchManager:

1. **Import the module**:
```powershell
Import-Module "/pwsh/modules/PatchManager" -Force
```

2. **Run a health check to identify issues**:
```powershell
Invoke-HealthCheck -Mode "Comprehensive" -LogPath "./logs/health-check.log"
```

3. **Apply fixes for specific issue types**:
   
   For test file issues:
   ```powershell
   Invoke-TestFileFix -Mode "Comprehensive" -UpdateChangelog
   ```
   
   For infrastructure issues:
   ```powershell
   Invoke-InfrastructureFix -Fix "ImportPaths" -AutoFix
   ```
   
   For YAML issues:
   ```powershell
   Invoke-YamlValidation -Mode "Fix" -Path "./.github/workflows/"
   ```

4. **Clean up scattered files**:
```powershell
Invoke-PatchCleanup -Mode "Full" -UpdateChangelog
```

5. **Verify fixes and generate reports**:
```powershell
Invoke-HealthCheck -Mode "Quick"
Show-MaintenanceReport -Mode "Recent"
```

### For AI Maintenance Agents

AI agents should follow these guidelines when performing maintenance:

1. **Always use PatchManager** for all maintenance/patching tasks
2. **Never create standalone fix scripts** in the project root
3. **Always use the module functions** for patching, fixing and maintenance
4. **Always generate a changelog entry** for significant changes
5. **Always check for recurring issues** before implementing new fixes

Example workflow for AI maintenance:

```powershell
# 1. Import modules
Import-Module "/pwsh/modules/PatchManager" -Force
Import-Module "/pwsh/modules/CodeFixer" -Force

# 2. Run health checks to identify issues
$healthReport = Invoke-HealthCheck -Mode "Comprehensive" -OutputFormat "Object"

# 3. Apply targeted fixes based on health report
foreach ($issue in $healthReport.Issues) {
    switch ($issue.Category) {
        "TestSyntax" {
            Invoke-TestFileFix -Mode "Targeted" -Files $issue.AffectedFiles -UpdateChangelog
        }
        "ImportPaths" {
            Invoke-InfrastructureFix -Fix "ImportPaths" -Path $issue.AffectedFiles -AutoFix
        }
        "YamlSyntax" {
            Invoke-YamlValidation -Mode "Fix" -Path $issue.AffectedFiles
        }
    }
}

# 4. Verify fixes
Invoke-HealthCheck -Mode "Quick"

# 5. Generate a report
Show-MaintenanceReport -Mode "Recent" -OutputPath "./reports/maintenance-$(Get-Date -Format 'yyyyMMdd').md"
```

# GitHub Copilot Custom Instructions and Prompts

This document describes the comprehensive GitHub Copilot configuration for the OpenTofu Lab Automation project, including custom instructions, prompts, and project management integration.

## CRITICAL WORKFLOW CHANGE - EFFECTIVE 2025-06-15

### MANDATORY GIT-BASED CHANGE CONTROL FOR ALL FIXES

**ALL automated fixes, patches, and maintenance operations MUST now use Git-based change control with mandatory human validation.**

## CRITICAL: NO EMOJI USAGE ALLOWED

**NEVER USE EMOJIS IN ANY CODE, SCRIPTS, WORKFLOWS, OR OUTPUT**
- Emojis break GitHub Actions workflows
- Emojis cause encoding issues across platforms
- Emojis break PowerShell execution
- Use plain text only for all output

#### New Copilot Behavior Requirements

1. **NO DIRECT COMMITS TO MAIN**: All changes must go through patch branches and PR review
2. **MANDATORY BRANCH CREATION**: Every fix must create a dedicated `patch/YYYYMMDD-HHMMSS-description` branch
3. **PULL REQUEST WORKFLOW**: All changes require PR creation and manual approval
4. **HUMAN VALIDATION GATES**: No automated merging - human review required for ALL changes
5. **NO EMOJIS**: Never use emojis in any generated code or output

#### Required Code Patterns for Copilot

```powershell
# CORRECT: Git-controlled patching (MANDATORY)
Import-Module "/pwsh/modules/PatchManager" -Force

$patchResult = Invoke-GitControlledPatch -PatchDescription "Fix identified issues" -PatchOperation {
    # Your fix operations here
    Invoke-PowerShellLint -Path "./target/files/" -AutoFix
    Invoke-TestFileFix -Path "./tests/" -AutoFix
} -AffectedFiles @("./target/files/", "./tests/") -CreatePullRequest

if ($patchResult.Success) {
    Write-Host "Patch created successfully. PR: $($patchResult.PullRequest.Url)"
    Write-Host "Manual review required before merge"
} else {
    Write-Error "Patch failed: $($patchResult.Message)"
}
```

```powershell
# PROHIBITED: Direct fixes without change control
Invoke-PowerShellLint -Path "./scripts/" -AutoFix  # NEVER DO THIS
Invoke-TestFileFix -Path "./tests/" -AutoFix       # NEVER DO THIS
```

#### Emergency Fix Protocol (Critical Issues Only)

```powershell
# Only for system-breaking critical issues
Invoke-EmergencyPatch -PatchDescription "Critical system failure fix" -PatchOperation {
    # Emergency operations
} -Justification "System completely broken, blocking all development" -AffectedFiles @("critical/files")
```

## Overview

The project includes extensive Copilot customization for:
- **Git-based change control** with mandatory PR workflow
- **Project-specific code generation** following strict standards
- **Automated validation and health checking** integration
- **Branch-based patching system** with human oversight
- **Comprehensive testing and security** workflows
- **Documentation generation** with live validation
- **Continuous project maintenance** with change control
- **GitHub collaboration** with mandatory review process

## File Structure

### Main Configuration
- **`.github/copilot-instructions.md`**: Primary Copilot instructions with Git workflow requirements
- **`.vscode/settings.json`**: VS Code Copilot configuration with change control enforcement

### Instruction Files (`.github/instructions/`)
- **`powershell-standards.instructions.md`**: PowerShell coding standards with Git workflow
- **`testing-standards.instructions.md`**: Pester testing with patch branch requirements
- **`yaml-standards.instructions.md`**: YAML/workflow standards with validation gates
- **`configuration-standards.instructions.md`**: Configuration with change control
- **`documentation-standards.instructions.md`**: Documentation with Git-based updates
- **`maintenance-standards.instructions.md`**: **UPDATED** - Mandatory Git workflow for all maintenance
- **`git-collaboration.instructions.md`**: **ENHANCED** - Mandatory branch/PR workflow

### Prompt Files (`.github/prompts/`)
- **`generate-powershell-script.prompt.md`**: PowerShell generation with Git workflow integration
- **`generate-pester-tests.prompt.md`**: Test generation with patch branch workflow
- **`security-review.prompt.md`**: Security validation with Git audit trail
- **`generate-workflow.prompt.md`**: GitHub Actions with validation gates
- **`analyze-and-fix-code.prompt.md`**: **UPDATED** - Code analysis with mandatory Git workflow
- **`project-maintenance.prompt.md`**: **UPDATED** - Maintenance with Git-based change control
- **`create-feature-branch.prompt.md`**: Feature branches with validation requirements
- **`generate-documentation.prompt.md`**: Documentation with Git-tracked changes

## Key Features

### Git-Based Change Control (NEW)
- **Branch-Based Patches**: All fixes create dedicated patch branches
- **PR-Based Review**: Mandatory pull request workflow with human approval
- **Validation Gates**: Comprehensive validation before PR creation
- **Audit Trail**: Complete Git history with justification for all changes
- **Backup Integration**: Automatic backup before applying any changes
- **Rollback Capability**: Built-in rollback for failed patches

### PatchManager Integration - ENHANCED

> **CRITICAL**: PatchManager now enforces Git-based change control for ALL operations

#### Core PatchManager Functions - UPDATED
- **Git-Controlled Maintenance**: `Invoke-GitControlledPatch` for ALL patches and fixes
- **Validation Integration**: `Invoke-PatchValidation` for comprehensive pre-merge validation
- **PR Creation**: `New-PatchPullRequest` for standardized pull request workflow
- **Emergency Protocol**: `Invoke-EmergencyPatch` for critical system-breaking issues only

#### Legacy Functions (Still Available but Must Use Git Workflow)
- **Centralized Maintenance**: `Invoke-UnifiedMaintenance` - now creates patch branches
- **Test File Fixes**: `Invoke-TestFileFix` - now requires Git workflow
- **Infrastructure Fixes**: `Invoke-InfrastructureFix` - now creates PRs
- **YAML Validation**: `Invoke-YamlValidation` - now uses branch-based validation

#### Mandatory Usage Guidelines
1. **NEVER create standalone fix scripts** anywhere in the project
2. **ALWAYS use `Invoke-GitControlledPatch`** for all fixes and patches
3. **ALWAYS create pull requests** for human review and approval
4. **ALWAYS validate changes** before PR creation using `Invoke-PatchValidation`
5. **ALWAYS provide clear justification** for all patches and changes
6. **NEVER merge automatically** - human approval required for ALL changes

### GitHub Workflow Integration - ENHANCED
- **Mandatory Branch Management**: All changes go through feature/patch branches
- **PR-Based Development**: No direct commits to main branch allowed
- **Validation Gates**: Pre-commit and pre-merge validation requirements
- **Human Review Process**: Mandatory manual approval for all automated fixes
- **CI/CD Integration**: Enhanced validation with change control enforcement

### Continuous Validation with Change Control
- **Real-time Health Checks**: < 1 minute project health validation with Git integration
- **Branch-Based Validation**: All validation operations create patch branches
- **Cross-platform Testing**: Validation across Windows, Linux, macOS with Git workflow
- **Security Scanning**: Automated security validation with audit trail through Git

## Usage Examples

### Code Generation with Git Workflow
```powershell
# Copilot now automatically uses Git-controlled patching
Import-Module "/pwsh/modules/PatchManager" -Force

$result = Invoke-GitControlledPatch -PatchDescription "Generate new lab configuration script" -PatchOperation {
    # Generated code follows project standards AND Git workflow
    $newScript = @"
#Requires -Version 7.0
[CmdletBinding()]
param([object]$Config)

Import-Module "/pwsh/modules/LabRunner/" -Force

Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Starting lab configuration..." "INFO"
    # Generated code with proper patterns
}
"@
    Set-Content -Path "./scripts/new-lab-config.ps1" -Value $newScript
} -AffectedFiles @("./scripts/new-lab-config.ps1") -CreatePullRequest

Write-Host "📋 New script generated with Git workflow: $($result.PullRequest.Url)"
```

### Project Maintenance with Git Control
```powershell
# Before any development work
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Comprehensive validation with Git-based change control
Import-Module "/pwsh/modules/CodeFixer/" -Force
Invoke-ComprehensiveValidation -OutputFormat "Detailed" -AutoFix -CreatePullRequest
```

### GitHub Workflow
```bash
# Feature branch creation (enforced by instructions)
git checkout -b "feature/new-functionality"

# Pre-commit validation (automated)
pwsh -Command "Invoke-PreCommitChecklist"

# Semantic commits (guided by instructions)
git commit -m "feat(modules): Add health checking integration"
```

### Maintenance and Patching

```powershell
# PREFERRED: Always use PatchManager for maintenance and patching
Import-Module "/pwsh/modules/PatchManager" -Force

# Fix test files with automated changelog updates
Invoke-TestFileFix -Mode "Comprehensive" -Path "./tests/" -UpdateChangelog

# Run infrastructure fixes with automatic application
Invoke-InfrastructureFix -Fix "ImportPaths" -AutoFix -UpdateChangelog

# Clean up scattered fix scripts
Invoke-PatchCleanup -Mode "Full" -UpdateChangelog

# Run health checks and generate reports
$healthReport = Invoke-HealthCheck -Mode "Comprehensive" 
Show-MaintenanceReport -HealthData $healthReport -OutputPath "./reports/maintenance.md"

# YAML validation and fixes
Invoke-YamlValidation -Path "./.github/workflows/" -Mode "Fix"
```

### Troubleshooting Process

```powershell
# Step 1: Import the module
Import-Module "/pwsh/modules/PatchManager" -Force

# Step 2: Run health check to identify issues
$issues = Invoke-HealthCheck -Mode "Comprehensive" -OutputFormat "Object"

# Step 3: Apply targeted fixes based on issue type
foreach ($issue in $issues.Where{$_.Category -eq "TestSyntax"}) {
    Invoke-TestFileFix -Path $issue.FilePath -FixType "Comprehensive" -UpdateChangelog
}

# Step 4: Verify fixes worked
Invoke-HealthCheck -Mode "Quick"
```

## VS Code Settings Integration

The `.vscode/settings.json` includes:

```json
{
  "github.copilot.enable": {
    "*": true,
    "plaintext": true,
    "markdown": true,
    "powershell": true
  },
  "github.copilot.editor.enableCodeReview": true,
  "github.copilot.editor.enableCommitGeneration": true,
  "github.copilot.referencesInEditor": true,
  "github.copilot.editor.enableInstructionFiles": true,
  "github.copilot.editor.instructionFiles": [
    ".github/copilot-instructions.md",
    ".github/instructions/*.instructions.md"
  ],
  "github.copilot.editor.promptFiles": [
    ".github/prompts/*.prompt.md"
  ]
}
```

## Project Standards Enforcement

### Module Architecture
- **LabRunner Module**: `/pwsh/modules/LabRunner/` for execution and logging
- **CodeFixer Module**: `/pwsh/modules/CodeFixer/` for validation and fixing
- **Strict Import Paths**: Always use absolute paths for module imports

### Validation Requirements
- **PowerShell Linting**: PSScriptAnalyzer with parallel processing
- **YAML Validation**: yamllint with auto-formatting
- **JSON Validation**: Schema-based configuration validation
- **Cross-platform Testing**: Multi-OS compatibility verification

### Documentation Standards
- **Live Validation**: Documentation validated against current project state
- **Integration Requirements**: Links to project manifest and health checks
- **GitHub Workflow**: Documentation changes require feature branches and PR review

## Continuous Integration

### GitHub Actions Integration
- **Health Checks**: Automated project health validation on all PRs
- **Security Scanning**: Comprehensive security validation
- **Performance Monitoring**: Automated performance benchmarking
- **Cross-platform Testing**: Multi-OS test execution

### Branch Protection
- **Feature Branch Workflow**: No direct commits to main branch
- **Pre-commit Validation**: Comprehensive validation before any commit
- **PR Requirements**: Code review, validation passes, and documentation updates
- **Automated Cleanup**: Post-merge cleanup and project file updates

## Performance Targets

### Health Check Performance
- **Quick Health Check**: < 1 minute completion time
- **Comprehensive Validation**: < 5 minutes for full project scan
- **Parallel Processing**: Optimized for multi-core systems
- **Caching**: Smart caching to avoid redundant validation

### Project File Management
- **Automatic Updates**: PROJECT-MANIFEST.json updated with all changes
- **Index Regeneration**: Project indexes updated automatically
- **Issue Tracking**: Automated issue creation and resolution tracking
- **Performance Metrics**: Continuous health and performance monitoring

## Error Handling and Recovery

### Comprehensive Error Handling
- **Retry Logic**: Automatic retry for transient failures
- **Backup and Restore**: Automatic backups before major operations
- **Issue Creation**: Automated issue tracking for maintenance failures
- **Recovery Procedures**: Documented rollback and recovery processes

### Self-Validation
- **Maintenance Scripts**: All scripts validate their own requirements
- **Health Metrics**: Continuous monitoring of project health
- **Performance Tracking**: Automated performance regression detection
- **Quality Assurance**: Continuous validation of project standards

## Prompt Usage Examples

### Project Maintenance
```
@workspace Generate project maintenance report showing current health status, recent validation results, and recommended improvements using the project-maintenance prompt.
```

### Feature Branch Creation
```
@workspace Create a new feature branch for implementing automated security scanning with proper validation setup using the create-feature-branch prompt.
```

### Code Analysis and Fixing
```
@workspace Analyze and fix all PowerShell files in the project using CodeFixer module with comprehensive validation using the analyze-and-fix-code prompt.
```

### Documentation Generation
```
@workspace Generate comprehensive documentation for the LabRunner module including all functions, examples, and integration guidelines using the generate-documentation prompt.
```

### Security Review
```
@workspace Perform a comprehensive security review of all configuration files and workflows with focus on secrets management using the security-review prompt.
```

## Getting Started

1. **Verify Copilot Configuration**: Check that VS Code settings are properly configured
2. **Run Initial Health Check**: Execute `./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"`
3. **Validate Module Imports**: Ensure LabRunner and CodeFixer modules load correctly
4. **Test Copilot Integration**: Create a test PowerShell script and verify it follows project standards
5. **Create Feature Branch**: Practice the GitHub workflow with a test feature branch

## Troubleshooting

### Common Issues
- **Module Import Failures**: Check that absolute paths are used for module imports
- **Health Check Failures**: Run `unified-maintenance.ps1 -Mode "All" -AutoFix` to resolve issues
- **YAML Validation Errors**: Use `Invoke-YamlValidation.ps1 -Mode "Fix"` for auto-correction
- **GitHub Workflow Issues**: Verify branch protection rules and PR requirements

### Support Resources
- **Project Documentation**: `/docs/` directory for comprehensive guides
- **Maintenance Scripts**: `/scripts/maintenance/` for health checking and validation
- **Test Framework**: `/tests/` for validation and testing examples
- **Utility Scripts**: `/scripts/utilities/` for project management and maintenance

## Configuration Validation

To validate the complete setup:

```powershell
# Check instruction files
Get-ChildItem ".github/instructions/" -Filter "*.instructions.md"

# Check prompt files  
Get-ChildItem ".github/prompts/" -Filter "*.prompt.md"

# Validate VS Code settings
$settings = Get-Content ".vscode/settings.json" | ConvertFrom-Json
$settings.'github.copilot.editor.enableInstructionFiles'

# Test Copilot integration
Import-Module "/pwsh/modules/LabRunner/" -Force
Import-Module "/pwsh/modules/CodeFixer/" -Force

# Run health check to verify system
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
```

---

**Version**: 2.0  
**Last Updated**: 2025-01-14  
**Compatibility**: VS Code with GitHub Copilot extension  
**Project Health**: < 1 minute validation time  
**Standards**: OpenTofu Lab Automation project standards

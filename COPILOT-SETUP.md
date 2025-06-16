# GitHub Copilot Custom Instructions and Prompts

This document describes the comprehensive GitHub Copilot configuration for the OpenTofu Lab Automation project, including custom instructions, prompts, and project management integration.

## Overview

The project includes extensive Copilot customization for:
- **Project-specific code generation** following strict standards
- **Automated validation and health checking** integration
- **Comprehensive testing and security** workflows
- **Documentation generation** with live validation
- **Continuous project maintenance** and file synchronization
- **GitHub collaboration** with branch management and CI/CD
- **Issue tracking** and performance monitoring

## File Structure

### Main Configuration
- **`.github/copilot-instructions.md`**: Primary Copilot instructions with project context
- **`.vscode/settings.json`**: VS Code Copilot configuration and instruction file references
- **`repository-custom-instructions.md`**: Guide to adding repository instructions for Copilot (see `docs/copilot_docs/repository-custom-instructions.md`)

### Instruction Files (`.github/instructions/`)
- **`powershell-standards.instructions.md`**: PowerShell coding standards and patterns
- **`testing-standards.instructions.md`**: Pester testing framework and validation
- **`yaml-standards.instructions.md`**: YAML/workflow standards and validation
- **`configuration-standards.instructions.md`**: Configuration file and JSON standards
- **`documentation-standards.instructions.md`**: Documentation generation with maintenance integration
- **`maintenance-standards.instructions.md`**: Project health checking and continuous validation
- **`git-collaboration.instructions.md`**: GitHub workflow and branch management

### Prompt Files (`.github/prompts/`)
- **`generate-powershell-script.prompt.md`**: PowerShell script generation with health checks
- **`generate-pester-tests.prompt.md`**: Comprehensive test generation
- **`security-review.prompt.md`**: Security validation and review
- **`generate-workflow.prompt.md`**: GitHub Actions workflow generation
- **`analyze-and-fix-code.prompt.md`**: Code analysis and automated fixing
- **`project-maintenance.prompt.md`**: Project health checking and maintenance
- **`create-feature-branch.prompt.md`**: Feature branch creation with validation
- **`generate-documentation.prompt.md`**: Documentation generation with validation

## Key Features

### Automatic Project Maintenance
- **Health Checking**: Continuous validation with `unified-maintenance.ps1`
- **File Synchronization**: Automatic PROJECT-MANIFEST.json and index updates
- **Issue Tracking**: Automated issue creation and resolution tracking
- **Performance Monitoring**: Health metrics and performance benchmarking

### GitHub Workflow Integration
- **Branch Management**: Enforced feature branch workflow with semantic commits
- **Pre-commit Validation**: Comprehensive validation before any commit
- **CI/CD Integration**: Automated validation in GitHub Actions
- **Pull Request Standards**: Structured PR templates with validation requirements

### Continuous Validation
- **Real-time Health Checks**: < 1 minute project health validation
- **Self-Validation**: All maintenance scripts validate their own requirements
- **Cross-platform Testing**: Windows, Linux, macOS compatibility validation
- **Security Scanning**: Automated security validation and review

## Usage Examples

### Code Generation
```powershell
# Copilot automatically includes proper patterns
Import-Module "/pwsh/modules/LabRunner/" -Force

Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Starting operation..." "INFO"
    # Generated code follows project standards
}
```

### Project Maintenance
```powershell
# Before any development work
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Comprehensive validation
Import-Module "/pwsh/modules/CodeFixer/" -Force
Invoke-ComprehensiveValidation -OutputFormat "Detailed" -AutoFix
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

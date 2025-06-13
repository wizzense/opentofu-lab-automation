# CodeFixer Module Guide

This guide provides detailed information on how to use the CodeFixer PowerShell module, which is the core component of the OpenTofu Lab Automation testing framework.

## Table of Contents
- [Installation and Setup](#installation-and-setup)
- [Module Structure](#module-structure)
- [Key Functions](#key-functions)
- [Automation Integration](#automation-integration)
- [Common Usage Scenarios](#common-usage-scenarios)
- [Extending the Module](#extending-the-module)
- [Troubleshooting](#troubleshooting)

## Installation and Setup

The CodeFixer module is already installed as part of the OpenTofu Lab Automation project. To use it:

1. Import the module:

```powershell
Import-Module ./pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
```

2. Run the various functions as needed:

```powershell
Invoke-PowerShellLint
Invoke-AutoFix -ApplyFixes
Invoke-ComprehensiveValidation
```

## Module Structure

The CodeFixer module follows a standard PowerShell module structure:

```
pwsh/
└── modules/
    └── CodeFixer/
        ├── CodeFixer.psd1         # Module manifest
        ├── CodeFixer.psm1         # Module loader
        ├── Public/                # Public functions
        │   ├── Invoke-AutoFix.ps1
        │   ├── Invoke-ComprehensiveValidation.ps1
        │   ├── Invoke-PowerShellLint.ps1
        │   ├── Invoke-ResultsAnalysis.ps1
        │   ├── Invoke-ScriptOrderFix.ps1
        │   ├── Invoke-TernarySyntaxFix.ps1
        │   ├── Invoke-TestSyntaxFix.ps1
        │   ├── New-AutoTest.ps1
        │   └── Watch-ScriptDirectory.ps1
        └── Private/               # Private helper functions
            ├── Get-SyntaxError.ps1
            └── Resolve-ScriptPath.ps1
```

## Key Functions

### Invoke-AutoFix

Runs all available fixers in sequence.

```powershell
Invoke-AutoFix -ApplyFixes -ScriptPaths "path/to/script.ps1", "path/to/another/script.ps1" -FixTypes Syntax, Ternary
```

**Parameters:**
- `-ApplyFixes` - Actually apply the fixes (otherwise just report)
- `-ScriptPaths` - Array of script paths to fix (defaults to all PowerShell scripts)
- `-FixTypes` - Types of fixes to apply ('All', 'Syntax', 'Ternary', 'ScriptOrder', 'ImportModule')
- `-Quiet` - Suppress output
- `-Force` - Force fixes even if the script appears valid

### Invoke-PowerShellLint

Runs and reports on PowerShell linting.

```powershell
Invoke-PowerShellLint -OutputFormat JSON -OutputPath "linting-results.json" -FixErrors
```

**Parameters:**
- `-OutputFormat` - Format of the output ('Default', 'CI', 'JSON', 'Detailed')
- `-OutputPath` - Path to save the results
- `-FixErrors` - Attempt to fix detected errors
- `-IncludeArchive` - Include archive directories in linting

### New-AutoTest

Generates tests for PowerShell scripts.

```powershell
New-AutoTest -ScriptPath "path/to/script.ps1" -Force
```

**Parameters:**
- `-ScriptPath` - Path to the script to generate tests for
- `-OutputDirectory` - Directory to place the generated test
- `-Force` - Overwrite existing tests
- `-Template` - Custom template to use for test generation

### Invoke-ComprehensiveValidation

Runs a full validation suite including linting, test execution, and fixing.

```powershell
Invoke-ComprehensiveValidation -ApplyFixes -GenerateTests -OutputFormat CI -OutputPath "validation-report.json"
```

**Parameters:**
- `-ApplyFixes` - Apply fixes to detected issues
- `-GenerateTests` - Generate missing tests
- `-OutputFormat` - Format of the output ('Text', 'JSON', 'CI')
- `-OutputPath` - Path to save the validation report
- `-OutputComprehensiveReport` - Create a comprehensive report object
- `-CI` - Run in CI mode (stricter validation)

## Automation Integration

### Project Maintenance Automation
CodeFixer integrates with the project's automated maintenance system:

```powershell
# Run automated maintenance with CodeFixer integration
./scripts/maintenance/auto-maintenance.ps1 -Task "fix-imports"

# Full maintenance cycle including CodeFixer validation
./scripts/maintenance/auto-maintenance.ps1 -Task "full" -GenerateReport
```

### Agent Integration (AI/Copilot)
For AI agents and GitHub Copilot, CodeFixer provides automated validation:

```powershell
# Required after any module structure changes
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer"
Invoke-ComprehensiveValidation
Invoke-ImportAnalysis -AutoFix
```

### Report Generation Integration
CodeFixer validation results can trigger automatic report generation:

```powershell
# Generate test analysis report if validation finds issues
./scripts/utilities/new-report.ps1 -Type "test-analysis" -Title "CodeFixer Validation Results" -Template "test"
```

### Pre-Commit Hook Integration
CodeFixer works with the project's pre-commit validation:

```bash
# Install pre-commit hook that includes CodeFixer validation
pwsh tools/pre-commit-hook.ps1 -Install
```

## Common Usage Scenarios

### Fixing Common Syntax Issues

To automatically fix common syntax issues in your scripts:

```powershell
# Fix all scripts in the project
Invoke-AutoFix -ApplyFixes

# Fix specific scripts
Invoke-AutoFix -ApplyFixes -ScriptPaths "./scripts/my-script.ps1"

# Fix only specific types of issues
Invoke-AutoFix -ApplyFixes -FixTypes Syntax, Ternary
```

### Running Linting

To lint your PowerShell code:

```powershell
# Basic linting
Invoke-PowerShellLint

# Lint and fix errors
Invoke-PowerShellLint -FixErrors

# Output JSON report
Invoke-PowerShellLint -OutputFormat JSON -OutputPath "reports/lint-results.json"
```

### Generating Tests

To generate tests for PowerShell scripts:

```powershell
# Generate tests for a specific script
New-AutoTest -ScriptPath "./pwsh/modules/MyModule/MyFunction.ps1"

# Force regeneration of tests
New-AutoTest -ScriptPath "./pwsh/modules/MyModule/MyFunction.ps1" -Force

# Watch for changes and generate tests
Watch-ScriptDirectory -DirectoryPath "./pwsh/modules/MyModule"
```

### Full System Validation

To run a complete validation of your codebase:

```powershell
# Basic validation
Invoke-ComprehensiveValidation

# Validation with fixes and test generation
Invoke-ComprehensiveValidation -ApplyFixes -GenerateTests

# Validation for CI with JSON output
Invoke-ComprehensiveValidation -CI -OutputFormat JSON -OutputPath "validation-report.json"
```

## Extending the Module

### Adding New Fixers

To add a new fixer:

1. Create a new script in the `Public` directory (e.g., `Invoke-NewFixerType.ps1`)
2. Implement the fixer function
3. Add the new fixer type to the `Invoke-AutoFix` function's `FixTypes` parameter
4. Update the module manifest to include the new script

### Customizing Test Templates

To use custom test templates:

1. Create a template file in the `tests/templates` directory
2. Use the `-Template` parameter when calling `New-AutoTest`

## Troubleshooting

### Common Issues

1. **Syntax errors not being fixed**
   - Check if the script has unusual formatting or custom syntax
   - Try using `-Force` parameter with `Invoke-AutoFix`

2. **Test generation failing**
   - Ensure the script follows standard PowerShell conventions
   - Check if the script has proper function documentation
   - Use `-Verbose` to see more detailed error information

3. **Linting reporting false positives**
   - Consider adding specific rules to exclusions in `PSScriptAnalyzerSettings.psd1`

### Getting Help

For more detailed help on any function, use Get-Help:

```powershell
Get-Help Invoke-AutoFix -Full
Get-Help Invoke-ComprehensiveValidation -Examples
```

## Integration with CI/CD

The CodeFixer module is integrated with GitHub Actions workflows:

- **unified-ci.yml** - Runs the comprehensive validation
- **auto-test-generation.yml** - Generates tests for new or modified scripts

To customize this integration, edit these workflow files in the `.github/workflows` directory.

# CodeFixer PowerShell Module

This module provides comprehensive automation tools for fixing, testing, and validating PowerShell scripts in the OpenTofu Lab Automation project.

## Structure

- **CodeFixer.psd1** - Module manifest
- **CodeFixer.psm1** - Module loader
- **Public/** - Public functions available to users
- **Private/** - Private helper functions used internally

## Key Functions

### Public Functions

- **Invoke-AutoFix** - Runs all available fixers in sequence
- **Invoke-PowerShellLint** - Runs and reports on PowerShell linting
- **Invoke-TestSyntaxFix** - Fixes common syntax errors in test files
- **Invoke-TernarySyntaxFix** - Fixes ternary operator issues
- **Invoke-ScriptOrderFix** - Fixes Import-Module/Param order
- **New-AutoTest** - Generates tests for PowerShell scripts
- **Watch-ScriptDirectory** - Watches for changes and generates tests
- **Invoke-ComprehensiveValidation** - Runs full validation suite
- **Invoke-ResultsAnalysis** - Parses test results and applies fixes

### Private Functions

- **Get-SyntaxError** - Detects common syntax errors
- **Resolve-ScriptPath** - Resolves script paths for processing

## Usage



## Documentation

For detailed usage information, see:
- [CODEFIXER-GUIDE.md](../../../docs/CODEFIXER-GUIDE.md)
- [TESTING.md](../../../docs/TESTING.md)

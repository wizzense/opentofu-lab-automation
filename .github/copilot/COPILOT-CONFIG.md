# OpenTofu Lab Automation - Copilot Configuration

## Project Overview
The OpenTofu Lab Automation project is a comprehensive testing and automation framework for OpenTofu scripts. The project uses PowerShell and Python for automation tasks, with a strong emphasis on testing, validation, and automatic fixing of common issues.

## Key Components

### CodeFixer PowerShell Module (Enhanced 2025-06-13)
Located at `/pwsh/modules/CodeFixer/`, this is the core module that provides automated tools for fixing common issues, import analysis, and comprehensive validation. 

Key functions in this module include:
- `Invoke-PowerShellLint`: Enhanced linting with PSScriptAnalyzer auto-installation
- `Invoke-ImportAnalysis`: NEW - Detects and fixes import issues, outdated paths
- `Invoke-AutoFix`: Runs automated syntax and structure fixes
- `Invoke-ComprehensiveValidation`: Runs full validation suite
- `Test-JsonConfig`: Validates JSON configuration files

### LabRunner PowerShell Module (Moved 2025-06-13)
**IMPORTANT:** LabRunner has been moved from `/pwsh/lab_utils/LabRunner/` to `/pwsh/modules/LabRunner/`

This module provides core lab automation functionality and should be imported as:
```powershell
Import-Module "/path/to/pwsh/modules/LabRunner" -Force
```

### Import Analysis and Path Migration
The CodeFixer module now includes `Invoke-ImportAnalysis` which:
- Automatically detects outdated `lab_utils` path references
- Identifies missing module imports (PSScriptAnalyzer, Pester, etc.)
- Provides auto-fix capability for common import issues
- Ensures all scripts use the correct module paths

### Main Runner Scripts
The following scripts in the root directory serve as wrappers around the CodeFixer module:
- `invoke-comprehensive-validation.ps1`: Runs all validations, fixes, and test generation
- `auto-fix.ps1`: Automated fixing of common issues
- `comprehensive-lint.ps1`: PowerShell linting
- `comprehensive-health-check.ps1`: Performs system health checks

### GitHub Actions Workflows
Located in `/.github/workflows/`, these workflows automate testing and validation:
- `unified-ci.yml`: Main CI/CD pipeline for validation, linting, testing, and health checks
- `auto-test-generation.yml`: Automatically generates tests for new/modified scripts

## Best Practices for This Project

1. **Use the CodeFixer Module**: When making changes to PowerShell scripts, use the CodeFixer module to validate, fix issues, and generate tests.

2. **Follow Test Generation Pattern**: All PowerShell scripts should have corresponding `.Tests.ps1` files generated with the `New-AutoTest` function.

3. **Use the Comprehensive Validation Script**: Before submitting changes, run `./invoke-comprehensive-validation.ps1` to ensure all validations pass.

4. **Keep Workflows Updated**: If you modify the CodeFixer module or its functions, update the corresponding GitHub Actions workflows to use the new functionality.

5. **Use Standard Code Formatting**: Code should follow PowerShell standard practices and pass PSScriptAnalyzer checks.

## Common Tasks

### Adding a New Script
When adding a new PowerShell script:
1. Place it in the appropriate directory under `/pwsh/`
2. Ensure proper module imports using `Invoke-ImportAnalysis -AutoFix`
3. Generate tests using `New-AutoTest -ScriptPath "path/to/script.ps1"`
4. Run validation with `Invoke-ComprehensiveValidation`

### Fixing Issues in Existing Scripts
To fix common issues in existing scripts:
1. Run `Invoke-ImportAnalysis -AutoFix` to fix import and path issues
2. Run `Invoke-AutoFix -ApplyFixes` to automatically fix common problems
3. Use `Invoke-PowerShellLint` for enhanced linting with auto PSScriptAnalyzer install
4. For JSON configs: `Test-JsonConfig -Path "config.json" -AutoFix`

### Import Analysis and Path Migration
To analyze and fix import issues across the project:
1. **Scan for issues**: `Invoke-ImportAnalysis -Path "./pwsh"`
2. **Auto-fix issues**: `Invoke-ImportAnalysis -Path "./pwsh" -AutoFix`
3. **CI format**: `Invoke-ImportAnalysis -OutputFormat CI`

### Testing and Module Integration
To work with the updated module structure:
1. **Import LabRunner**: `Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/LabRunner"`
2. **Import CodeFixer**: `Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer"`
3. **Run tests**: Tests automatically load from correct module paths via TestHelpers.ps1

### Running Full Validation
To validate the entire codebase:
1. Run `./invoke-comprehensive-validation.ps1`
2. For CI environments: `./invoke-comprehensive-validation.ps1 -OutputFormat CI -SaveResults`
3. To apply fixes: `./invoke-comprehensive-validation.ps1 -Fix`

## Documentation
For more information, refer to:
- `/docs/TESTING.md`: Detailed testing framework documentation
- `/docs/CODEFIXER-GUIDE.md`: Comprehensive guide to the CodeFixer module

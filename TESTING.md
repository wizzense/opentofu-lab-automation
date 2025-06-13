# OpenTofu Lab Testing Framework

This document describes the testing framework and workflows used in the OpenTofu Lab Automation project.

## Testing Structure

The project uses several testing tools and frameworks:

1. **PowerShell Linting** - Using PSScriptAnalyzer to check code quality
2. **Pester Tests** - For PowerShell unit and integration tests
3. **PyTest** - For Python unit and integration tests
4. **Comprehensive Health Checks** - To verify the system status

## Key Scripts

The following scripts are available for running tests:

- `run-comprehensive-tests.ps1` - Run all tests locally
- `comprehensive-lint.ps1` - Run PowerShell linting
- `comprehensive-health-check.ps1` - Check system health
- `fix-ternary-syntax.ps1` - Fix syntax issues in test files
- `clean-workflows.ps1` - Archive redundant workflow files

## GitHub Workflows

The project uses GitHub Actions for CI/CD. The main workflow is:

- `unified-ci.yml` - Runs all tests and checks

### Testing Workflow

Here's the standard workflow for testing:

1. **Validate** - Basic validation of workflow files
2. **Lint** - PowerShell linting
3. **PyTest** - Python tests
4. **Pester** - PowerShell tests on Linux
5. **Health Check** - System health verification
6. **Workflow Health Monitor** - Checks workflow execution trends

## Running Tests Locally

To run all tests locally:

```powershell
./run-comprehensive-tests.ps1
```

To run specific test categories:

```powershell
./run-comprehensive-tests.ps1 -SkipLint -SkipPyTest
```

## Clean Up Workflows

To identify redundant workflows:

```powershell
./clean-workflows.ps1 -WhatIf
```

To archive redundant workflows:

```powershell
./clean-workflows.ps1 -Archive
```

## Testing Best Practices

1. Always run linting and tests before committing code
2. Keep tests focused and maintainable
3. Avoid ternary operators in PowerShell tests (use if/else instead)
4. Add new tests for every new feature or bug fix
5. Use proper assertions and mocks in tests

## Common Test Issues

1. **Ternary Operators** - PowerShell doesn't natively support ternary operators; use if/else instead
2. **Parameter Validation** - Ensure all script parameters are properly declared and documented
3. **Module Loading** - Tests should properly load the required modules
4. **Cross-Platform Support** - Tests should run on Windows, Linux and macOS

# Extensible Testing Framework

## Overview

This project uses an extensible, cross-platform testing framework that automatically:
- **Generates tests** for new PowerShell scripts
- **Enforces naming conventions** 
- **Categorizes tests** by functionality
- **Supports platform-specific testing**
- **Integrates with CI/CD pipelines**

## Script Naming Conventions

### Standard Scripts
- Use **PascalCase** with **Verb-Noun** pattern
- Examples: `Install-Node.ps1`, `Configure-DNS.ps1`, `Enable-WinRM.ps1`

### Runner Scripts (in `pwsh/runner_scripts/`)
- Use **4-digit sequence number** + **Verb-Noun** pattern
- Format: `nnnn_Verb-Noun.ps1`
- Examples: `0101_Install-Git.ps1`, `0201_Configure-Environment.ps1`

### Test Files
- Automatically generated as `ScriptName.Tests.ps1`
- Examples: `Install-Node.Tests.ps1`, `0101_Install-Git.Tests.ps1`

## Automatic Test Generation

### How It Works
1. **File Monitoring**: GitHub Actions detects new/modified PowerShell scripts
2. **Name Validation**: Automatically renames scripts to follow conventions
3. **Test Generation**: Creates comprehensive test files based on script analysis
4. **Platform Detection**: Determines platform compatibility and requirements
5. **Category Assignment**: Assigns tests to categories (Installer, Configuration, etc.)

### Manual Test Generation
```powershell
# Generate test for specific script
./tests/helpers/New-AutoTestGenerator.ps1 -ScriptPath "pwsh/runner_scripts/0301_Install-NewTool.ps1"

# Generate tests for all scripts in directory
./tests/helpers/New-AutoTestGenerator.ps1 -WatchDirectory "pwsh/runner_scripts"

# Start file watcher for automatic generation
./tests/helpers/New-AutoTestGenerator.ps1 -WatchMode -WatchIntervalSeconds 30
```

## Test Categories

The framework automatically categorizes tests:

- **Installer**: Installs software or dependencies
- **Configuration**: Modifies system or app settings
- **Feature**: Enables/disables features
- **Service**: Manages services or daemons
- **Integration**: Multi-script or end-to-end tests

## Running Tests

- Use `pwsh -NoLogo -NoProfile -Command "Invoke-Pester"` for PowerShell
- Use `pytest py` for Python
- See testing.md(testing.md) for local setup
- See pester-test-failures.md(pester-test-failures.md) for tracked failures

## Extending the Framework

- Add new templates to `tests/helpers/TestTemplates.ps1`
- Add new categories by updating the test generator
- Use mocks in `tests/helpers/` for platform-specific logic

---

For more, see the Documentation Index(index.md).

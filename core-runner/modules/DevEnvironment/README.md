# DevEnvironment Module

Development environment setup and management for OpenTofu Lab Automation. Provides tools for Git hooks, development workspace configuration, and project cleanup.

## Features

- **Git pre-commit hooks** management
- **Development environment** setup and validation
- **Project cleanup** utilities (emoji removal, etc.)
- **Module import** troubleshooting
- **Cross-platform** support

## Installation

```powershell
Import-Module './core-runner/modules/DevEnvironment' -Force
```

## Exported Functions

### Git Hook Management

- `Install-PreCommitHook` - Install Git pre-commit hook for the repository
- `Remove-PreCommitHook` - Remove Git pre-commit hook
- `Test-PreCommitHook` - Test if pre-commit hook is installed and functional

### Environment Setup

- `Set-DevelopmentEnvironment` - Configure development environment settings
- `Test-DevelopmentSetup` - Validate development environment is properly configured
- `Initialize-DevelopmentEnvironment` - Complete environment initialization

### Maintenance

- `Remove-ProjectEmojis` - Clean up emoji characters from project files
- `Resolve-ModuleImportIssues` - Troubleshoot and fix module import problems

## Basic Usage

### Setup Development Environment

```powershell
# Initialize full development environment
Initialize-DevelopmentEnvironment

# Test current setup
Test-DevelopmentSetup
```

### Manage Git Hooks

```powershell
# Install pre-commit hook
Install-PreCommitHook

# Test hook installation
Test-PreCommitHook

# Remove hook
Remove-PreCommitHook
```

### Project Maintenance

```powershell
# Remove emoji characters from files (for compatibility)
Remove-ProjectEmojis

# Fix module import issues
Resolve-ModuleImportIssues
```

## Dependencies

The DevEnvironment module dynamically imports the Logging module with fallback support:
- Attempts to import Logging module from multiple locations
- Provides fallback logging if Logging module is unavailable
- No hard dependency - can operate standalone

## Version

Current Version: 1.0.0

## License

Copyright (c) 2025 Wizzense. All rights reserved.

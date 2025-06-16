# Core Application Module (CoreApp)

## Overview

The CoreApp module provides a unified interface for running the core OpenTofu lab automation application. It consolidates all essential scripts and configurations needed for core functionality, separate from project maintenance tasks.

## Environment Variables

The module relies on these environment variables:

- `$env:PROJECT_ROOT` - Root directory of the project
- `$env:PWSH_MODULES_PATH` - Path to PowerShell modules
- `$env:PLATFORM` - Current platform (Windows/Linux/macOS)

## Module Structure

```text
pwsh/core_app/
├── CoreApp.psd1          # Module manifest
├── CoreApp.psm1          # Module implementation
├── default-config.json   # Default configuration
├── scripts/              # Core application scripts
│   ├── 0007_Install-Go.ps1
│   ├── 0008_Install-OpenTofu.ps1
│   ├── 0009_Initialize-OpenTofu.ps1
│   └── Invoke-CoreApplication.ps1
└── README.md            # This file
```

## Usage

```powershell
# Import the module
Import-Module "$env:PWSH_MODULES_PATH/../core_app/" -Force

# Run the core application
Invoke-CoreApplication -ConfigPath "$env:PROJECT_ROOT/pwsh/core_app/default-config.json"

# Or use individual scripts
& "$env:PROJECT_ROOT/pwsh/core_app/scripts/0008_Install-OpenTofu.ps1"
```

## Key Features

- **Environment Variable Based**: No hardcoded paths
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **Modular**: Individual scripts can be run independently
- **Standardized**: Follows project PowerShell standards
- **Unified Configuration**: Single config file for all operations

## Scripts Included

- **Go Installation**: `0007_Install-Go.ps1`
- **OpenTofu Installation**: `0008_Install-OpenTofu.ps1`
- **OpenTofu Initialization**: `0009_Initialize-OpenTofu.ps1`
- **Core Application Entry Point**: `Invoke-CoreApplication.ps1`

## Configuration

The `default-config.json` provides standard settings that can be customized for different environments.

## Integration

This module integrates with:

- LabRunner module (for execution framework)
- CodeFixer module (for validation)
- PatchManager module (for change control)

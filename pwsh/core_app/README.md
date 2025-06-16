# Core Application Module

This module consolidates all scripts and configurations required for running the core application. It separates core logic from project maintenance tasks for better organization and maintainability.

## Structure

- **Scripts**: Core application scripts migrated from `runner_scripts`.

- **Configurations**: Essential configuration files like `default-config.json`.

## Usage

Import the module and use the provided scripts for core application execution.

```powershell
Import-Module "/pwsh/core_app/"
Invoke-CoreApplication -Config "default-config.json"
```

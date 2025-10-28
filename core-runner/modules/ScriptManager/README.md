# ScriptManager Module

Centralized management for one-off scripts in OpenTofu Lab Automation. Ensures scripts are properly registered, validated, and tracked.

## Features

- **Script registration** with metadata tracking
- **Script validation** for required dependencies
- **Execution tracking** with results logging
- **JSON-based metadata** storage

## Installation

```powershell
Import-Module './core-runner/modules/ScriptManager' -Force
```

## Exported Functions

- `Register-OneOffScript` - Register a script with metadata
- `Test-OneOffScript` - Validate script structure and dependencies
- `Invoke-OneOffScript` - Execute a registered one-off script

## Basic Usage

### Register a Script

```powershell
Register-OneOffScript -ScriptPath "./scripts/my-script.ps1" `
                      -Purpose "Fix configuration issues" `
                      -Author "DevTeam"

# Force re-registration
Register-OneOffScript -ScriptPath "./scripts/my-script.ps1" `
                      -Purpose "Updated purpose" `
                      -Author "DevTeam" `
                      -Force
```

### Validate a Script

```powershell
# Check if script meets requirements
Test-OneOffScript -ScriptPath "./scripts/my-script.ps1"
```

### Execute a Script

```powershell
# Run registered script
Invoke-OneOffScript -ScriptPath "./scripts/my-script.ps1"

# Force execution even if already executed
Invoke-OneOffScript -ScriptPath "./scripts/my-script.ps1" -Force
```

## Metadata Storage

Scripts are tracked in `scripts/one-off-scripts.json`:

```json
{
  "ScriptPath": "./scripts/example.ps1",
  "Purpose": "Fix specific issue",
  "Author": "DevTeam",
  "RegisteredDate": "2025-01-15 10:30:00",
  "Executed": false,
  "ExecutionDate": null,
  "ExecutionResult": null
}
```

## Script Validation

The module validates that scripts:
- Exist at the specified path
- Import required modules properly
- Use modern function patterns (e.g., `Invoke-ParallelScriptAnalyzer`)
- Avoid deprecated functions (e.g., `Invoke-BatchScriptAnalysis`)

## Best Practices

1. **Always register** scripts before execution
2. **Include clear purpose** descriptions for tracking
3. **Use module imports** in scripts for dependency management
4. **Test scripts** before marking them for execution
5. **Track execution** results for audit purposes

## Version

Current Version: 1.0.0

## License

Copyright (c) 2025 Wizzense. All rights reserved.

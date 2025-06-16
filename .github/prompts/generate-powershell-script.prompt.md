---
description: Generate a comprehensive PowerShell script following OpenTofu Lab Automation standards
mode: agent
tools: "filesystem", "semantic_search", "codebase"
---

# Generate PowerShell Script

Create a PowerShell script for the OpenTofu Lab Automation project that follows all established standards and patterns.

## Context and Requirements

Start by understanding the project context using #codebase to find similar patterns and existing implementations.

### Primary Requirements

1. **Standard Template Structure** - Use the established project template:
   - Parameter block with `pscustomobject$Config`
   - Error handling with `$ErrorActionPreference = "Stop"`
   - Import LabRunner module: `Import-Module "/pwsh/modules/LabRunner/" -Force`
   - Main execution using `Invoke-LabStep` pattern

2. **GitHub Actions Validation Integration** - Include validation hooks:
   - Pre-execution health checks using `unified-maintenance.ps1`
   - Post-execution validation with revert capability
   - Cross-platform testing integration
   - Commit validation through GitHub Actions workflow monitoring

3. **Comprehensive Error Handling** - Implement robust error management:
   - Try-catch blocks with `Write-CustomLog` for all errors
   - Input parameter validation with detailed error messages
   - Backup creation before making changes
   - Automatic rollback on validation failures

4. **Cross-Platform Support** - Ensure compatibility:
   - Use `Join-Path` for all file path operations
   - Use `Get-Platform` for platform-specific logic
   - Use `Invoke-CrossPlatformCommand` for system commands
   - Test on Windows, Linux, and macOS via GitHub Actions

5. **Validation and Health Checking** - Integrate self-validation:
   - Run health checks before and after execution
   - Validate module imports and dependencies
   - Monitor GitHub Actions workflow status
   - Implement fix validation with automatic revert

## Specific Examples to Follow

Reference these existing patterns from #codebase:

### Module Import Pattern
```powershell
# Always use absolute paths
Import-Module "/pwsh/modules/LabRunner/" -Force
Import-Module "/pwsh/modules/CodeFixer/" -Force
```

### Error Handling Pattern
```powershell
try {
    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Starting operation: $OperationName" "INFO"
        # Your operation here
        Write-CustomLog "Operation completed successfully" "INFO"
    }
} catch {
    Write-CustomLog "Operation failed: $($_.Exception.Message)" "ERROR"
    throw
}
```

### Validation Pattern
```powershell
# Pre-execution validation
$healthBefore = ./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
if ($healthBefore.TotalErrors -gt 0) {
    throw "Pre-execution health check failed with $($healthBefore.TotalErrors) errors"
}
```

## Template Structure

Use this exact template structure:

```powershell
<#
.SYNOPSIS
Brief description of script purpose

.DESCRIPTION
Detailed description of what the script does and how it works

.PARAMETER Config
Configuration object containing script parameters and settings

.EXAMPLE
$config = pscustomobject@{
    Property = "Value"
}
.\ScriptName.ps1 -Config $config

.NOTES
Additional notes about requirements, dependencies, or usage
#>
Param(
    Parameter(Mandatory=$true)
    pscustomobject$Config
)

$ErrorActionPreference = "Stop"

# Import required modules
Import-Module "/pwsh/modules/LabRunner/" -Force

# Main execution
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Starting script execution..." "INFO"
    
    try {
        # Your implementation here
        
        Write-CustomLog "Script completed successfully" "INFO"
    } catch {
        Write-CustomLog "Script failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}
```

## Specific Requirements

- **Input**: Script purpose and any specific requirements
- **Output**: Complete PowerShell script with proper structure
- **Variables**: Use `${input:scriptName}` for the script name and `${input:purpose}` for the script purpose

Please specify:
1. The script name (without .ps1 extension)
2. The main purpose/functionality of the script
3. Any specific parameters or operations needed
4. Target platform requirements (if any)

## Reference Instructions

Reference the following instruction files for detailed standards:
- PowerShell Standards(../instructions/powershell-standards.instructions.md)
- Testing Standards(../instructions/testing-standards.instructions.md)

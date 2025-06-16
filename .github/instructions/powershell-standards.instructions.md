---
applyTo: "**/*.ps1"
description: PowerShell coding standards and best practices for the OpenTofu Lab Automation project
---

# PowerShell Development Instructions

## Quick Reference

### Module Import Standards
 **Correct**                                **Deprecated**                  
-----------------------------------------------------------------------------
 `Import-Module "/pwsh/modules/CodeFixer/" -Force`  `Import-Module "pwsh/lab_utils/LabRunner"` 

### Script Structure
Template:
```powershell
Param(
    Parameter(Mandatory=$true)
    pscustomobject$Config
)

$ErrorActionPreference = "Stop"
Import-Module "/pwsh/modules/LabRunner/" -Force
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Starting operation..." "INFO"
    # Implementation
    Write-CustomLog "Operation completed successfully" "INFO"
}
```

## Detailed Instructions

### Error Handling
Use:
```powershell
try {
    $result = SomeOperation
    Write-CustomLog "Operation successful: $result" "INFO"
} catch {
    Write-CustomLog "Operation failed: $($_.Exception.Message)" "ERROR"
    throw
}
```

### Testing Standards
Use Pester:
```powershell
Describe 'ScriptName Tests' {
    It 'should import required modules' {
        Get-Module LabRunner  Should -Not -BeNullOrEmpty
    }
}
```

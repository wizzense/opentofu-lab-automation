# Unified Project Guidelines

## Overview
This document consolidates all project guidelines, including Git collaboration, Copilot configurations, and agent instructions, into a single source of truth.

---

## Git Collaboration

### Branch Management
- **Create Feature Branch**: Use PatchManager to create branches: `./pwsh/modules/PatchManager/Public/Invoke-GitControlledPatch.ps1 -CreateBranch feature/<description>`
- **Push Feature Branch**: `git push -u origin feature/<description>`
- **Create Pull Request**: Use PatchManager to open PRs: `./pwsh/modules/PatchManager/Public/Invoke-GitControlledPatch.ps1 -OpenPR -Title "feat(scope): description" -Body "Detailed description"`

### Commit Standards
 **Type**    **Scope**        **Example**                                
-------------------------------------------------------------------------
 feat        codefixer        feat(codefixer): add parallel processing   
 fix         labrunner        fix(labrunner): resolve path issues        
 docs        readme           docs(readme): update installation guide    
 chore       deps             chore(deps): update dependencies           

### Pre-Commit Validation
Run:
```powershell
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
Invoke-PowerShellLint -Path "./scripts/" -Parallel
```

---

## Copilot Configuration

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

---

## Agent Instructions

### Maintenance Commands
 **Command**                                 **Purpose**                     
-----------------------------------------------------------------------------
 `./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"`  Quick health assessment         
 `./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix`  Comprehensive health check      
 `./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"`  YAML validation and formatting  

### Validation Sequence
Run:
```powershell
Import-Module "/pwsh/modules/CodeFixer/" -Force
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
Invoke-PowerShellLint -Path $ChangedFiles -PassThru
Update-ProjectManifest -Changes $Changes
```

---

## Project File Management

### PROJECT-MANIFEST.json Updates
Always update the project manifest after changes:
```powershell
# Read current manifest
$manifest = Get-Content "./PROJECT-MANIFEST.json"  ConvertFrom-Json

# Update last modified
$manifest.project.lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Save updated manifest
$manifest  ConvertTo-Json -Depth 10  Set-Content "./PROJECT-MANIFEST.json"

# Validate manifest structure
Test-JsonConfig -Path "./PROJECT-MANIFEST.json"
```

---

## Cleanup and Organization

### Automated Cleanup Procedures
```powershell
# Clean temporary files
Get-ChildItem -Path "." -Recurse -Filter "*.tmp"  Remove-Item -Force
Get-ChildItem -Path "." -Recurse -Filter "*.log" -OlderThan (Get-Date).AddDays(-7)  Remove-Item -Force

# Organize archive files
$archiveThreshold = (Get-Date).AddDays(-30)
Get-ChildItem -Path "./coverage/" -Recurse -File  Where-Object { 
    $_.LastWriteTime -lt $archiveThreshold 
}  Move-Item -Destination "./archive/coverage/"

# Clean up test artifacts
Remove-Item "./TestResults*.xml" -Force -ErrorAction SilentlyContinue
Remove-Item "./coverage/lcov.info" -Force -ErrorAction SilentlyContinue

# Validate file organization
./scripts/maintenance/organize-project-files.ps1 -ValidateOnly
```

---

## Logging and Issue Tracking

### Standardized Logging
```powershell
# Use Write-CustomLog for all operations
Import-Module "/pwsh/modules/LabRunner/" -Force

# Log maintenance operations
Write-CustomLog "Starting maintenance operation: $OperationType" "INFO"
Write-CustomLog "Processing files: $($Files.Count)" "INFO"

# Log validation results
Write-CustomLog "Validation completed: $PassedTests passed, $FailedTests failed" "INFO"

# Log errors with context
Write-CustomLog "Operation failed: $($_.Exception.Message)" "ERROR"
Write-CustomLog "Context: File=$CurrentFile, Line=$LineNumber" "DEBUG"
```

---

## Integration with CI/CD

### Continuous Integration Hooks
```powershell
# For GitHub Actions integration
function Invoke-CIValidation {…}
```

---

*This document serves as the single source of truth for all project guidelines.*

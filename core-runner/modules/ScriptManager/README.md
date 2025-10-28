# ScriptManager Module

Module for managing one-off scripts and script templates in OpenTofu Lab Automation.

## Overview

The ScriptManager module provides functionality for registering, testing, and executing one-off scripts. It helps manage temporary or single-use automation scripts while maintaining proper logging and error handling.

## Features

- **Script registration** - Register one-off scripts for execution
- **Script validation** - Test scripts before execution
- **Script execution** - Run registered scripts with proper error handling
- **Script templates** - Reusable script patterns
- **Cross-platform** - Works on Windows, Linux, and macOS
- **Logging integration** - Uses centralized logging

## Installation

```powershell
Import-Module "./core-runner/modules/ScriptManager" -Force
```

## Functions

### Register-OneOffScript

Registers a one-off script for execution.

```powershell
# Register a simple script
Register-OneOffScript -Name "Quick-Cleanup" -ScriptBlock {
    Write-Host "Cleaning up temporary files..."
    Remove-Item "./temp/*" -Force -Recurse
}

# Register with parameters
Register-OneOffScript -Name "Database-Backup" -ScriptBlock {
    param($Database, $BackupPath)
    Write-Host "Backing up $Database to $BackupPath"
    # Backup logic
} -Parameters @{
    Database = "LabDB"
    BackupPath = "./backups"
}

# Register from file
Register-OneOffScript -Name "Import-Data" -ScriptPath "./scripts/import-data.ps1"
```

**Parameters:**
- **Name** (Required): Unique name for the script
- **ScriptBlock**: Script code to execute
- **ScriptPath**: Path to script file
- **Parameters**: Hashtable of parameters to pass to script
- **Description**: Optional description

### Test-OneOffScript

Tests a registered script without executing it.

```powershell
# Test script registration
$isValid = Test-OneOffScript -Name "Quick-Cleanup"

if ($isValid) {
    Write-Host "Script is valid and ready to run" -ForegroundColor Green
} else {
    Write-Warning "Script has validation issues"
}

# Test with detailed output
Test-OneOffScript -Name "Database-Backup" -Verbose

# Test all registered scripts
$scripts = Get-RegisteredScripts
foreach ($script in $scripts) {
    Test-OneOffScript -Name $script.Name
}
```

**Validates:**
- Script exists in registry
- ScriptBlock or ScriptPath is valid
- Required parameters are defined
- Script syntax (if ScriptPath)

### Invoke-OneOffScript

Executes a registered one-off script.

```powershell
# Execute script
Invoke-OneOffScript -Name "Quick-Cleanup"

# Execute with custom parameters
Invoke-OneOffScript -Name "Database-Backup" -Parameters @{
    Database = "ProductionDB"
    BackupPath = "C:/Backups/Production"
}

# Execute with error handling
try {
    Invoke-OneOffScript -Name "Import-Data"
    Write-Host "Script completed successfully" -ForegroundColor Green
} catch {
    Write-Error "Script failed: $($_.Exception.Message)"
}

# Execute in WhatIf mode
Invoke-OneOffScript -Name "Database-Backup" -WhatIf
```

## Usage Examples

### Simple One-Off Task

```powershell
# Import module
Import-Module "./core-runner/modules/ScriptManager" -Force

# Register quick cleanup task
Register-OneOffScript -Name "Clean-Logs" -ScriptBlock {
    Write-Host "Cleaning old log files..." -ForegroundColor Cyan
    
    $logDir = "./logs"
    $cutoffDate = (Get-Date).AddDays(-30)
    
    Get-ChildItem $logDir -Filter "*.log" | Where-Object {
        $_.LastWriteTime -lt $cutoffDate
    } | Remove-Item -Force
    
    Write-Host "Cleanup complete" -ForegroundColor Green
}

# Test and execute
if (Test-OneOffScript -Name "Clean-Logs") {
    Invoke-OneOffScript -Name "Clean-Logs"
}
```

### Parameterized Script

```powershell
# Register script with parameters
Register-OneOffScript -Name "Export-Report" -ScriptBlock {
    param(
        [string]$ReportType,
        [string]$OutputPath,
        [datetime]$StartDate,
        [datetime]$EndDate
    )
    
    Write-Host "Generating $ReportType report..." -ForegroundColor Cyan
    Write-Host "  Date range: $StartDate to $EndDate"
    Write-Host "  Output: $OutputPath"
    
    # Report generation logic
    $data = Get-ReportData -Type $ReportType -Start $StartDate -End $EndDate
    $data | Export-Csv -Path $OutputPath -NoTypeInformation
    
    Write-Host "Report generated successfully" -ForegroundColor Green
}

# Execute with parameters
Invoke-OneOffScript -Name "Export-Report" -Parameters @{
    ReportType = "Usage"
    OutputPath = "./reports/usage-$(Get-Date -Format 'yyyy-MM-dd').csv"
    StartDate = (Get-Date).AddDays(-7)
    EndDate = Get-Date
}
```

### Script from File

```powershell
# Create script file
@'
param($ServerName, $Port)

Write-Host "Testing connection to $ServerName`:$Port"

try {
    $connection = Test-NetConnection -ComputerName $ServerName -Port $Port
    
    if ($connection.TcpTestSucceeded) {
        Write-Host "Connection successful" -ForegroundColor Green
    } else {
        Write-Warning "Connection failed"
    }
} catch {
    Write-Error "Error testing connection: $($_.Exception.Message)"
}
'@ | Set-Content "./scripts/test-connection.ps1"

# Register and execute
Register-OneOffScript -Name "Test-Connection" -ScriptPath "./scripts/test-connection.ps1"

Invoke-OneOffScript -Name "Test-Connection" -Parameters @{
    ServerName = "example.com"
    Port = 443
}
```

### Multiple Script Management

```powershell
# Register multiple maintenance scripts
$maintenanceScripts = @{
    "Clean-TempFiles" = {
        Remove-Item "$env:TEMP/*" -Force -Recurse -ErrorAction SilentlyContinue
    }
    "Update-GitRepos" = {
        Get-ChildItem "C:/Projects" -Directory | ForEach-Object {
            Push-Location $_.FullName
            if (Test-Path ".git") {
                Write-Host "Updating $($_.Name)..."
                git pull
            }
            Pop-Location
        }
    }
    "Compress-OldLogs" = {
        Get-ChildItem "./logs" -Filter "*.log" | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-7)
        } | ForEach-Object {
            Compress-Archive -Path $_.FullName -DestinationPath "$($_.FullName).zip"
            Remove-Item $_.FullName
        }
    }
}

# Register all scripts
foreach ($scriptName in $maintenanceScripts.Keys) {
    Register-OneOffScript -Name $scriptName -ScriptBlock $maintenanceScripts[$scriptName]
}

# Execute all scripts
foreach ($scriptName in $maintenanceScripts.Keys) {
    Write-Host "`nExecuting: $scriptName" -ForegroundColor Cyan
    Invoke-OneOffScript -Name $scriptName
}
```

## Script Templates

### Template: Data Processing

```powershell
Register-OneOffScript -Name "Process-Data" -ScriptBlock {
    param($InputPath, $OutputPath, $ProcessingFunction)
    
    # Load data
    Write-Host "Loading data from $InputPath..."
    $data = Import-Csv $InputPath
    
    # Process data
    Write-Host "Processing $($data.Count) records..."
    $processed = $data | ForEach-Object {
        & $ProcessingFunction $_
    }
    
    # Save results
    Write-Host "Saving results to $OutputPath..."
    $processed | Export-Csv $OutputPath -NoTypeInformation
    
    Write-Host "Processing complete" -ForegroundColor Green
}
```

### Template: System Check

```powershell
Register-OneOffScript -Name "System-Check" -ScriptBlock {
    Write-Host "Running system checks..." -ForegroundColor Cyan
    
    # Check disk space
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $freePercent = ($drive.Free / $drive.Used) * 100
        $status = if ($freePercent -gt 20) { "OK" } else { "LOW" }
        Write-Host "  Drive $($drive.Name): $([math]::Round($freePercent, 2))% free - $status"
    }
    
    # Check services
    $criticalServices = @("LabService", "DatabaseService")
    foreach ($service in $criticalServices) {
        $svc = Get-Service $service -ErrorAction SilentlyContinue
        if ($svc) {
            $status = if ($svc.Status -eq "Running") { "Running" } else { "STOPPED" }
            Write-Host "  Service $service: $status"
        }
    }
    
    Write-Host "System check complete" -ForegroundColor Green
}
```

## Integration with Other Modules

### With Logging Module

```powershell
Import-Module "./core-runner/modules/Logging" -Force
Import-Module "./core-runner/modules/ScriptManager" -Force

Register-OneOffScript -Name "Logged-Task" -ScriptBlock {
    Write-CustomLog -Level 'INFO' -Message 'Starting task'
    
    try {
        # Task logic
        Write-CustomLog -Level 'SUCCESS' -Message 'Task completed'
    } catch {
        Write-CustomLog -Level 'ERROR' -Message "Task failed: $($_.Exception.Message)"
        throw
    }
}
```

### With PatchManager Module

```powershell
# Use ScriptManager for one-off patches
Register-OneOffScript -Name "Apply-HotFix" -ScriptBlock {
    Import-Module "./core-runner/modules/PatchManager" -Force
    
    Invoke-PatchWorkflow -PatchDescription "Apply hot-fix" -PatchOperation {
        # Fix logic
    } -CreatePR
}
```

## Best Practices

1. **Use descriptive names** for scripts to identify their purpose
2. **Test scripts** before execution with Test-OneOffScript
3. **Include parameters** for flexibility
4. **Add error handling** in script blocks
5. **Use logging** for traceability
6. **Clean up** registered scripts when no longer needed
7. **Document scripts** with descriptions

## Error Handling

```powershell
# Robust script execution
Register-OneOffScript -Name "Robust-Task" -ScriptBlock {
    param($InputFile)
    
    try {
        # Validate input
        if (-not (Test-Path $InputFile)) {
            throw "Input file not found: $InputFile"
        }
        
        # Main logic
        $data = Import-Csv $InputFile
        # Process data...
        
        Write-Host "Task completed successfully" -ForegroundColor Green
    } catch {
        Write-Error "Task failed: $($_.Exception.Message)"
        # Cleanup or rollback
        throw
    } finally {
        # Always clean up
        Write-Host "Cleaning up resources..."
    }
}
```

## Troubleshooting

### Script not found
- Verify script was registered: Check registration
- Ensure correct script name (case-sensitive)
- Re-register if needed

### Script fails on execution
- Test script first with Test-OneOffScript
- Check parameters are correct
- Review error messages
- Add verbose output for debugging

### Parameters not working
- Verify parameter names match
- Check parameter types
- Use -Verbose with Test-OneOffScript

## Version History

- **1.0.0**: Initial release with script registration and execution

## Related Modules

- [Logging](../Logging/) - Used for script execution logging
- [LabRunner](../LabRunner/) - Lab automation script execution
- [PatchManager](../PatchManager/) - Code patching workflows

## Contributing

When adding ScriptManager features:

1. Maintain simple, focused interface
2. Include parameter validation
3. Support both script blocks and file paths
4. Test with various script types
5. Update this README with new functionality

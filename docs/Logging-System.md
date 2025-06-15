# OpenTofu Lab Automation Logging System

This document outlines the centralized logging system for the OpenTofu Lab Automation project, explaining how to use it consistently across all project components.

## Overview

The project uses a centralized logging module at `/pwsh/modules/Logging/Logger.ps1` which provides consistent formatting, error handling, and output options across all project scripts and modules.

## Key Features

- **Consistent formatting** across all project outputs
- **Multi-destination logging** (console and file)
- **Verbosity control** for different environments
- **Color-coding** by log level
- **Timestamp standardization**
- **Fallback mechanisms** when module can't be loaded

## How to Use the Logger

### 1. Import the Module

Always start your script by importing the logging module:

```powershell
# Import centralized logging module
try {
    Import-Module "/pwsh/modules/Logging" -ErrorAction Stop
} catch {
    try {
        Import-Module "/pwsh/modules/LabRunner/" -ErrorAction Stop
    } catch {
        # Fallback implementation if module import fails
        function Write-CustomLog {
            param([string]$Message, [string]$Level = "INFO")
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $color = switch ($Level) {
                "INFO" { "Cyan" }
                "SUCCESS" { "Green" }
                "WARNING" { "Yellow" }
                "ERROR" { "Red" }
                default { "White" }
            }
            Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
        }
    }
}
```

### 2. Log Messages

Use the `Write-CustomLog` function for all logging:

```powershell
# Basic usage
Write-CustomLog "Starting process" "INFO"

# Log levels
Write-CustomLog "Operation successful" "SUCCESS"
Write-CustomLog "Missing configuration file" "WARN"
Write-CustomLog "Failed to connect to server" "ERROR"
Write-CustomLog "Detailed variable state: $var" "DEBUG"

# Advanced usage with options
Write-CustomLog "Hidden from file" "INFO" -NoFileOutput
Write-CustomLog "Only to file" "DEBUG" -NoConsole
Write-CustomLog "Custom log location" "INFO" -LogFile "./logs/special.log"
```

### 3. User Input

Use `Read-LoggedInput` for capturing user input with logging:

```powershell
$name = Read-LoggedInput "Enter your name"
$password = Read-LoggedInput "Enter password" -AsSecureString
```

### 4. Configure Logging

```powershell
# Set log file location
Set-LoggingPath -LogFilePath "/logs/custom-path.log" -CreateDirectory

# Set verbosity level
Set-LogVerbosity -Level "Verbose"  # Options: Quiet, Normal, Verbose, Debug
```

### 5. Log Management

```powershell
# Merge logs from different sources
Merge-LogFiles -LogFiles @("./log1.log", "./log2.log") -OutputFile "./combined.log" -SortByTimestamp
```

## Log Levels

| Level | Color | Use Case |
|-------|-------|----------|
| INFO | Cyan | General information |
| WARN | Yellow | Potential issues that don't stop execution |
| ERROR | Red | Error conditions that affect operation |
| DEBUG | Gray | Detailed debugging information |
| SUCCESS | Green | Successful operations |
| CRITICAL | Red | Critical failures requiring immediate attention |

## Best Practices

1. **Always use the centralized logger** instead of `Write-Host` directly
2. **Import properly** at the top of your scripts
3. **Use appropriate log levels** for different message types
4. **Include context** in error messages to make debugging easier
5. **Set verbosity appropriately** based on execution environment
6. **Handle sensitive information** properly by using `-AsSecureString` flag

## Standardization Script

To standardize logging across existing scripts, use the `Standardize-LoggingAcrossProject.ps1` script:

```powershell
# Check what would be changed without making changes
./scripts/maintenance/Standardize-LoggingAcrossProject.ps1 -DryRun

# Apply changes across all scripts
./scripts/maintenance/Standardize-LoggingAcrossProject.ps1 -BackupFiles

# Force reprocessing of all files
./scripts/maintenance/Standardize-LoggingAcrossProject.ps1 -Force -BackupFiles
```

## Troubleshooting

- If log files aren't being created, check permissions on the log directory
- If colors aren't displaying correctly, ensure the terminal supports ANSI colors
- If the module can't be imported, the script will use a fallback implementation

---

For more information, see the module source code at `/pwsh/modules/Logging/Logger.ps1`

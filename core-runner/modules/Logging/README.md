# Logging Module

Enterprise-grade centralized logging system for OpenTofu Lab Automation with full tracing, performance monitoring, and debugging capabilities.

## Features

- **Multiple log levels** with filtering (SILENT, ERROR, WARN, INFO, SUCCESS, DEBUG, TRACE, VERBOSE)
- **Structured logging** with context support
- **File and console output** with independent level control
- **Performance tracking** with start/stop trace functions
- **Call stack tracing** for debugging
- **Module/function context** automatic detection
- **Configurable output formats** (Simple, Structured, JSON)
- **Log rotation and archiving** with configurable size limits
- **Thread-safe operations** for concurrent use
- **Cross-platform compatibility** (Windows, Linux, macOS)

## Installation

The Logging module is automatically available in the OpenTofu Lab Automation project:

```powershell
Import-Module './core-runner/modules/Logging' -Force
```

## Basic Usage

### Initialize Logging System

```powershell
# Initialize with defaults
Initialize-LoggingSystem

# Custom configuration
Initialize-LoggingSystem -LogPath "./logs/app.log" -LogLevel "DEBUG" -EnableTrace -EnablePerformance
```

### Write Log Messages

```powershell
# Simple logging
Write-CustomLog "Application started" -Level INFO
Write-CustomLog "Configuration loaded successfully" -Level SUCCESS
Write-CustomLog "Potential issue detected" -Level WARN
Write-CustomLog "Operation failed" -Level ERROR

# Logging with context
Write-CustomLog "Database connection established" -Level INFO -Context @{
    Server = "localhost"
    Database = "automation"
    ConnectionTime = "150ms"
}
```

### Performance Tracking

```powershell
# Track operation performance
Start-PerformanceTrace -Name "DataProcessing"
# ... perform operation ...
Stop-PerformanceTrace -Name "DataProcessing"
```

### Debug Tracing

```powershell
# Enable trace logging
Set-LoggingConfiguration -EnableTrace

# Write trace messages
Write-TraceLog "Entering critical section" -Context @{ Variable = $value }

# Debug with variable context
Write-DebugContext "Current state" -Variables @{
    Counter = $counter
    Status = $status
}
```

## Configuration

### Environment Variables

- `LAB_LOG_LEVEL` - File log level (default: INFO)
- `LAB_CONSOLE_LEVEL` - Console log level (default: INFO)
- `LAB_LOG_PATH` - Log file path
- `LAB_MAX_LOG_SIZE_MB` - Maximum log file size (default: 50 MB)
- `LAB_MAX_LOG_FILES` - Number of rotated logs to keep (default: 10)
- `LAB_ENABLE_TRACE` - Enable trace logging (default: false)
- `LAB_ENABLE_PERFORMANCE` - Enable performance tracking (default: false)
- `LAB_LOG_FORMAT` - Output format: Simple, Structured, JSON (default: Structured)

### Runtime Configuration

```powershell
# Get current configuration
$config = Get-LoggingConfiguration

# Update configuration
Set-LoggingConfiguration -LogLevel "DEBUG" -EnableTrace
```

## Exported Functions

- `Write-CustomLog` - Main logging function with level support
- `Initialize-LoggingSystem` - Initialize logging with configuration
- `Start-PerformanceTrace` - Begin performance tracking
- `Stop-PerformanceTrace` - End performance tracking and log results
- `Write-TraceLog` - Write trace-level messages with context
- `Write-DebugContext` - Write debug information with variables
- `Get-LoggingConfiguration` - Retrieve current configuration
- `Set-LoggingConfiguration` - Update logging settings

## Log Levels

Hierarchy from least to most verbose:

1. **SILENT** - No output
2. **ERROR** - Critical errors only
3. **WARN** - Warnings and errors
4. **INFO** - Informational messages, warnings, and errors
5. **SUCCESS** - Success messages (same priority as INFO)
6. **DEBUG** - Debugging information
7. **TRACE** - Detailed trace information
8. **VERBOSE** - Maximum verbosity

## Best Practices

1. **Always initialize** the logging system at application startup
2. **Use appropriate levels** - don't log everything at ERROR level
3. **Include context** for important operations to aid troubleshooting
4. **Use performance tracing** for operations that may be slow
5. **Enable trace logging** only when debugging specific issues
6. **Configure log rotation** to prevent disk space issues

## Examples

### Application Startup

```powershell
Import-Module './core-runner/modules/Logging' -Force
Initialize-LoggingSystem -LogPath "./logs/automation.log" -LogLevel "INFO"
Write-CustomLog "OpenTofu Lab Automation started" -Level SUCCESS
```

### Error Handling

```powershell
try {
    # Operation
    Invoke-SomeOperation
    Write-CustomLog "Operation completed successfully" -Level SUCCESS
} catch {
    Write-CustomLog "Operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
}
```

### Performance Monitoring

```powershell
Start-PerformanceTrace -Name "ConfigLoad" -Context @{ ConfigFile = $configPath }
$config = Get-Content $configPath | ConvertFrom-Json
Stop-PerformanceTrace -Name "ConfigLoad" -AdditionalContext @{ ItemCount = $config.Count }
```

## Thread Safety

All logging operations are thread-safe and can be used in parallel execution scenarios without additional synchronization.

## Version

Current Version: 2.0.0

## License

Copyright (c) 2025 Wizzense. All rights reserved.

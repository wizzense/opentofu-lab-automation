# Logging Module

Enterprise-grade centralized logging system for OpenTofu Lab Automation with full tracing, performance monitoring, and debugging capabilities.

## Overview

The Logging module provides comprehensive logging functionality that integrates across all modules and scripts in the project. It supports multiple log levels, performance tracing, debugging context, and configurable output formats.

## Features

- **Multi-level logging** - DEBUG, INFO, SUCCESS, WARN, ERROR levels
- **Performance tracing** - Track execution time of operations
- **Debug context** - Capture detailed context for troubleshooting
- **Cross-platform** - Works on Windows, Linux, and macOS
- **Configurable output** - Control verbosity and log destinations
- **Thread-safe** - Safe for parallel execution scenarios

## Installation

The module is automatically available when you import it:

```powershell
Import-Module "./core-runner/modules/Logging" -Force
```

## Functions

### Write-CustomLog

Main logging function used throughout the project.

```powershell
# Basic logging
Write-CustomLog -Level 'INFO' -Message 'Operation started'

# Success message
Write-CustomLog -Level 'SUCCESS' -Message 'Operation completed successfully'

# Warning
Write-CustomLog -Level 'WARN' -Message 'Resource not found, using default'

# Error with context
Write-CustomLog -Level 'ERROR' -Message "Failed to process: $($_.Exception.Message)"

# Debug information
Write-CustomLog -Level 'DEBUG' -Message 'Variable state: $variableName = $value'
```

**Log Levels:**
- **DEBUG**: Detailed diagnostic information
- **INFO**: General informational messages
- **SUCCESS**: Successful operation completion
- **WARN**: Warning messages that don't stop execution
- **ERROR**: Error messages for failures

### Initialize-LoggingSystem

Initializes the logging system with configuration.

```powershell
# Initialize with default settings
Initialize-LoggingSystem

# Initialize with custom log directory
Initialize-LoggingSystem -LogDirectory "./custom-logs"

# Initialize with specific verbosity
Initialize-LoggingSystem -Verbosity "detailed"
```

**Verbosity Levels:**
- **silent**: Only ERROR messages
- **normal**: WARN and ERROR messages
- **detailed**: All messages including DEBUG

### Start-PerformanceTrace

Starts tracking execution time for an operation.

```powershell
# Start tracing an operation
$traceId = Start-PerformanceTrace -OperationName "DataProcessing"

# ... perform operation ...

# Stop and log results
Stop-PerformanceTrace -TraceId $traceId
```

### Stop-PerformanceTrace

Stops performance tracing and logs the duration.

```powershell
# Stop with trace ID
Stop-PerformanceTrace -TraceId $traceId

# Logs: "Performance: DataProcessing completed in 1.234 seconds"
```

### Write-TraceLog

Writes a trace-level log message (more detailed than DEBUG).

```powershell
# Trace level logging for very detailed diagnostics
Write-TraceLog -Message "Entering function with parameters: $params"
```

### Write-DebugContext

Captures and logs detailed context for debugging.

```powershell
# Log current context for troubleshooting
Write-DebugContext -Context @{
    Function = $MyInvocation.MyCommand.Name
    Parameters = $PSBoundParameters
    Variables = (Get-Variable).Count
}
```

### Get-LoggingConfiguration

Retrieves current logging configuration.

```powershell
# Get current settings
$config = Get-LoggingConfiguration

# Display settings
$config | Format-List
```

### Set-LoggingConfiguration

Updates logging configuration at runtime.

```powershell
# Change verbosity level
Set-LoggingConfiguration -Verbosity "detailed"

# Change log directory
Set-LoggingConfiguration -LogDirectory "./new-logs"

# Update multiple settings
Set-LoggingConfiguration -Verbosity "normal" -LogDirectory "./logs" -EnableTracing $true
```

## Usage Examples

### Basic Logging Pattern

```powershell
# Import module
Import-Module "./core-runner/modules/Logging" -Force

# Initialize
Initialize-LoggingSystem

# Log throughout your script
try {
    Write-CustomLog -Level 'INFO' -Message "Starting data import"
    
    # ... perform operations ...
    
    Write-CustomLog -Level 'SUCCESS' -Message "Data import completed"
} catch {
    Write-CustomLog -Level 'ERROR' -Message "Data import failed: $($_.Exception.Message)"
    throw
}
```

### Performance Tracing

```powershell
# Start trace
$traceId = Start-PerformanceTrace -OperationName "DatabaseQuery"

try {
    # ... perform database query ...
    
    Write-CustomLog -Level 'SUCCESS' -Message "Query returned $resultCount rows"
} finally {
    # Always stop trace
    Stop-PerformanceTrace -TraceId $traceId
}
```

### Debugging with Context

```powershell
# Capture context when issues occur
try {
    # ... complex operation ...
} catch {
    Write-DebugContext -Context @{
        Operation = "DataTransformation"
        InputFile = $inputPath
        ErrorMessage = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
    }
    
    Write-CustomLog -Level 'ERROR' -Message "Operation failed - see debug context"
    throw
}
```

### Integration with Core Runner

The Logging module integrates with the core runner's verbosity settings:

```powershell
# Silent mode (only errors)
./core-runner.ps1 -Verbosity silent

# Normal mode (warnings and errors)
./core-runner.ps1 -Verbosity normal

# Detailed mode (all log levels)
./core-runner.ps1 -Verbosity detailed
```

## Log File Locations

Logs are written to:

- **Default location**: `./logs/`
- **File naming**: `automation-{date}.log`
- **Rotation**: New log file created daily

## Configuration

The module uses these default settings:

- **Verbosity**: `normal`
- **Log directory**: `./logs/`
- **Performance tracing**: Enabled
- **Debug context**: Enabled in detailed mode

## Cross-Platform Compatibility

The module handles platform-specific differences:

```powershell
# Automatic path handling
$logPath = Join-Path $LogDirectory "automation.log"  # Works on all platforms

# Platform detection (from LabRunner module)
$platform = Get-Platform  # Returns: Windows, Linux, or macOS
```

## Error Handling

All functions include comprehensive error handling:

- Try-catch blocks for all operations
- Graceful fallback for missing log directories
- Automatic directory creation
- Thread-safe file writing

## Best Practices

1. **Always initialize** the logging system at script start
2. **Use appropriate levels** - DEBUG for diagnostics, INFO for progress, SUCCESS for completions
3. **Include context** in error messages to aid troubleshooting
4. **Use performance tracing** for operations that may be slow
5. **Clean up traces** with try-finally blocks
6. **Consistent messaging** across similar operations

## Integration with Other Modules

The Logging module is used by all other modules:

```powershell
# LabRunner uses Logging
Import-Module "./core-runner/modules/LabRunner" -Force  # Automatically uses Logging

# PatchManager uses Logging
Import-Module "./core-runner/modules/PatchManager" -Force  # Automatically uses Logging

# All modules coordinate through centralized logging
```

## Troubleshooting

### Logs not appearing
- Check verbosity level: `Get-LoggingConfiguration`
- Verify log directory exists and is writable
- Ensure `Initialize-LoggingSystem` was called

### Too much log output
- Set verbosity to 'normal': `Set-LoggingConfiguration -Verbosity normal`
- Use 'silent' mode for automation: `-Verbosity silent`

### Performance tracing not working
- Ensure trace ID is stored: `$traceId = Start-PerformanceTrace ...`
- Always call `Stop-PerformanceTrace` with the same trace ID
- Use try-finally to ensure cleanup

## Version History

- **2.0.0**: Enterprise-grade logging with tracing and debugging capabilities
- **1.0.0**: Initial release with basic logging functionality

## Related Modules

- [LabRunner](../LabRunner/) - Uses Logging for all operations
- [PatchManager](../PatchManager/) - Uses Logging for git operations
- [TestingFramework](../TestingFramework/) - Uses Logging for test execution
- [UnifiedMaintenance](../UnifiedMaintenance/) - Uses Logging for maintenance tasks

## Contributing

When adding new logging features:

1. Maintain backward compatibility with existing log levels
2. Follow thread-safe patterns for file operations
3. Include comprehensive help documentation
4. Test with all verbosity levels
5. Update this README with new functionality

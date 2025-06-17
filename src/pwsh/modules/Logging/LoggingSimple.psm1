#Requires -Version 7.0

function Write-CustomLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("ERROR", "WARN", "INFO", "SUCCESS", "DEBUG", "TRACE", "VERBOSE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        "DEBUG" { "DarkGray" }
        "TRACE" { "Magenta" }
        "VERBOSE" { "DarkCyan" }
        default { "White" }
    }
    
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $color
    
    # Also write to file
    $logFile = Join-Path $env:TEMP "opentofu-lab-automation.log"
    try {
        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Ignore file logging errors
    }
}

Export-ModuleMember -Function Write-CustomLog

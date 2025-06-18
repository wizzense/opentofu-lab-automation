#Requires -Version 7.0

<#
.SYNOPSIS
    Writes a custom log message with a specified level.
    
.DESCRIPTION
    Provides standardized logging across the application with color-coded output based on log level.
    
.PARAMETER Message
    The message to log.
    
.PARAMETER Level
    The level of the log (INFO, WARN, ERROR, SUCCESS, DEBUG).
    
.PARAMETER Component
    The component generating the log message.
    
.EXAMPLE
    Write-CustomLog -Message "Operation completed" -Level "SUCCESS"
    
.EXAMPLE
    Write-CustomLog -Message "Connection failed" -Level "ERROR" -Component "Network"
#>
function Write-CustomLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO",
        
        [Parameter()]
        [string]$Component = "CoreApp"
    )
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Green" }
        "SUCCESS" { "Cyan" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    
    Write-Host "[$Level] [$Component] $Message" -ForegroundColor $color
}

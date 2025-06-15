function Write-PatchLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG", "STEP", "MAINTENANCE")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Level] $Message"
    
    # Color coding based on level
    if (-not $NoConsole) {
        $color = switch ($Level) {
            "INFO"        { "Gray" }
            "SUCCESS"     { "Green" }
            "WARNING"     { "Yellow" }
            "ERROR"       { "Red" }
            "DEBUG"       { "DarkGray" }
            "STEP"        { "Cyan" }
            "MAINTENANCE" { "Magenta" }
            default       { "White" }
        }
        
        Write-Host $formattedMessage -ForegroundColor $color
    }
    
    # Write to log file if specified
    if ($LogFile) {
        $formattedMessage | Out-File -FilePath $LogFile -Append -Encoding utf8
    }
}

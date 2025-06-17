Param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigPath
)

$ErrorActionPreference = "Stop"

# Import necessary modules using environment variables
Import-Module "LabRunner" -Force
# LabRunner deprecated - functionality moved to other modules

# Load configuration
if (-Not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found at $ConfigPath"
    exit 1
}

$config = Get-Content $ConfigPath | ConvertFrom-Json

Write-Host "Starting core application: $($config.ApplicationName)"

try {
    # Example operation
    Invoke-LabStep -Config $config -Body {
        Write-CustomLog "Core application operation started." "INFO"
        # Add core application logic here
        Write-CustomLog "Core application operation completed successfully." "INFO"
    }
} catch {
    Write-CustomLog "Core application operation failed: $($_.Exception.Message)" "ERROR"
    throw
}

#Requires -Version 7.0

<#
.SYNOPSIS
    Gets the configuration for the OpenTofu Lab Automation core application.
    
.DESCRIPTION
    Loads and returns the JSON configuration from the specified path or the default configuration.
    
.PARAMETER ConfigPath
    Path to the configuration file (JSON format). If not provided, uses the default config.
    
.EXAMPLE
    Get-CoreConfiguration
    
.EXAMPLE
    Get-CoreConfiguration -ConfigPath "./configs/custom-config.json"
#>
function Get-CoreConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = (Join-Path $PSScriptRoot "../default-config.json")
    )
    
    process {
        try {
            if (Test-Path $ConfigPath) {
                return Get-Content $ConfigPath | ConvertFrom-Json
            } else {
                throw "Configuration file not found: $ConfigPath"
            }
        } catch {
            Write-CustomLog -Message "Failed to load configuration: $($_.Exception.Message)" -Level "ERROR"
            throw
        }
    }
}

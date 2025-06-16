#Requires -Version 7.0

<#
.SYNOPSIS
    DevEnvironment module for OpenTofu Lab Automation

.DESCRIPTION
    Provides functions for setting up and managing the development environment,
    including Git hooks, development tools, and workspace configuration.

.NOTES
    This module integrates development environment setup into the core project workflow.
#>

# Import the centralized Logging module
$loggingModulePath = $null
if ($env:PWSH_MODULES_PATH -and (Test-Path $env:PWSH_MODULES_PATH)) {
    $loggingModulePath = Join-Path $env:PWSH_MODULES_PATH "Logging"
}
if (-not $loggingModulePath -or -not (Test-Path $loggingModulePath)) {
    $loggingModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "Logging"
}
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -Force -Global
    Write-Verbose "Successfully imported centralized Logging module"
} else {
    Write-Warning "Could not find centralized Logging module at $loggingModulePath"
    # Fallback logging function
    function Write-CustomLog {
        param($Message, $Level = "INFO")
        $color = switch ($Level) {
            "SUCCESS" { "Green" }
            "WARN" { "Yellow" } 
            "ERROR" { "Red" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Import public functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
        Write-Verbose "Imported function: $($import.BaseName)"
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $($_.Exception.Message)"
    }
}

# Export only the public functions
if ($Public.Count -gt 0) {
    $functionNames = $Public.BaseName
    Export-ModuleMember -Function $functionNames
    Write-Verbose "Exported DevEnvironment functions: $($functionNames -join ', ')"
} else {
    Write-Warning "No public functions found to export in $PSScriptRoot\Public\"
}

#Requires -Version 7.0

<#
.SYNOPSIS
    Direct test of Logging module functionality
#>

# Import the Logging module with specific path
$LoggingPath = Join-Path $PSScriptRoot "pwsh\modules\Logging"
Import-Module $LoggingPath -Force -Verbose

Write-Host "Testing Module Import" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# Check what was imported
Write-Host "`nChecking imported commands:" -ForegroundColor Yellow
$commands = Get-Command -Module Logging
if ($commands) {
    foreach ($cmd in $commands) {
        Write-Host "  $($cmd.Name) ($($cmd.CommandType))" -ForegroundColor Green
    }
} else {
    Write-Host "  No commands found from Logging module" -ForegroundColor Red
}

# Check all available Write-CustomLog commands
Write-Host "`nAll Write-CustomLog commands available:" -ForegroundColor Yellow
$allWriteCustomLog = Get-Command Write-CustomLog -All -ErrorAction SilentlyContinue
if ($allWriteCustomLog) {
    foreach ($cmd in $allWriteCustomLog) {
        Write-Host "  Source: $($cmd.Source), Version: $($cmd.Version)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No Write-CustomLog commands found" -ForegroundColor Red
}

# Try to call the function directly from the module
Write-Host "`nTesting direct module function call:" -ForegroundColor Yellow
try {
    $LoggingModule = Get-Module Logging
    if ($LoggingModule) {
        Write-Host "  Logging module is loaded" -ForegroundColor Green
        Write-Host "  Exported functions: $($LoggingModule.ExportedFunctions.Keys -join ', ')" -ForegroundColor Gray
        
        # Try calling the function using module prefix
        & (Get-Module Logging) { Write-CustomLog "Test message from module scope" -Level SUCCESS }
    } else {
        Write-Host "  Logging module not found in loaded modules" -ForegroundColor Red
    }
}
catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nModule test completed" -ForegroundColor Green

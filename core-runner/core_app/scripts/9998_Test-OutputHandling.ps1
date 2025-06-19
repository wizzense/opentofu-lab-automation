#Requires -Version 7.0
param([object]$Config)

Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force

Write-CustomLog "Starting test script with various output types" -Level INFO

Write-Host "This is a Write-Host message from the script" -ForegroundColor Green
Write-Output "This is Write-Output from the script"
Write-Warning "This is a warning from the script"
Write-Verbose "This is verbose output from the script" -Verbose

# Test error handling
try {
    Write-Error "This is a non-terminating error" -ErrorAction Continue
} catch {
    Write-CustomLog "Caught error: $($_.Exception.Message)" -Level ERROR
}

# Test some operations
$date = Get-Date
Write-Host "Current date and time: $date"

# Test pipeline output
1..3 | ForEach-Object { "Item $_" }

Write-CustomLog "Test script completed successfully" -Level SUCCESS

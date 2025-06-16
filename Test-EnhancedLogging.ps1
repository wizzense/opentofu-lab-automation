#Requires -Version 7.0

<#
.SYNOPSIS
    Simple test of the enhanced centralized logging system
#>

# Import only the Logging module
Import-Module "$PSScriptRoot\pwsh\modules\Logging\" -Force

Write-Host "Testing Enhanced Logging System" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test basic logging
Write-Host "`nTesting basic logging levels:" -ForegroundColor Yellow
Write-CustomLog "This is an INFO message" -Level INFO
Write-CustomLog "This is a SUCCESS message" -Level SUCCESS
Write-CustomLog "This is a WARNING message" -Level WARN
Write-CustomLog "This is an ERROR message" -Level ERROR
Write-CustomLog "This is a DEBUG message" -Level DEBUG

# Test logging with context
Write-Host "`nTesting logging with context:" -ForegroundColor Yellow
Write-CustomLog "This message has context" -Level INFO -Context @{
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
    TestNumber = 123
}

# Test performance tracing
Write-Host "`nTesting performance tracing:" -ForegroundColor Yellow
Start-PerformanceTrace -OperationName "TestOperation"
Start-Sleep -Milliseconds 500
Stop-PerformanceTrace -OperationName "TestOperation"

# Test trace logging
Write-Host "`nTesting trace logging:" -ForegroundColor Yellow
Set-LoggingConfiguration -EnableTrace
Write-TraceLog "This is a trace message" -Context @{ TraceTest = $true }

# Test debug context
Write-Host "`nTesting debug context:" -ForegroundColor Yellow
$testVar = "TestValue"
$counter = 42
Write-DebugContext "Debug message with variables" -Variables @{
    TestVar = $testVar
    Counter = $counter
}

# Show configuration
Write-Host "`nCurrent logging configuration:" -ForegroundColor Yellow
$config = Get-LoggingConfiguration
foreach ($key in $config.Keys) {
    Write-Host "  $key = $($config[$key])" -ForegroundColor Gray
}

# Show log file info
Write-Host "`nLog file information:" -ForegroundColor Yellow
$logFile = $config.LogFilePath
Write-Host "  Location: $logFile" -ForegroundColor Gray
if (Test-Path $logFile) {
    $logInfo = Get-Item $logFile
    Write-Host "  Size: $([math]::Round($logInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
    Write-Host "  Last Modified: $($logInfo.LastWriteTime)" -ForegroundColor Gray
    
    Write-Host "`nLast 10 lines from log file:" -ForegroundColor Yellow
    Get-Content $logFile -Tail 10 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  Log file not created yet" -ForegroundColor Gray
}

Write-Host "`nEnhanced logging system test completed successfully!" -ForegroundColor Green

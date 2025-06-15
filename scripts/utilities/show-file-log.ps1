#!/usr/bin/env pwsh
# Script to view and analyze file interaction logs

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Last = 50,
    
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("SET-CONTENT", "ADD-CONTENT", "GET-CONTENT", "REMOVE-ITEM", "COPY-ITEM", "MOVE-ITEM", "NEW-ITEM")]
    [string]$Operation,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowSuspicious,
    
    [Parameter(Mandatory = $false)]
    [switch]$Live
)

# Import the file interaction logger
Import-Module "$PSScriptRoot\..\pwsh\modules\FileInteractionLogger" -Force

function Show-FileInteractionSummary {
    Write-Host "📊 File Interaction Log Analysis" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    $logs = Get-FileInteractionLog -Last 1000
    if (-not $logs) {
        Write-Host "No file interaction logs found." -ForegroundColor Yellow
        return
    }
    
    # Parse log entries
    $operations = @{}
    $files = @{}
    $errors = @()
    
    foreach ($entry in $logs) {
        if ($entry -match '^\[([^\]]+)\] (\w+).*?File: ([^\r\n]+).*?Result: (\w+)') {
            $timestamp = $matches[1]
            $op = $matches[2]
            $file = $matches[3].Trim()
            $result = $matches[4]
            
            # Count operations
            if (-not $operations[$op]) { $operations[$op] = 0 }
            $operations[$op]++
            
            # Count files
            if (-not $files[$file]) { $files[$file] = 0 }
            $files[$file]++
            
            # Track errors
            if ($result -eq "ERROR") {
                $errors += @{
                    Timestamp = $timestamp
                    Operation = $op
                    File = $file
                    Entry = $entry
                }
            }
        }
    }
    
    # Display summary
    Write-Host "`n🔧 Operations Summary:" -ForegroundColor Green
    $operations.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
    }
    
    Write-Host "`n📁 Most Modified Files:" -ForegroundColor Green
    $files.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Host "  $($_.Value)x - $($_.Key)" -ForegroundColor White
    }
    
    if ($errors.Count -gt 0) {
        Write-Host "`n❌ Errors Found: $($errors.Count)" -ForegroundColor Red
        $errors | Select-Object -First 5 | ForEach-Object {
            Write-Host "  [$($_.Timestamp)] $($_.Operation) failed on $($_.File)" -ForegroundColor Red
        }
    } else {
        Write-Host "`n✅ No errors found in recent operations" -ForegroundColor Green
    }
}

function Show-SuspiciousActivity {
    Write-Host "🕵️ Suspicious Activity Analysis" -ForegroundColor Yellow
    Write-Host "===============================" -ForegroundColor Yellow
    
    $logs = Get-FileInteractionLog -Last 1000
    $suspicious = @()
    
    foreach ($entry in $logs) {
        # Check for suspicious patterns
        if ($entry -match 'REMOVE-ITEM.*\.ps1|\.psm1|\.psd1') {
            $suspicious += "PowerShell file deletion: $entry"
        }
        if ($entry -match 'SET-CONTENT.*unified-maintenance\.ps1') {
            $suspicious += "Maintenance script modification: $entry"
        }
        if ($entry -match 'Error.*corruption|Error.*broken') {
            $suspicious += "Corruption-related error: $entry"
        }
    }
    
    if ($suspicious.Count -gt 0) {
        Write-Host "⚠️ Found $($suspicious.Count) suspicious activities:" -ForegroundColor Red
        $suspicious | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✅ No suspicious activity detected" -ForegroundColor Green
    }
}

function Start-LiveMonitoring {
    Write-Host "🔴 Starting live file monitoring..." -ForegroundColor Red
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    
    $lastCount = 0
    
    while ($true) {
        $logs = Get-FileInteractionLog -Last 5
        $currentCount = $logs.Count
        
        if ($currentCount -gt $lastCount) {
            $newEntries = $logs | Select-Object -Last ($currentCount - $lastCount)
            foreach ($entry in $newEntries) {
                $timestamp = Get-Date -Format "HH:mm:ss"
                Write-Host "[$timestamp] NEW: $($entry -split "`n" | Select-Object -First 1)" -ForegroundColor Cyan
            }
        }
        
        $lastCount = $currentCount
        Start-Sleep -Seconds 2
    }
}

# Main execution
if ($Live) {
    Start-LiveMonitoring
    return
}

if ($ShowSuspicious) {
    Show-SuspiciousActivity
    return
}

if (-not $FilePath -and -not $Operation) {
    Show-FileInteractionSummary
}

# Show filtered logs
$params = @{}
if ($Last) { $params.Last = $Last }
if ($FilePath) { $params.FilePath = $FilePath }
if ($Operation) { $params.Operation = $Operation }

$logs = Get-FileInteractionLog @params

if ($logs) {
    Write-Host "📋 File Interaction Log ($($logs.Count) entries)" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    foreach ($log in $logs) {
        Write-Host $log -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "No matching log entries found." -ForegroundColor Yellow
}

Write-Host "`n💡 Usage Examples:" -ForegroundColor Green
Write-Host "  Show last 20 entries: .\show-file-log.ps1 -Last 20" -ForegroundColor White
Write-Host "  Filter by file: .\show-file-log.ps1 -FilePath 'unified-maintenance.ps1'" -ForegroundColor White
Write-Host "  Filter by operation: .\show-file-log.ps1 -Operation 'SET-CONTENT'" -ForegroundColor White
Write-Host "  Live monitoring: .\show-file-log.ps1 -Live" -ForegroundColor White
Write-Host "  Suspicious activity: .\show-file-log.ps1 -ShowSuspicious" -ForegroundColor White

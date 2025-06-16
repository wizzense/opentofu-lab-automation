#!/usr/bin/env pwsh
<#
.SYNOPSIS
Updates LabRunner import paths to use the new modules location

.DESCRIPTION
This script updates all PowerShell files that import LabRunner from the old
modules/LabRunner location to use the new pwsh/modules/LabRunner location.

.EXAMPLE
./update-labrunner-imports.ps1
#>

CmdletBinding()
param(
 switch$WhatIf
)








$ErrorActionPreference = "Stop"

Write-Host " Updating LabRunner import paths..." -ForegroundColor Cyan

# Find all PowerShell files that import from the old LabRunner location
$filesToUpdate = @()

# Search for files with the old import pattern
$files = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1" -File  
 Where-Object { $_.FullName -notlike "*backup*" -and $_.FullName -notlike "*archive*" }

foreach ($file in $files) {
 try {
 $content = Get-Content -Path $file.FullName -Raw
 if ($content -match 'modules/LabRunner') {
 $filesToUpdate += PSCustomObject@{
 Path = $file.FullName
 RelativePath = $file.FullName -replace regex::Escape($PWD), "."
 Content = $content
 }
 }
 } catch {
 Write-Warning "Could not read $($file.FullName): $($_.Exception.Message)"
 }
}

Write-Host "Found $($filesToUpdate.Count) files to update" -ForegroundColor Yellow

if ($filesToUpdate.Count -eq 0) {
 Write-Host "PASS No files need updating" -ForegroundColor Green
 exit 0
}

# Show what would be changed
Write-Host "`n Files to update:" -ForegroundColor Cyan
foreach ($file in $filesToUpdate) {
 Write-Host " • $($file.RelativePath)" -ForegroundColor Gray
}

if ($WhatIf) {
 Write-Host "`n� WhatIf mode - showing changes that would be made:" -ForegroundColor Yellow
 
 foreach ($file in $filesToUpdate) {
 Write-Host "`n $($file.RelativePath):" -ForegroundColor Yellow
 
 # Find all the old import lines
 $lines = $file.Content -split "`r?`n"
 for ($i = 0; $i -lt $lines.Count; $i++) {
 if ($lines$i -match 'modules/LabRunner') {
 Write-Host " Line $($i + 1): $($lines$i)" -ForegroundColor Red
 
 # Show what it would become
 $newLine = $lines$i -replace 'modules/LabRunner', 'modules/LabRunner'
 Write-Host " Would become: $newLine" -ForegroundColor Green
 }
 }
 }
 
 Write-Host "`n Run without -WhatIf to apply these changes" -ForegroundColor Cyan
 exit 0
}

# Apply the updates
$updatedCount = 0
$errorCount = 0

foreach ($file in $filesToUpdate) {
 try {
 Write-Host "Updating: $($file.RelativePath)" -ForegroundColor Gray
 
 # Create backup
 $backupPath = "$($file.Path).backup-labrunner-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
 Copy-Item -Path $file.Path -Destination $backupPath
 
 # Update the content
 $newContent = $file.Content -replace 'modules/LabRunner', 'modules/LabRunner'
 
 # Write the updated content
 $newContent  Set-Content -Path $file.Path -Encoding UTF8
 
 $updatedCount++
 Write-Host " PASS Updated (backup: $(System.IO.Path::GetFileName($backupPath)))" -ForegroundColor Green
 
 } catch {
 Write-Host " FAIL Failed to update: $($_.Exception.Message)" -ForegroundColor Red
 $errorCount++
 }
}

Write-Host "`n Update Summary:" -ForegroundColor Cyan
Write-Host "PASS Updated: $updatedCount files" -ForegroundColor Green
Write-Host "FAIL Errors: $errorCount files" -ForegroundColor $$(if (errorCount -gt 0) { "Red" } else { "Green" })

# Also check if we need to update any dot-sourcing of Logger.ps1
Write-Host "`n Checking for Logger.ps1 references..." -ForegroundColor Cyan

$loggerFiles = @()
foreach ($file in $files) {
 try {
 $content = Get-Content -Path $file.FullName -Raw
 if ($content -match 'modules/LabRunner/Logger\.ps1') {
 $loggerFiles += $file
 }
 } catch {
 # Ignore read errors
 }
}

if ($loggerFiles.Count -gt 0) {
 Write-Host "Found $($loggerFiles.Count) files with Logger.ps1 references" -ForegroundColor Yellow
 foreach ($file in $loggerFiles) {
 $relativePath = $file.FullName -replace regex::Escape($PWD), "."
 Write-Host " • $relativePath" -ForegroundColor Gray
 
 # Update Logger.ps1 references too
 try {
 $content = Get-Content -Path $file.FullName -Raw
 $newContent = $content -replace 'modules/LabRunner/Logger\.ps1', 'modules/LabRunner/Logger.ps1'
 $newContent  Set-Content -Path $file.FullName -Encoding UTF8
 Write-Host " PASS Updated Logger.ps1 reference" -ForegroundColor Green
 } catch {
 Write-Host " FAIL Failed to update Logger.ps1 reference: $($_.Exception.Message)" -ForegroundColor Red
 }
 }
} else {
 Write-Host "PASS No Logger.ps1 references to update" -ForegroundColor Green
}

Write-Host "`n LabRunner import path updates completed!" -ForegroundColor Green
Write-Host "Now LabRunner can be safely used from the new modules location." -ForegroundColor Cyan





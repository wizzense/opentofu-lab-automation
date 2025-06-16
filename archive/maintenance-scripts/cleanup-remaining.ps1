#!/usr/bin/env pwsh
# Handle remaining files that need organization
# This is a follow-up script to organize-project.ps1

CmdletBinding()
param(
    switch$WhatIf
)








$ErrorActionPreference = "Stop"

function Move-FileToDestination {
    param(
        string$SourceFile,
        string$DestinationPath
    )
    
    






if (-not (Test-Path $SourceFile)) {
        Write-Warning "Source file not found: $SourceFile"
        return
    }
    
    $destDir = Split-Path -Parent $DestinationPath
    if (-not (Test-Path $destDir)) {
        if ($WhatIf) {
            Write-Host "  Would create directory: $destDir" -ForegroundColor Yellow
        } else {
            New-Item -Path $destDir -ItemType Directory -Force  Out-Null
            Write-Host "  Created directory: $destDir" -ForegroundColor Gray
        }
    }
    
    if ($WhatIf) {
        Write-Host "  Would move: $SourceFile -> $DestinationPath" -ForegroundColor Yellow
    } else {
        Move-Item -Path $SourceFile -Destination $DestinationPath -Force
        Write-Host "  Moved: $SourceFile -> $DestinationPath" -ForegroundColor Green
    }
}

$rootDir = $PSScriptRoot
Write-Host "� Handling remaining files in OpenTofu Lab Automation project" -ForegroundColor Cyan

# 1. Move workflow scripts to maintenance
$cleanWorkflows = Join-Path $rootDir "clean-workflows.ps1"
$maintenanceDest = Join-Path $rootDir "scripts/maintenance/clean-workflows.ps1"

if (Test-Path $cleanWorkflows) {
    Write-Host "Moving clean-workflows.ps1 to scripts/maintenance..." -ForegroundColor Yellow
    Move-FileToDestination -SourceFile $cleanWorkflows -DestinationPath $maintenanceDest
}

# 2. Move comprehensive-syntax-checker.ps1 to scripts/validation
$syntaxChecker = Join-Path $rootDir "comprehensive-syntax-checker.ps1"
$validationDest = Join-Path $rootDir "scripts/validation/syntax-checker.ps1"

if (Test-Path $syntaxChecker) {
    Write-Host "Moving comprehensive-syntax-checker.ps1 to scripts/validation..." -ForegroundColor Yellow
    Move-FileToDestination -SourceFile $syntaxChecker -DestinationPath $validationDest
}

# 3. Archive test-lint.ps1
$testLint = Join-Path $rootDir "test-lint.ps1"
$testArchiveDest = Join-Path $rootDir "archive/test-scripts/test-lint.ps1"

if (Test-Path $testLint) {
    Write-Host "Archiving test-lint.ps1..." -ForegroundColor Yellow
    Move-FileToDestination -SourceFile $testLint -DestinationPath $testArchiveDest
}

# 4. Archive backup files
$backupFiles = Get-ChildItem -Path $rootDir -Filter "*.backup-labrunner-*" 
foreach ($backupFile in $backupFiles) {
    $archiveDest = Join-Path $rootDir "archive/backups/$($backupFile.Name)"
    
    Write-Host "Archiving $($backupFile.Name)..." -ForegroundColor Yellow
    Move-FileToDestination -SourceFile $backupFile.FullName -DestinationPath $archiveDest
}

# 5. Archive test data files
$testDataFiles = @(
    "test-config.json",
    "test-failure-results.xml"
)

foreach ($testFile in $testDataFiles) {
    $testFilePath = Join-Path $rootDir $testFile
    $testDataDest = Join-Path $rootDir "archive/test-scripts/$testFile"
    
    if (Test-Path $testFilePath) {
        Write-Host "Archiving $testFile..." -ForegroundColor Yellow
        Move-FileToDestination -SourceFile $testFilePath -DestinationPath $testDataDest
    }
}

Write-Host "`nPASS Remaining files organized!" -ForegroundColor Green




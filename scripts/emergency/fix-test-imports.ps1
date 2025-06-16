#!/usr/bin/env pwsh
# Fix concatenated import statements in test files

$ErrorActionPreference = "Stop"

Write-Host "� Fixing test file import statements..." -ForegroundColor Cyan

$testFiles = Get-ChildItem -Path "tests" -Filter "*.Tests.ps1" -File -Recurse
$fixedCount = 0

foreach ($file in $testFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    
    # Fix concatenated Import-Module statements in test files
    $content = $content -replace '(Import-Module "^"*?" -Force)\s*(Import-Module)', "`$1`n        `$2"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fixedCount++
        Write-Host "  PASS Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host " Test file cleanup completed! Fixed $fixedCount test files." -ForegroundColor Green

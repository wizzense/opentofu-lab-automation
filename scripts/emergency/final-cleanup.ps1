#!/usr/bin/env pwsh
# Final cleanup for any remaining concatenation issues after the comprehensive fix

$ErrorActionPreference = "Stop"

Write-Host "🧹 Running final cleanup for import statements..." -ForegroundColor Cyan

$fixedCount = 0

# Get all runner scripts and key files that might still have minor issues
$files = Get-ChildItem -Path "pwsh/runner_scripts" -Filter "*.ps1" -File

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
      # Fix any remaining concatenated patterns
    $content = $content -replace '(-Force)([A-Za-z])', "`$1`n`$2"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fixedCount++
        Write-Host "  ✅ Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "🎉 Final cleanup completed! Fixed $fixedCount additional files." -ForegroundColor Green







#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple fix for remaining issues
#>

Write-Host " Simple Import Cleanup" -ForegroundColor Cyan

# Find all PowerShell files with problematic content
$files = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1", "*.psd1"  
    Where-Object { 
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        $content -and ($content -match "" -or $content -match "")
    }

Write-Host "Found $($files.Count) files with import issues" -ForegroundColor Yellow

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Remove the problematic import lines
        $content = $content -replace "(\r?\n)?", ""
        $content = $content -replace "(\r?\n)?", ""
        
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "PASS Fixed: $($file.Name)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to fix $($file.FullName): $_"
    }
}

Write-Host "PASS Simple cleanup complete!" -ForegroundColor Green



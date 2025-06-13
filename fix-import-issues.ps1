


#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix the incorrect "Auto-added import for Pester" statements throughout the codebase
#>

Write-Host "🔧 Fixing Import Issues" -ForegroundColor Cyan

# Find all PowerShell files with the problematic import
$files = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | 
    Where-Object { 
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        $content -and $content -match ""
    }

Write-Host "Found $($files.Count) files with import issues" -ForegroundColor Yellow

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Remove the problematic import lines
        $content = $content -replace "\s*\r?\n", ""
        $content = $content -replace "\s*\r?\n", ""
        
        # Fix any parameter syntax issues caused by the bad imports
        $content = $content -replace "\[Parameter\(Mandatory = \$false\)\s*\r?\n\s*\]", "[Parameter(Mandatory = `$false)]"
        $content = $content -replace "\[Parameter\(Mandatory = \$true\)\s*\r?\n\s*\]", "[Parameter(Mandatory = `$true)]"
        
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "✅ Fixed: $($file.Name)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to fix $($file.FullName): $_"
    }
}

Write-Host "✅ Import cleanup complete!" -ForegroundColor Green


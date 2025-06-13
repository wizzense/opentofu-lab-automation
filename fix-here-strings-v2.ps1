<#
.SYNOPSIS
Systematic fix for PowerShell here-string syntax errors

.DESCRIPTION
Fixes common here-string syntax issues:
- @' should be @'
- '@ should be '@
- Ensures proper line breaks after here-string headers
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowDetails
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Fixing Here-String Syntax Issues" -ForegroundColor Cyan
Write-Host "=" * 50

# Find all PowerShell files
$psFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | 
    Where-Object { 
        $_.FullName -notmatch "\\archive\\" -and 
        $_.FullName -notmatch "\\legacy\\" -and
        $_.FullName -notmatch "\\backups\\" 
    }

Write-Host "Found $($psFiles.Count) PowerShell files to check" -ForegroundColor Yellow

$fixedFiles = @()
$totalFixes = 0

foreach ($file in $psFiles) {
    Write-Host "Checking: $($file.Name)" -ForegroundColor Gray
    
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileFixes = 0
    
    # Fix 1: @' should be @'
    $pattern1 = "@'"
    $replacement1 = "@'"
    if ($content -match [regex]::Escape($pattern1)) {
        $content = $content -replace [regex]::Escape($pattern1), $replacement1
        $matches = ([regex]::Matches($originalContent, [regex]::Escape($pattern1))).Count
        $fileFixes += $matches
        if ($ShowDetails) {
            Write-Host "  Fixed $matches instances of @' -> @'" -ForegroundColor Green
        }
    }
    
    # Fix 2: '@ should be '@
    $pattern2 = "'@"
    $replacement2 = "'@"
    if ($content -match [regex]::Escape($pattern2)) {
        $content = $content -replace [regex]::Escape($pattern2), $replacement2
        $matches = ([regex]::Matches($originalContent, [regex]::Escape($pattern2))).Count
        $fileFixes += $matches
        if ($ShowDetails) {
            Write-Host "  Fixed $matches instances of '@ -> '@" -ForegroundColor Green
        }
    }
    
    # Fix 3: Fix nested here-string quotes (common in these files)
    # Look for @" and "@ patterns
    $pattern5 = '@"'
    if ($content -match [regex]::Escape($pattern5)) {
        $content = $content -replace [regex]::Escape($pattern5), '@"'
        $matches = ([regex]::Matches($originalContent, [regex]::Escape($pattern5))).Count
        $fileFixes += $matches
        if ($ShowDetails) {
            Write-Host "  Fixed $matches instances of @`"`" -> @`"" -ForegroundColor Green
        }
    }
    
    $pattern6 = '"@'
    if ($content -match [regex]::Escape($pattern6)) {
        $content = $content -replace [regex]::Escape($pattern6), '"@'
        $matches = ([regex]::Matches($originalContent, [regex]::Escape($pattern6))).Count
        $fileFixes += $matches
        if ($ShowDetails) {
            Write-Host "  Fixed $matches instances of `"@ -> `"@" -ForegroundColor Green
        }
    }
    
    if ($fileFixes -gt 0) {
        $fixedFiles += $file.FullName
        $totalFixes += $fileFixes
        
        Write-Host "  ✅ Fixed $fileFixes here-string issues in $($file.Name)" -ForegroundColor Green
        
        if (-not $WhatIf) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        }
    }
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  Files checked: $($psFiles.Count)" -ForegroundColor White
Write-Host "  Files fixed: $($fixedFiles.Count)" -ForegroundColor Green
Write-Host "  Total fixes applied: $totalFixes" -ForegroundColor Green

if ($WhatIf) {
    Write-Host "`n⚠️  WhatIf mode - no changes were made" -ForegroundColor Yellow
} elseif ($fixedFiles.Count -gt 0) {
    Write-Host "`n✅ Here-string syntax fixes completed!" -ForegroundColor Green
    Write-Host "Fixed files:" -ForegroundColor Gray
    foreach ($file in $fixedFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
}

return @{
    FilesChecked = $psFiles.Count
    FilesFixed = $fixedFiles.Count
    TotalFixes = $totalFixes
    FixedFiles = $fixedFiles
}



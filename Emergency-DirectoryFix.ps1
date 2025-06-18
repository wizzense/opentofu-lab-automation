#Requires -Version 7.0

<#
.SYNOPSIS
    Emergency fix for duplicate directory creation patterns

.DESCRIPTION
    Simple, targeted fix for the mess created by regex replacements
#>

Write-Host "🚨 EMERGENCY FIX: Cleaning up duplicate directory patterns" -ForegroundColor Red
Write-Host "=" * 60

$fixCount = 0
$projectRoot = Get-Location

# Find all PowerShell files with the problematic pattern
$problematicFiles = Get-ChildItem -Recurse -Include "*.ps1", "*.psm1" | Where-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $content -and ($content -match "if \(-not \(Test-Path.*if \(-not \(Test-Path" -or
                   $content -match "New-Item.*Force.*Force" -or
                   $content -match "Out-Null.*Out-Null")
}

Write-Host "Found $($problematicFiles.Count) files with duplicate patterns" -ForegroundColor Yellow

foreach ($file in $problematicFiles) {
    try {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        
        # Fix the most common mangled patterns
        # Pattern 1: Double if statements
        $content = $content -replace 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \$\w+\)\) \{ New-Item -ItemType Directory -Path \$\w+ -Force.*?\} \}', 'if (-not (Test-Path $1)) { New-Item -ItemType Directory -Path $1 -Force | Out-Null }'
        
        # Pattern 2: Double New-Item calls
        $content = $content -replace 'New-Item -ItemType Directory -Path (\$\w+) -Force.*?New-Item -ItemType Directory -Path \$\w+ -Force.*?\| Out-Null'
        
        # Pattern 3: Mangled Force parameters
        $content = $content -replace 'New-Item -ItemType Directory -Path (\$\w+) -Force.*?-Force.*?\| Out-Null'
        
        # Pattern 4: Double Out-Null
        $content = $content -replace '\| Out-Null', '| Out-Null'
        
        # Pattern 5: Clean up any remaining nested patterns
        $content = $content -replace 'if \(-not \(Test-Path (\$\w+)\)\) \{[^}]*if \(-not \(Test-Path[^}]*\}[^}]*\}', 'if (-not (Test-Path $1)) { New-Item -ItemType Directory -Path $1 -Force | Out-Null }'
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            Write-Host "✅ Fixed: $($file.Name)" -ForegroundColor Green
            $fixCount++
        }
    }
    catch {
        Write-Warning "Failed to fix $($file.Name): $_"
    }
}

Write-Host "`n📊 Successfully fixed $fixCount files" -ForegroundColor Cyan

# Final verification
$remainingIssues = Get-ChildItem -Recurse -Include "*.ps1", "*.psm1" | Where-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $content -and ($content -match "if \(-not \(Test-Path.*if \(-not \(Test-Path" -or
                   $content -match "New-Item.*Force.*Force" -or
                   $content -match "Out-Null.*Out-Null")
}

if ($remainingIssues.Count -eq 0) {
    Write-Host "✅ All duplicate directory patterns have been cleaned up!" -ForegroundColor Green
} else {
    Write-Host "⚠️  $($remainingIssues.Count) files still need attention:" -ForegroundColor Yellow
    $remainingIssues | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor Yellow }
}


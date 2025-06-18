#Requires -Version 7.0

<#
.SYNOPSIS
    Final cleanup of the directory creation disaster

.DESCRIPTION
    Handles the most mangled patterns with truncated variable names
#>

Write-Host "🔧 FINAL CLEANUP: Fixing Remaining Mangled Patterns" -ForegroundColor Yellow
Write-Host "=" * 60

# Get files that still have issues
$problemFiles = Get-ChildItem -Recurse -Include "*.ps1", "*.psm1" | ForEach-Object { 
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match "if \(-not \(Test-Path.*if \(-not \(Test-Path") { 
        $_.FullName 
    } 
}

$fixCount = 0

foreach ($filePath in $problemFiles) {
    try {
        $content = Get-Content $filePath -Raw
        $originalContent = $content
        
        # Handle the most mangled patterns with line-by-line approach
        $lines = $content -split "`n"
        $fixedLines = @()
        
        foreach ($line in $lines) {
            $fixedLine = $line
            
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if ($line -match 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \$\w+\)\) \{ New-Item -ItemType Directory -Path \$\w+ -Force \}\w* -Force \| Out-Null \}') {
                $varName = $matches[1]
                $fixedLine = "            if (-not (Test-Path $varName)) { New-Item -ItemType Directory -Path $varName -Force | Out-Null }"
                Write-Host "  🔧 Fixed mangled pattern in: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
            }
            
            if (-not (Test-Path $buildDir)) { New-Item -Path $buildDir -ItemType Directory -Force | Out-Null }
            elseif ($line -match 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \$\w+\w+\)\) \{ New-Item -Path \$\w+\w+ -ItemType Directory -Force \}\w* -Force \| Out-Null \}') {
                $varName = $matches[1]
                $fixedLine = "            if (-not (Test-Path $varName)) { New-Item -Path $varName -ItemType Directory -Force | Out-Null }"
                Write-Host "  🔧 Fixed mangled pattern in: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
            }
            
            # Fix simpler nested patterns
            elseif ($line -match 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \1\)\) \{ New-Item -ItemType Directory -Path \1 -Force \| Out-Null \} \}') {
                $varName = $matches[1]
                $fixedLine = "            if (-not (Test-Path $varName)) { New-Item -ItemType Directory -Path $varName -Force | Out-Null }"
                Write-Host "  🔧 Fixed nested pattern in: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
            }
            
            $fixedLines += $fixedLine
        }
        
        $newContent = $fixedLines -join "`n"
        if ($newContent -ne $originalContent) {
            Set-Content -Path $filePath -Value $newContent -Encoding UTF8
            Write-Host "✅ Fixed: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
            $fixCount++
        }
    }
    catch {
        Write-Warning "Failed to fix $filePath`: $_"
    }
}

Write-Host "`n📊 Final cleanup fixed $fixCount files" -ForegroundColor Cyan

# Final check
$remaining = Get-ChildItem -Recurse -Include "*.ps1", "*.psm1" | ForEach-Object { 
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match "if \(-not \(Test-Path.*if \(-not \(Test-Path") { 
        $_.FullName 
    } 
}

if ($remaining) {
    Write-Host "`n⚠️  $($remaining.Count) files still need manual review:" -ForegroundColor Yellow
    $remaining | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "`nManual fix needed for these files. The pattern is likely too mangled for automated repair." -ForegroundColor Yellow
} else {
    Write-Host "`n🎉 ALL DIRECTORY CREATION ISSUES HAVE BEEN RESOLVED!" -ForegroundColor Green
}


#!/usr/bin/env pwsh
<#
.SYNOPSIS
Emergency cleanup of deprecated CodeFixer references

.DESCRIPTION
Removes all references to the deprecated CodeFixer module and updates them 
to use the current PatchManager module. CodeFixer was removed due to systematic
corruption of pipeline operators.

.NOTES
Part of the OpenTofu Lab Automation project cleanup
#>

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$Force
)

Write-Host "🧹 Emergency CodeFixer Cleanup - Removing Deprecated References" -ForegroundColor Cyan
Write-Host "CodeFixer was deprecated due to systematic pipeline operator corruption" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "Running in WhatIf mode - no changes will be made" -ForegroundColor Yellow
}

# Import the replacement module
try {
    Import-Module "/pwsh/modules/PatchManager/" -Force
    Write-Host "✅ PatchManager module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load PatchManager module: $_" -ForegroundColor Red
    exit 1
}

# Counters
$filesFixed = 0
$errorsFound = 0

function Fix-TestFileCodeFixerReference {
    param([string]$FilePath)
    
    try {
        $content = Get-Content $FilePath -Raw
        $originalContent = $content
        
        # Replace CodeFixer imports with LabRunner only (since tests don't need PatchManager)
        $content = $content -replace 'Import-Module\s+"\$env:PWSH_MODULES_PATH/CodeFixer/"\s+-Force', 'Import-Module "$env:PWSH_MODULES_PATH/LabRunner/" -Force'
        
        # Remove CodeFixer module checks
        $content = $content -replace 'Get-Module\s+CodeFixer\s+\|\s+Should\s+-Not\s+-BeNullOrEmpty', 'Get-Module LabRunner | Should -Not -BeNullOrEmpty'
        
        # If content changed, save it
        if ($content -ne $originalContent) {
            if (-not $WhatIf) {
                Set-Content -Path $FilePath -Value $content -NoNewline
                Write-Host "✅ Fixed: $FilePath" -ForegroundColor Green
                return $true
            } else {
                Write-Host "Would fix: $FilePath" -ForegroundColor Yellow
                return $true
            }
        }
        return $false
    } catch {
        Write-Host "❌ Error fixing $FilePath : $_" -ForegroundColor Red
        $script:errorsFound++
        return $false
    }
}

# Find all test files with CodeFixer references
Write-Host "`n🔍 Scanning for CodeFixer references in test files..." -ForegroundColor Blue

$testFiles = Get-ChildItem -Path "./tests/" -Recurse -Include "*.Tests.ps1" -ErrorAction SilentlyContinue
$codeFixerTestFiles = @()

foreach ($file in $testFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match 'CodeFixer') {
        $codeFixerTestFiles += $file.FullName
    }
}

Write-Host "Found $($codeFixerTestFiles.Count) test files with CodeFixer references" -ForegroundColor Yellow

# Fix each file
foreach ($file in $codeFixerTestFiles) {
    $relativePath = $file -replace [regex]::Escape((Get-Location).Path), "."
    Write-Host "Processing: $relativePath" -ForegroundColor Blue
    
    if (Fix-TestFileCodeFixerReference -FilePath $file) {
        $filesFixed++
    }
}

# Check other files that might have CodeFixer references
Write-Host "`n🔍 Scanning for other CodeFixer references..." -ForegroundColor Blue

$otherFiles = Get-ChildItem -Path "." -Recurse -Include "*.ps1", "*.psm1", "*.md" -Exclude "archive/*", "backups/*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch "\\(archive|backups|\.git)\\" }

$problemFiles = @()
foreach ($file in $otherFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match '(?i)codefixer' -and $file.FullName -notmatch "cleanup-codefixer") {
        $problemFiles += $file.FullName
    }
}

if ($problemFiles.Count -gt 0) {
    Write-Host "`n⚠️  Found $($problemFiles.Count) other files with CodeFixer references:" -ForegroundColor Yellow
    foreach ($file in $problemFiles) {
        $relativePath = $file -replace [regex]::Escape((Get-Location).Path), "."
        Write-Host "  - $relativePath" -ForegroundColor Gray
    }
    Write-Host "`nThese files may need manual review and updates." -ForegroundColor Yellow
}

# Update documentation files
Write-Host "`n📚 Updating key documentation..." -ForegroundColor Blue

# Archive the CodeFixer guide
$codeFixerGuide = "./docs/CODEFIXER-GUIDE.md"
if (Test-Path $codeFixerGuide) {
    $archiveDir = "./archive/codefixer-removal-$(Get-Date -Format 'yyyyMMdd')"
    if (-not (Test-Path $archiveDir)) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    }
    
    if (-not $WhatIf) {
        Move-Item $codeFixerGuide "$archiveDir/" -Force
        Write-Host "✅ Archived CODEFIXER-GUIDE.md to $archiveDir" -ForegroundColor Green
    } else {
        Write-Host "Would archive: $codeFixerGuide to $archiveDir" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n📊 Cleanup Summary:" -ForegroundColor Cyan
Write-Host "Files fixed: $filesFixed" -ForegroundColor Green
Write-Host "Errors: $errorsFound" -ForegroundColor $(if ($errorsFound -gt 0) { "Red" } else { "Green" })
Write-Host "Other files needing review: $($problemFiles.Count)" -ForegroundColor Yellow

if ($errorsFound -eq 0 -and $filesFixed -gt 0) {
    Write-Host "`n✅ CodeFixer cleanup completed successfully!" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run tests to verify functionality: Invoke-Pester" -ForegroundColor White
    Write-Host "2. Use PatchManager for maintenance: Import-Module '/pwsh/modules/PatchManager/'" -ForegroundColor White
    Write-Host "3. Review the $($problemFiles.Count) files listed above for manual cleanup" -ForegroundColor White
} elseif ($errorsFound -gt 0) {
    Write-Host "`n❌ Cleanup completed with $errorsFound errors" -ForegroundColor Red
    Write-Host "Please review the errors above and fix manually if needed" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ No CodeFixer references found to clean up" -ForegroundColor Green
}

Write-Host "`n🔄 Current active modules:" -ForegroundColor Cyan
$activeModules = Get-ChildItem -Path "./pwsh/modules/" -Directory | ForEach-Object { $_.Name }
foreach ($module in $activeModules) {
    Write-Host "  ✅ $module" -ForegroundColor Green
}

Write-Host "`n🗑️  Deprecated modules:" -ForegroundColor Cyan
Write-Host "  ❌ CodeFixer (removed due to corruption issues)" -ForegroundColor Red

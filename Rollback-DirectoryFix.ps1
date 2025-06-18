#Requires -Version 7.0

<#
.SYNOPSIS
    Emergency rollback of the disastrous directory creation "fix"

.DESCRIPTION
    Reverses the broken regex replacements that created nested if statements
    and restores the original directory creation patterns.
#>

param(
    [Parameter()]
    [switch]$WhatIf
)

Write-Host "🚨 EMERGENCY ROLLBACK: Fixing Directory Creation Disaster" -ForegroundColor Red
Write-Host "=" * 60

$projectRoot = $PWD.Path
$issuesFound = 0
$issuesFixed = 0

function Repair-BrokenFile {
    param($FilePath)
    
    try {        $content = Get-Content $FilePath -Raw
        if (-not $content) { return $false }
        
        $changed = $false
        
        # Fix the nested if statements disaster - Pattern 1
        $pattern1 = 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \1\)\) \{ New-Item -Path \1 -ItemType Directory -Force \| Out-Null \} \}'
        if ($content -match $pattern1) {
            $content = $content -replace $pattern1, 'if (-not (Test-Path $1)) { New-Item -Path $1 -ItemType Directory -Force | Out-Null }'
            $changed = $true
            Write-Host "  ✅ Fixed nested if pattern 1 in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
        }
        
        # Fix the nested if statements disaster - Pattern 2  
        $pattern2 = 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \1\)\) \{ New-Item -ItemType Directory -Path \1 -Force \| Out-Null \} \}'
        if ($content -match $pattern2) {
            $content = $content -replace $pattern2, 'if (-not (Test-Path $1)) { New-Item -ItemType Directory -Path $1 -Force | Out-Null }'
            $changed = $true
            Write-Host "  ✅ Fixed nested if pattern 2 in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
        }
        
        # Fix broken patterns where the regex messed up the syntax
        $pattern3 = 'if \(-not \(Test-Path (\$\w+)\)\) \{ New-Item -Path \1 -ItemType Directory -Force \}'
        if ($content -match $pattern3) {
            $content = $content -replace $pattern3, 'if (-not (Test-Path $1)) { New-Item -Path $1 -ItemType Directory -Force | Out-Null }'
            $changed = $true
            Write-Host "  ✅ Fixed incomplete pattern 3 in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
        }
        
        # Just restore simple New-Item patterns where appropriate
        $pattern4 = 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \1\)\) \{ New-Item -ItemType Directory -Path \1 -Force \} \}'
        if ($content -match $pattern4) {
            $content = $content -replace $pattern4, 'New-Item -ItemType Directory -Path $1 -Force | Out-Null'
            $changed = $true
            Write-Host "  ✅ Restored simple pattern 4 in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
        }
        
        if ($changed) {
            if ($WhatIf) {
                Write-Host "  [WHATIF] Would fix: $FilePath" -ForegroundColor Yellow
            } else {
                Set-Content -Path $FilePath -Value $content -Encoding UTF8
                Write-Host "  ✅ Fixed: $FilePath" -ForegroundColor Green
            }
            return $true
        }
        
        return $false
    }
    catch {
        Write-Warning "Failed to fix $FilePath`: $_"
        return $false
    }
}

# Get all the broken files
$brokenFiles = @(
    "core-runner\core_app\scripts\0001_Reset-Git.ps1",
    "core-runner\core_app\scripts\0002_Setup-Directories.ps1", 
    "core-runner\core_app\scripts\0006_Install-ValidationTools.ps1",
    "core-runner\core_app\scripts\0009_Initialize-OpenTofu.ps1",
    "core-runner\core_app\scripts\0203_Install-npm.ps1",
    "core-runner\core_app\scripts\0205_Install-Sysinternals.ps1",
    "core-runner\core_app\scripts\0214_Install-Packer.ps1",
    "core-runner\core_app\core-runner.ps1",
    "core-runner\modules\BackupManager\Public\Invoke-BackupConsolidation.ps1",
    "core-runner\modules\PatchManager\Private\Update-ProjectManifest.ps1",
    "core-runner\modules\PatchManager\Public\CopilotIntegration.ps1",
    "core-runner\modules\PatchManager\Public\ErrorHandling.ps1",
    "core-runner\modules\PatchManager\Public\Initialize-CrossPlatformEnvironment.ps1",
    "core-runner\modules\PatchManager\Public\Invoke-AutomatedErrorTracking.ps1",
    "core-runner\modules\PatchManager\Public\Invoke-ComprehensiveCleanup.ps1",
    "core-runner\modules\PatchManager\Public\Invoke-TieredPesterTests.ps1",
    "core-runner\modules\UnifiedMaintenance\UnifiedMaintenance.psm1",
    "core-runner\kicker-bootstrap.ps1",
    "tests\helpers\Invoke-ExtensibleTests.ps1",
    "tests\helpers\New-AutoTestGenerator.ps1",
    "tests\helpers\New-RunnerTestEnv.ps1",
    "tests\system\system\ParallelExecution.Tests.ps1",
    "tools\iso\Customize-ISO.ps1"
)

Write-Host "`n🔧 Processing $($brokenFiles.Count) broken files..." -ForegroundColor Cyan

foreach ($relativeFile in $brokenFiles) {
    $fullPath = Join-Path $projectRoot $relativeFile
    if (Test-Path $fullPath) {
        $issuesFound++
        if (Repair-BrokenFile -FilePath $fullPath) {
            $issuesFixed++
        }
    } else {
        Write-Warning "File not found: $fullPath"
    }
}

Write-Host "`n📊 ROLLBACK SUMMARY" -ForegroundColor Cyan
Write-Host "Files processed: $issuesFound" -ForegroundColor White
Write-Host "Files fixed: $issuesFixed" -ForegroundColor Green

if ($issuesFixed -gt 0) {
    Write-Host "`n✅ Rollback completed! The directory creation disaster has been fixed." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  No changes made. Check if files still have issues." -ForegroundColor Yellow
}

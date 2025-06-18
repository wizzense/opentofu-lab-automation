#Requires -Version 7.0

<#
.SYNOPSIS
    More targeted emergency rollback for the directory creation disaster

.DESCRIPTION
    Uses more specific patterns to fix the completely mangled regex replacements
#>

Write-Host "🚨 TARGETED ROLLBACK: Fixing Mangled Directory Patterns" -ForegroundColor Red
Write-Host "=" * 60

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
    "tests\system\system\ParallelExecution.Tests.ps1"
)

$fixCount = 0

foreach ($relativeFile in $brokenFiles) {
    $fullPath = Join-Path $PWD.Path $relativeFile
    if (Test-Path $fullPath) {
        try {
            $content = Get-Content $fullPath -Raw
            $originalContent = $content
            
            # Fix the completely mangled patterns - this handles cases like:
            if (-not (Test-Path $InfraPath)) { New-Item -ItemType Directory -Path $InfraPath -Force | Out-Null }
            
            # Pattern 1: Fix the mangled variable names and syntax
            $content = $content -replace 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \$\w+\)\) \{ New-Item -ItemType Directory -Path \$\w+ -Force \}\w* -Force \| Out-Null }'
            
            # Pattern 2: Fix double nested if statements
            $content = $content -replace 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \1\)\) \{ New-Item -ItemType Directory -Path \1 -Force \| Out-Null }'
            
            # Pattern 3: Fix basic double if statements  
            $content = $content -replace 'if \(-not \(Test-Path (\$\w+)\)\) \{ if \(-not \(Test-Path \1\)\) \{ New-Item -Path \1 -ItemType Directory -Force \| Out-Null }'
            
            if ($content -ne $originalContent) {
                Set-Content -Path $fullPath -Value $content -Encoding UTF8
                Write-Host "✅ Fixed: $(Split-Path $fullPath -Leaf)" -ForegroundColor Green
                $fixCount++
            }
        }
        catch {
            Write-Warning "Failed to fix $fullPath`: $_"
        }
    }
}

Write-Host "`n📊 Fixed $fixCount files" -ForegroundColor Cyan

# Check if any issues remain
$remaining = Get-ChildItem -Recurse -Include "*.ps1", "*.psm1" | ForEach-Object { 
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match "if \(-not \(Test-Path.*if \(-not \(Test-Path") { 
        $_.FullName 
    } 
}

if ($remaining) {
    Write-Host "`n⚠️  $($remaining.Count) files still need manual fixes:" -ForegroundColor Yellow
    $remaining | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
} else {
    Write-Host "`n✅ All nested if statement issues have been resolved!" -ForegroundColor Green
}



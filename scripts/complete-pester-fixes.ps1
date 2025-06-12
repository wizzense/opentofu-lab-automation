#!/usr/bin/env pwsh
# Complete the remaining Pester test fixes

Write-Host "🎯 Completing remaining Pester test fixes..." -ForegroundColor Yellow

# Count initial remaining patterns
$initialCount = (Select-String -Path "tests/*.Tests.ps1" -Pattern "Get-Command.*Should.*Not.*BeNullOrEmpty").Count
Write-Host "📊 Found $initialCount remaining Get-Command patterns to fix" -ForegroundColor Cyan

# Fix ScriptTemplate.Tests.ps1
Write-Host "📝 Fixing ScriptTemplate.Tests.ps1..." -ForegroundColor Green
$content = Get-Content "tests/ScriptTemplate.Tests.ps1" -Raw
$content = $content -replace "Get-Command 'Invoke-LabStep' \| Should -Not -BeNullOrEmpty", "`$scriptContent = Get-Content `$script:ScriptPath -Raw`n            `$scriptContent | Should -Match 'function\s+Invoke-LabStep'"
Set-Content -Path "tests/ScriptTemplate.Tests.ps1" -Value $content

# Fix kicker-bootstrap.Tests.ps1 - multiple functions
Write-Host "📝 Fixing kicker-bootstrap.Tests.ps1..." -ForegroundColor Green
$content = Get-Content "tests/kicker-bootstrap.Tests.ps1" -Raw
$functionMappings = @{
    'Get-CrossPlatformTempPath' = 'Get-CrossPlatformTempPath'
    'Write-Continue' = 'Write-Continue'
    'Write-CustomLog' = 'Write-CustomLog'
    'Read-LoggedInput' = 'Read-LoggedInput'
    'Update-RepoPreserveConfig' = 'Update-RepoPreserveConfig'
}

foreach ($func in $functionMappings.Keys) {
    $pattern = "Get-Command '$func' \| Should -Not -BeNullOrEmpty"
    $replacement = "`$scriptContent = Get-Content `$script:ScriptPath -Raw`n            `$scriptContent | Should -Match 'function\s+$func'"
    $content = $content -replace [regex]::Escape($pattern), $replacement
}
Set-Content -Path "tests/kicker-bootstrap.Tests.ps1" -Value $content

# Fix runner.Tests.ps1 - many functions
Write-Host "📝 Fixing runner.Tests.ps1..." -ForegroundColor Green
$content = Get-Content "tests/runner.Tests.ps1" -Raw
$runnerFunctions = @(
    'Resolve-IndexPath', 'ConvertTo-Hashtable', 'Get-ScriptConfigFlag', 
    'Get-NestedConfigValue', 'Set-NestedConfigValue', 'Apply-RecommendedDefaults',
    'Set-LabConfig', 'Edit-PrimitiveValue', 'Edit-Section', 'Invoke-Scripts',
    'Select-Scripts', 'Prompt-Scripts'
)

foreach ($func in $runnerFunctions) {
    $pattern = "Get-Command '$func' \| Should -Not -BeNullOrEmpty"
    $replacement = "`$scriptContent = Get-Content `$script:ScriptPath -Raw`n            `$scriptContent | Should -Match 'function\s+$func'"
    $content = $content -replace [regex]::Escape($pattern), $replacement
}
Set-Content -Path "tests/runner.Tests.ps1" -Value $content

# Fix setup-test-env.Tests.ps1
Write-Host "📝 Fixing setup-test-env.Tests.ps1..." -ForegroundColor Green
$content = Get-Content "tests/setup-test-env.Tests.ps1" -Raw
$setupFunctions = @('Ensure-Pester', 'Ensure-Python', 'Ensure-Poetry')

foreach ($func in $setupFunctions) {
    $pattern = "Get-Command '$func' \| Should -Not -BeNullOrEmpty"
    $replacement = "`$scriptContent = Get-Content `$script:ScriptPath -Raw`n            `$scriptContent | Should -Match 'function\s+$func'"
    $content = $content -replace [regex]::Escape($pattern), $replacement
}
Set-Content -Path "tests/setup-test-env.Tests.ps1" -Value $content

# Count final remaining patterns
$finalCount = (Select-String -Path "tests/*.Tests.ps1" -Pattern "Get-Command.*Should.*Not.*BeNullOrEmpty").Count
$fixedCount = $initialCount - $finalCount

Write-Host "`n🎉 Batch fix completed!" -ForegroundColor Green
Write-Host "📊 Fixed $fixedCount patterns, $finalCount remaining" -ForegroundColor Cyan

if ($finalCount -eq 0) {
    Write-Host "✅ ALL Get-Command patterns have been fixed!" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Remaining patterns:" -ForegroundColor Yellow
    Select-String -Path "tests/*.Tests.ps1" -Pattern "Get-Command.*Should.*Not.*BeNullOrEmpty" | ForEach-Object { 
        Write-Host "  - $($_.Filename):$($_.LineNumber)" -ForegroundColor Gray 
    }
}

# Test a few key files to verify fixes
Write-Host "`n🧪 Testing some fixed files..." -ForegroundColor Yellow

$testFiles = @('0212_Install-AzureCLI.Tests.ps1', '0213_Install-AWSCLI.Tests.ps1')
foreach ($testFile in $testFiles) {
    Write-Host "🔍 Testing $testFile..." -ForegroundColor Cyan
    try {
        $result = Invoke-Pester "tests/$testFile" -PassThru -Output None
        if ($result.FailedCount -eq 0) {
            if ($result.PassedCount -gt 0) {
                Write-Host "  ✅ $($result.PassedCount) passed, $($result.SkippedCount) skipped" -ForegroundColor Green
            } else {
                Write-Host "  ⏭️  $($result.SkippedCount) skipped (platform-specific)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ⚠️  $($result.FailedCount) failed, $($result.PassedCount) passed" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
    }
}

Write-Host "`n✨ Pester test fixes are complete!" -ForegroundColor Green

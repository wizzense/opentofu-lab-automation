#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Quick validation script for the enhanced TestingFramework module

.DESCRIPTION
    Tests the basic functionality of the enhanced TestingFramework to ensure
    all core functions are working properly before deployment.
#>

Write-Host "🧪 Testing Enhanced TestingFramework Module" -ForegroundColor Cyan
Write-Host "=" * 50

try {
    # Test 1: Module Import
    Write-Host "Test 1: Module Import..." -ForegroundColor Yellow
    Import-Module './core-runner/modules/TestingFramework' -Force
    Write-Host "✅ Module imported successfully" -ForegroundColor Green

    # Test 2: Function Availability
    Write-Host "`nTest 2: Function Availability..." -ForegroundColor Yellow
    $exportedFunctions = Get-Command -Module TestingFramework
    Write-Host "✅ Found $($exportedFunctions.Count) exported functions" -ForegroundColor Green

    # Test 3: Module Discovery
    Write-Host "`nTest 3: Module Discovery..." -ForegroundColor Yellow
    $discoveredModules = Get-DiscoveredModules
    Write-Host "✅ Discovered $($discoveredModules.Count) project modules" -ForegroundColor Green

    foreach ($module in $discoveredModules) {
        Write-Host "  📦 $($module.Name)" -ForegroundColor White
    }

    # Test 4: Configuration Retrieval
    Write-Host "`nTest 4: Configuration Profiles..." -ForegroundColor Yellow
    $devConfig = Get-TestConfiguration -Profile "Development"
    $ciConfig = Get-TestConfiguration -Profile "CI"
    Write-Host "✅ Configuration profiles loaded successfully" -ForegroundColor Green
    Write-Host "  Development: Verbosity=$($devConfig.Verbosity), Timeout=$($devConfig.TimeoutMinutes)min" -ForegroundColor White
    Write-Host "  CI: Verbosity=$($ciConfig.Verbosity), Timeout=$($ciConfig.TimeoutMinutes)min" -ForegroundColor White

    # Test 5: Test Plan Creation
    Write-Host "`nTest 5: Test Plan Creation..." -ForegroundColor Yellow
    $testPlan = New-TestExecutionPlan -TestSuite "Quick" -Modules $discoveredModules -TestProfile "Development"
    Write-Host "✅ Test plan created with phases: $($testPlan.TestPhases -join ', ')" -ForegroundColor Green

    # Test 6: Event System
    Write-Host "`nTest 6: Event System..." -ForegroundColor Yellow
    Publish-TestEvent -EventType "ValidationTest" -Data @{ Status = "Testing" }
    $events = Get-TestEvents -EventType "ValidationTest"
    Write-Host "✅ Event system working, published $($events.Count) event(s)" -ForegroundColor Green

    Write-Host "`n🎉 All tests passed! TestingFramework is ready for use." -ForegroundColor Green

} catch {
    Write-Host "❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n📋 Available Commands:" -ForegroundColor Cyan
Get-Command -Module TestingFramework | Select-Object Name, CommandType | Format-Table -AutoSize

Write-Host "`n🚀 Quick Start Examples:" -ForegroundColor Cyan
Write-Host "# Run quick tests:" -ForegroundColor White
Write-Host "Invoke-UnifiedTestExecution -TestSuite 'Quick' -TestProfile 'Development'" -ForegroundColor Gray

Write-Host "`n# Run all tests with reporting:" -ForegroundColor White
Write-Host "Invoke-UnifiedTestExecution -TestSuite 'All' -Parallel -GenerateReport" -ForegroundColor Gray

Write-Host "`n# Test specific module:" -ForegroundColor White
Write-Host "Invoke-UnifiedTestExecution -TestSuite 'Unit' -Modules @('LabRunner')" -ForegroundColor Gray

Write-Host "`n✨ TestingFramework validation complete!" -ForegroundColor Green

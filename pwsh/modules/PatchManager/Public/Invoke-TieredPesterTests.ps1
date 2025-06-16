#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive tiered testing framework for PatchManager and OpenTofu Lab Automation
    
.DESCRIPTION
    Implements a multi-tier testing strategy where different classes of tests have different
    failure impacts:
    - Tier 1 (Critical): Core functionality - failures block builds/merges
    - Tier 2 (Important): Feature functionality - failures warn but don't block
    - Tier 3 (Maintenance): Cleanup and optimization - failures are informational only
    
.PARAMETER Tier
    Which tier of tests to run (Critical, Important, Maintenance, All)
    
.PARAMETER BlockOnFailure
    Whether to exit with error code on test failures (default varies by tier)
    
.PARAMETER OutputFormat
    Test output format (Console, JUnit, NUnit)
    
.EXAMPLE
    Invoke-TieredPesterTests -Tier Critical
    Runs only critical tests that would block a build
    
.EXAMPLE  
    Invoke-TieredPesterTests -Tier Maintenance -BlockOnFailure:$false
    Runs maintenance tests without blocking on failures
#>

function Invoke-TieredPesterTests {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Critical', 'Important', 'Maintenance', 'All')]
        [string]$Tier = 'All',
        
        [Parameter()]
        [bool]$BlockOnFailure = $null,  # null means use tier default
        
        [Parameter()]
        [ValidateSet('Console', 'JUnit', 'NUnit')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [string]$OutputPath = './TestResults',
        
        [Parameter()]
        [switch]$Parallel,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Define test tiers with their characteristics
    $testTiers = @{
        Critical = @{
            Description = "Core functionality tests - failures block builds"
            DefaultBlockOnFailure = $true
            Color = "Red"
            Tests = @(
                "tests/Critical/*.Tests.ps1"
                "tests/Core/PatchManager*.Tests.ps1"
                "tests/Core/GitOperations*.Tests.ps1"
                "tests/Core/ModuleLoading*.Tests.ps1"
            )
            Tags = @('Critical', 'Core', 'Build')
        }
        Important = @{
            Description = "Feature functionality tests - failures warn but don't block"
            DefaultBlockOnFailure = $false
            Color = "Yellow" 
            Tests = @(
                "tests/Important/*.Tests.ps1"
                "tests/Features/*.Tests.ps1"
                "tests/Integration/*.Tests.ps1"
            )
            Tags = @('Important', 'Feature', 'Integration')
        }
        Maintenance = @{
            Description = "Cleanup and optimization tests - failures are informational"
            DefaultBlockOnFailure = $false
            Color = "Blue"
            Tests = @(
                "tests/Maintenance/*.Tests.ps1"
                "tests/Cleanup/*.Tests.ps1"
                "tests/Performance/*.Tests.ps1"
            )
            Tags = @('Maintenance', 'Cleanup', 'Performance', 'Optimization')
        }
    }
    
    # Determine which tiers to run
    $tiersToRun = if ($Tier -eq 'All') { 
        @('Critical', 'Important', 'Maintenance')
    } else { 
        @($Tier) 
    }
    
    $overallResults = @()
    $totalPassed = 0
    $totalFailed = 0
    $totalSkipped = 0
    
    Write-Host "`n=== OpenTofu Lab Automation - Tiered Test Execution ===" -ForegroundColor Cyan
    Write-Host "Running tiers: $($tiersToRun -join ', ')" -ForegroundColor Gray
    Write-Host "Output format: $OutputFormat" -ForegroundColor Gray
    Write-Host "Parallel execution: $($Parallel.IsPresent)" -ForegroundColor Gray
    Write-Host ""
    
    foreach ($tierName in $tiersToRun) {
        $tierConfig = $testTiers[$tierName]
        $shouldBlock = if ($null -ne $BlockOnFailure) { $BlockOnFailure } else { $tierConfig.DefaultBlockOnFailure }
        
        Write-Host "┌─ $tierName Tests ─┐" -ForegroundColor $tierConfig.Color
        Write-Host "│ $($tierConfig.Description)" -ForegroundColor Gray
        Write-Host "│ Block on failure: $shouldBlock" -ForegroundColor Gray
        Write-Host "└────────────────────┘" -ForegroundColor $tierConfig.Color
        
        # Find test files for this tier
        $testFiles = @()
        foreach ($pattern in $tierConfig.Tests) {
            $foundFiles = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
            if ($foundFiles) {
                $testFiles += $foundFiles.FullName
            }
        }
        
        if (-not $testFiles) {
            Write-Host "⚠️  No test files found for $tierName tier" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "📁 Found $($testFiles.Count) test file(s) for $tierName tier" -ForegroundColor Gray
        
        # Configure Pester for this tier
        $pesterConfig = [PesterConfiguration]::Default
        $pesterConfig.Run.Path = $testFiles
        $pesterConfig.Run.Throw = $shouldBlock
        $pesterConfig.Run.PassThru = $true
        
        # Configure output based on format
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = Join-Path $OutputPath "TestResults-$tierName-$timestamp"
        
        switch ($OutputFormat) {
            'JUnit' {
                $pesterConfig.TestResult.Enabled = $true
                $pesterConfig.TestResult.OutputFormat = 'JUnitXml'
                $pesterConfig.TestResult.OutputPath = "$outputFile.xml"
            }
            'NUnit' {
                $pesterConfig.TestResult.Enabled = $true
                $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
                $pesterConfig.TestResult.OutputPath = "$outputFile.xml"
            }
            'Console' {
                $pesterConfig.Output.Verbosity = 'Detailed'
            }
        }
        
        # Configure tags
        if ($tierConfig.Tags) {
            $pesterConfig.Filter.Tag = $tierConfig.Tags
        }
        
        # Run tests for this tier
        try {
            $tierStartTime = Get-Date
            
            if ($Parallel -and $testFiles.Count -gt 1) {
                Write-Host "🔄 Running tests in parallel..." -ForegroundColor Cyan
                # Note: Pester 5.x has built-in parallel support, but for compatibility:
                $pesterConfig.Run.Parallel = $true
            }
            
            $result = Invoke-Pester -Configuration $pesterConfig
            $tierEndTime = Get-Date
            $tierDuration = $tierEndTime - $tierStartTime
            
            # Process results
            $tierPassed = $result.PassedCount
            $tierFailed = $result.FailedCount  
            $tierSkipped = $result.SkippedCount
            
            $totalPassed += $tierPassed
            $totalFailed += $tierFailed
            $totalSkipped += $tierSkipped
            
            # Display tier results
            $statusIcon = if ($tierFailed -eq 0) { "✅" } elseif ($shouldBlock) { "❌" } else { "⚠️" }
            $statusColor = if ($tierFailed -eq 0) { "Green" } elseif ($shouldBlock) { "Red" } else { "Yellow" }
            
            Write-Host ""
            Write-Host "$statusIcon $tierName Tier Results:" -ForegroundColor $statusColor
            Write-Host "   Passed: $tierPassed" -ForegroundColor Green
            Write-Host "   Failed: $tierFailed" -ForegroundColor $(if ($tierFailed -gt 0) { "Red" } else { "Gray" })
            Write-Host "   Skipped: $tierSkipped" -ForegroundColor Yellow
            Write-Host "   Duration: $($tierDuration.TotalSeconds.ToString("F2"))s" -ForegroundColor Gray
            
            if ($OutputFormat -ne 'Console') {
                Write-Host "   Output: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor Cyan
            }
            
            # Store tier result
            $overallResults += @{
                Tier = $tierName
                Passed = $tierPassed
                Failed = $tierFailed
                Skipped = $tierSkipped
                Duration = $tierDuration
                BlockOnFailure = $shouldBlock
                Success = ($tierFailed -eq 0)
                OutputPath = $pesterConfig.TestResult.OutputPath
            }
            
            # Handle failures based on tier policy
            if ($tierFailed -gt 0) {
                if ($shouldBlock) {
                    Write-Host "🚫 $tierName tier has failures and is configured to block - stopping execution" -ForegroundColor Red
                    throw "$tierName tier tests failed ($tierFailed failures) - execution blocked"
                } else {
                    Write-Host "⚠️  $tierName tier has failures but is configured as non-blocking - continuing" -ForegroundColor Yellow
                }
            }
            
            Write-Host ""
            
        } catch {
            Write-Host "❌ $tierName tier execution failed: $($_.Exception.Message)" -ForegroundColor Red
            
            $overallResults += @{
                Tier = $tierName
                Passed = 0
                Failed = 999  # Indicate execution failure
                Skipped = 0
                Duration = [TimeSpan]::Zero
                BlockOnFailure = $shouldBlock
                Success = $false
                Error = $_.Exception.Message
            }
            
            if ($shouldBlock) {
                throw
            }
        }
    }
    
    # Overall summary
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                           OVERALL TEST SUMMARY                        ║" -ForegroundColor Cyan  
    Write-Host "╠═══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    $overallSuccess = ($totalFailed -eq 0) -and ($overallResults | Where-Object { -not $_.Success }).Count -eq 0
    $summaryIcon = if ($overallSuccess) { "✅" } else { "❌" }
    $summaryColor = if ($overallSuccess) { "Green" } else { "Red" }
    
    Write-Host "║ Overall Status: $summaryIcon $(if ($overallSuccess) { 'PASSED' } else { 'FAILED' })" -ForegroundColor $summaryColor
    Write-Host "║ Total Passed:   $totalPassed" -ForegroundColor Green
    Write-Host "║ Total Failed:   $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { "Red" } else { "Gray" })
    Write-Host "║ Total Skipped:  $totalSkipped" -ForegroundColor Yellow
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "║ Tier Breakdown:" -ForegroundColor Cyan
    
    foreach ($tierResult in $overallResults) {
        $tierIcon = if ($tierResult.Success) { "✅" } elseif ($tierResult.BlockOnFailure) { "❌" } else { "⚠️" }
        $tierSummary = "$($tierResult.Tier): $tierIcon P:$($tierResult.Passed) F:$($tierResult.Failed) S:$($tierResult.Skipped)"
        Write-Host "║   $tierSummary" -ForegroundColor $(if ($tierResult.Success) { "Green" } elseif ($tierResult.BlockOnFailure) { "Red" } else { "Yellow" })
    }
    
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Return results if requested
    if ($PassThru) {
        return @{
            OverallSuccess = $overallSuccess
            TotalPassed = $totalPassed
            TotalFailed = $totalFailed
            TotalSkipped = $totalSkipped
            TierResults = $overallResults
            OutputPath = $OutputPath
        }
    }
    
    # Exit with appropriate code
    if (-not $overallSuccess) {
        $blockingFailures = $overallResults | Where-Object { -not $_.Success -and $_.BlockOnFailure }
        if ($blockingFailures) {
            Write-Host "Exiting with error code due to blocking tier failures" -ForegroundColor Red
            exit 1
        } else {
            Write-Host "All failures were in non-blocking tiers - exiting successfully" -ForegroundColor Yellow
            exit 0
        }
    }
}

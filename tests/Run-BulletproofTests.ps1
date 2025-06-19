#Requires -Version 7.0

<#
.SYNOPSIS
    Bulletproof test runner for comprehensive validation of the OpenTofu Lab Automation system

.DESCRIPTION
    This script orchestrates comprehensive bulletproof testing including:
    - Core runner validation
    - Module testing
    - Integration testing
    - Performance benchmarking
    - Error scenario testing
    - Cross-platform compatibility
    - Non-interactive mode validation
    - Exit code consistency

.PARAMETER TestSuite
    Which test suite to run: All, Core, Modules, Integration, Performance, Quick

.PARAMETER LogLevel
    Logging level: Silent, Normal, Detailed, Verbose

.PARAMETER GenerateReport
    Generate comprehensive HTML report

.PARAMETER CI
    Run in CI mode with optimized settings

.EXAMPLE
    .\Run-BulletproofTests.ps1 -TestSuite All -LogLevel Detailed -GenerateReport

.EXAMPLE
    .\Run-BulletproofTests.ps1 -TestSuite Quick -CI

.NOTES
    This is the master test runner for bulletproof validation
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('All', 'Core', 'Modules', 'Integration', 'Performance', 'Quick', 'NonInteractive')]
    [string]$TestSuite = 'All',

    [Parameter()]
    [ValidateSet('Silent', 'Normal', 'Detailed', 'Verbose')]
    [string]$LogLevel = 'Normal',

    [Parameter()]
    [switch]$GenerateReport,

    [Parameter()]
    [switch]$CI,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [string]$OutputPath = ""
)

$ErrorActionPreference = 'Stop'

# Set up environment
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
}

$projectRoot = $env:PROJECT_ROOT
$testsDir = Join-Path $projectRoot "tests"
$resultsDir = Join-Path $testsDir "results"
$bulletproofDir = Join-Path $resultsDir "bulletproof"

# Ensure directories exist
@($resultsDir, $bulletproofDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# Import required modules
try {
    Import-Module Pester -Force -MinimumVersion 5.0 -ErrorAction Stop
    Import-Module "$projectRoot/core-runner/modules/Logging" -Force -ErrorAction SilentlyContinue
} catch {
    Write-Error "Failed to import required modules: $_"
    exit 1
}

# Configure logging
function Write-BulletproofLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',
        [switch]$NoTimestamp
    )

    if ($LogLevel -eq 'Silent' -and $Level -ne 'ERROR') { return }

    $timestamp = if (-not $NoTimestamp) { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] " } else { "" }
    $prefix = switch ($Level) {
        'INFO' { "🔍" }
        'WARN' { "⚠️ " }
        'ERROR' { "❌" }
        'SUCCESS' { "✅" }
    }

    $color = switch ($Level) {
        'INFO' { 'Cyan' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        'SUCCESS' { 'Green' }
    }

    Write-Host "$timestamp$prefix $Message" -ForegroundColor $color
}

# Test suite configurations
$testSuites = @{
    'Quick' = @{
        Name = 'Quick Validation'
        Tests = @(
            'tests/unit/modules/CoreApp/NonInteractiveMode.Tests.ps1'
        )
        MaxDuration = 300  # 5 minutes
    }
    'Core' = @{
        Name = 'Core Runner Tests'
        Tests = @(
            'tests/unit/modules/CoreApp/BulletproofCoreRunner.Tests.ps1',
            'tests/unit/modules/CoreApp/NonInteractiveMode.Tests.ps1',
            'tests/unit/modules/CoreApp/CoreRunner.Tests.ps1'
        )
        MaxDuration = 600  # 10 minutes
    }
    'Modules' = @{
        Name = 'Module Tests'
        Tests = @(
            'tests/unit/modules/Logging',
            'tests/unit/modules/LabRunner',
            'tests/unit/modules/TestingFramework',
            'tests/unit/modules/ParallelExecution',
            'tests/unit/modules/BackupManager',
            'tests/unit/modules/ScriptManager'
        )
        MaxDuration = 900  # 15 minutes
    }
    'Integration' = @{
        Name = 'Integration Tests'
        Tests = @(
            'tests/integration',
            'tests/unit/modules/CoreApp/MasterBulletproofTests.Tests.ps1'
        )
        MaxDuration = 1200  # 20 minutes
    }
    'Performance' = @{
        Name = 'Performance Tests'
        Tests = @(
            'tests/performance'
        )
        MaxDuration = 1800  # 30 minutes
    }
    'NonInteractive' = @{
        Name = 'Non-Interactive Mode'
        Tests = @(
            'tests/unit/modules/CoreApp/NonInteractiveMode.Tests.ps1',
            'tests/unit/modules/CoreApp/BulletproofCoreRunner.Tests.ps1'
        )
        MaxDuration = 300  # 5 minutes
    }
    'All' = @{
        Name = 'Complete Bulletproof Suite'
        Tests = @(
            'tests/unit/modules/CoreApp',
            'tests/unit/modules/Logging',
            'tests/unit/modules/LabRunner',
            'tests/unit/modules/TestingFramework',
            'tests/integration',
            'tests/system'
        )
        MaxDuration = 2400  # 40 minutes
    }
}

Write-BulletproofLog "🚀 Starting Bulletproof Test Suite: $TestSuite" -Level SUCCESS
Write-BulletproofLog "📂 Project Root: $projectRoot" -Level INFO
Write-BulletproofLog "📊 Log Level: $LogLevel" -Level INFO
Write-BulletproofLog "🔧 CI Mode: $CI" -Level INFO

# Get test configuration
$selectedSuite = $testSuites[$TestSuite]
if (-not $selectedSuite) {
    Write-BulletproofLog "Invalid test suite: $TestSuite" -Level ERROR
    exit 1
}

Write-BulletproofLog "🎯 Test Suite: $($selectedSuite.Name)" -Level INFO
Write-BulletproofLog "⏱️  Max Duration: $($selectedSuite.MaxDuration) seconds" -Level INFO

# Create Pester configuration
$pesterConfig = @{
    Run = @{
        Path = $selectedSuite.Tests | ForEach-Object { Join-Path $projectRoot $_ }
        Exit = $false
        PassThru = $true
        Throw = $false
    }
    Filter = @{
        Tag = @('Bulletproof', 'Unit', 'Integration', 'CoreApp', 'NonInteractive')
        ExcludeTag = if ($CI) { @('Slow', 'Interactive') } else { @() }
    }
    Output = @{
        Verbosity = switch ($LogLevel) {
            'Silent' { 'Minimal' }
            'Normal' { 'Normal' }
            'Detailed' { 'Detailed' }
            'Verbose' { 'Diagnostic' }
        }
        CIFormat = if ($CI) { 'GithubActions' } else { 'None' }
        StackTraceVerbosity = if ($LogLevel -in @('Detailed', 'Verbose')) { 'Full' } else { 'Filtered' }
    }
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = Join-Path $bulletproofDir "BulletproofResults-$TestSuite-$(Get-Date -Format 'yyyyMMddHHmmss').xml"
        TestSuiteName = "OpenTofu Lab Automation - Bulletproof $TestSuite Tests"
    }
    CodeCoverage = @{
        Enabled = ($TestSuite -in @('Core', 'All') -and -not $CI)
        Path = @(
            'core-runner/core_app/core-runner.ps1',
            'core-runner/core_app/CoreApp.psm1',
            'core-runner/modules/*/Public/*.ps1',
            'core-runner/modules/*/*.psm1'
        ) | ForEach-Object { Join-Path $projectRoot $_ }
        OutputFormat = 'JaCoCo'
        OutputPath = Join-Path $bulletproofDir "BulletproofCoverage-$TestSuite-$(Get-Date -Format 'yyyyMMddHHmmss').xml"
    }
    Should = @{
        ErrorAction = 'Stop'
    }
    Debug = @{
        ShowFullErrors = ($LogLevel -in @('Detailed', 'Verbose'))
        WriteDebugMessages = ($LogLevel -eq 'Verbose')
        WriteDebugMessagesFrom = @('Bulletproof', 'CoreApp', 'NonInteractive')
    }
}

# Convert to Pester configuration object
try {
    $config = New-PesterConfiguration -Hashtable $pesterConfig
} catch {
    Write-BulletproofLog "Failed to create Pester configuration: $_" -Level ERROR
    exit 1
}

# Start test execution
$startTime = Get-Date
Write-BulletproofLog "🏁 Starting test execution at $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Level SUCCESS

# Set timeout for test execution
$timeoutSeconds = $selectedSuite.MaxDuration
$testJob = Start-Job -ScriptBlock {
    param($Config)
    Invoke-Pester -Configuration $Config
} -ArgumentList $config

$completed = $false
try {
    # Wait for completion or timeout
    $testResult = Wait-Job $testJob -Timeout $timeoutSeconds | Receive-Job
    $completed = $true
} catch {
    Write-BulletproofLog "Test execution failed: $_" -Level ERROR
    $testResult = $null
} finally {
    if (-not $completed) {
        Write-BulletproofLog "Test execution timed out after $timeoutSeconds seconds" -Level ERROR
        Remove-Job $testJob -Force
    }
}

$endTime = Get-Date
$totalDuration = $endTime - $startTime

# Process results
if ($testResult) {
    Write-BulletproofLog "📊 Test Execution Summary:" -Level SUCCESS
    Write-BulletproofLog "  ⏱️  Duration: $($totalDuration.ToString('mm\:ss'))" -Level INFO
    Write-BulletproofLog "  📋 Total Tests: $($testResult.TotalCount)" -Level INFO
    Write-BulletproofLog "  ✅ Passed: $($testResult.PassedCount)" -Level SUCCESS
    Write-BulletproofLog "  ❌ Failed: $($testResult.FailedCount)" -Level $(if ($testResult.FailedCount -gt 0) { 'ERROR' } else { 'INFO' })
    Write-BulletproofLog "  ⏭️  Skipped: $($testResult.SkippedCount)" -Level INFO
    Write-BulletproofLog "  🚫 Not Run: $($testResult.NotRunCount)" -Level INFO

    # Calculate success rate
    $successRate = if ($testResult.TotalCount -gt 0) {
        ($testResult.PassedCount / $testResult.TotalCount) * 100
    } else { 0 }

    Write-BulletproofLog "  🎯 Success Rate: $($successRate.ToString('F1'))%" -Level $(
        if ($successRate -ge 95) { 'SUCCESS' }
        elseif ($successRate -ge 80) { 'WARN' }
        else { 'ERROR' }
    )

    # Show failed tests if any
    if ($testResult.FailedCount -gt 0) {
        Write-BulletproofLog "❌ Failed Tests:" -Level ERROR
        $testResult.Failed | ForEach-Object {
            Write-BulletproofLog "  • $($_.ExpandedName)" -Level ERROR -NoTimestamp
            if ($LogLevel -in @('Detailed', 'Verbose')) {
                Write-BulletproofLog "    $($_.ErrorRecord.Exception.Message)" -Level ERROR -NoTimestamp
            }
        }
    }

    # Code coverage summary
    if ($config.CodeCoverage.Enabled -and $testResult.CodeCoverage) {
        $coverage = $testResult.CodeCoverage
        $coveragePercent = if ($coverage.NumberOfCommandsAnalyzed -gt 0) {
            ($coverage.NumberOfCommandsExecuted / $coverage.NumberOfCommandsAnalyzed) * 100
        } else { 0 }

        Write-BulletproofLog "📈 Code Coverage: $($coveragePercent.ToString('F1'))%" -Level $(
            if ($coveragePercent -ge 80) { 'SUCCESS' }
            elseif ($coveragePercent -ge 60) { 'WARN' }
            else { 'ERROR' }
        )
        Write-BulletproofLog "  📋 Commands Analyzed: $($coverage.NumberOfCommandsAnalyzed)" -Level INFO
        Write-BulletproofLog "  ✅ Commands Executed: $($coverage.NumberOfCommandsExecuted)" -Level INFO
        Write-BulletproofLog "  ❌ Commands Missed: $($coverage.NumberOfCommandsMissed)" -Level INFO
    }

} else {
    Write-BulletproofLog "Test execution failed or timed out" -Level ERROR
    $successRate = 0
}

# Generate HTML report if requested
if ($GenerateReport -and $testResult) {
    Write-BulletproofLog "📄 Generating HTML report..." -Level INFO

    $reportPath = Join-Path $bulletproofDir "BulletproofReport-$TestSuite-$(Get-Date -Format 'yyyyMMddHHmmss').html"

    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Bulletproof Test Report - $TestSuite</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .success { color: #28a745; }
        .warning { color: #ffc107; }
        .error { color: #dc3545; }
        .metric { display: inline-block; margin: 10px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        .failed-test { background: #f8d7da; padding: 5px; margin: 5px 0; border-radius: 3px; }
        .test-details { font-family: monospace; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Bulletproof Test Report</h1>
        <h2>Test Suite: $($selectedSuite.Name)</h2>
        <p><strong>Execution Time:</strong> $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) - $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))</p>
        <p><strong>Duration:</strong> $($totalDuration.ToString('mm\:ss'))</p>
    </div>

    <div class="metrics">
        <div class="metric">
            <h3>Total Tests</h3>
            <div style="font-size: 24px;">$($testResult.TotalCount)</div>
        </div>
        <div class="metric success">
            <h3>Passed</h3>
            <div style="font-size: 24px;">$($testResult.PassedCount)</div>
        </div>
        <div class="metric error">
            <h3>Failed</h3>
            <div style="font-size: 24px;">$($testResult.FailedCount)</div>
        </div>
        <div class="metric">
            <h3>Success Rate</h3>
            <div style="font-size: 24px;" class="$(if ($successRate -ge 95) { 'success' } elseif ($successRate -ge 80) { 'warning' } else { 'error' })">$($successRate.ToString('F1'))%</div>
        </div>
    </div>

    $(if ($testResult.FailedCount -gt 0) {
        "<h2>Failed Tests</h2>" +
        ($testResult.Failed | ForEach-Object {
            "<div class='failed-test'><strong>$($_.ExpandedName)</strong><br/><div class='test-details'>$($_.ErrorRecord.Exception.Message)</div></div>"
        }) -join ""
    })

    <h2>Test Configuration</h2>
    <div class="test-details">
        <p><strong>Tests Included:</strong></p>
        <ul>
        $(($selectedSuite.Tests | ForEach-Object { "<li>$_</li>" }) -join "")
        </ul>
        <p><strong>Filters:</strong> $($config.Filter.Tag -join ', ')</p>
        <p><strong>Log Level:</strong> $LogLevel</p>
        <p><strong>CI Mode:</strong> $CI</p>
    </div>

    <div style="margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 5px;">
        <h3>🎯 Bulletproof Status</h3>
        $(if ($successRate -ge 95) {
            "<p class='success'>✅ <strong>BULLETPROOF</strong> - All systems validated and ready for production</p>"
        } elseif ($successRate -ge 80) {
            "<p class='warning'>⚠️ <strong>MOSTLY BULLETPROOF</strong> - Minor issues detected, review recommended</p>"
        } else {
            "<p class='error'>❌ <strong>NOT BULLETPROOF</strong> - Critical issues detected, remediation required</p>"
        })
    </div>

    <footer style="margin-top: 50px; text-align: center; color: #666;">
        <p>Generated by OpenTofu Lab Automation Bulletproof Test Runner</p>
        <p>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </footer>
</body>
</html>
"@

    $htmlReport | Out-File -FilePath $reportPath -Encoding UTF8
    Write-BulletproofLog "📄 HTML report saved to: $reportPath" -Level SUCCESS
}

# Output results files
Write-BulletproofLog "📂 Test Results:" -Level SUCCESS
if ($config.TestResult.Enabled) {
    Write-BulletproofLog "  📄 XML Results: $($config.TestResult.OutputPath)" -Level INFO
}
if ($config.CodeCoverage.Enabled) {
    Write-BulletproofLog "  📊 Coverage Report: $($config.CodeCoverage.OutputPath)" -Level INFO
}

# Set exit code based on results
$exitCode = if ($testResult -and $testResult.FailedCount -eq 0) { 0 } else { 1 }

# Final status
Write-BulletproofLog "🏁 Bulletproof Testing Complete" -Level SUCCESS
Write-BulletproofLog "🚀 Final Status: $(if ($exitCode -eq 0) { 'BULLETPROOF ✅' } else { 'ISSUES DETECTED ❌' })" -Level $(if ($exitCode -eq 0) { 'SUCCESS' } else { 'ERROR' })

# Output structured data for CI/CD
if ($CI -or $OutputPath) {
    $outputData = @{
        TestSuite = $TestSuite
        StartTime = $startTime
        EndTime = $endTime
        Duration = $totalDuration.TotalSeconds
        TotalTests = if ($testResult) { $testResult.TotalCount } else { 0 }
        PassedTests = if ($testResult) { $testResult.PassedCount } else { 0 }
        FailedTests = if ($testResult) { $testResult.FailedCount } else { 1 }
        SkippedTests = if ($testResult) { $testResult.SkippedCount } else { 0 }
        SuccessRate = $successRate
        ExitCode = $exitCode
        Bulletproof = ($exitCode -eq 0 -and $successRate -ge 95)
        ResultsFile = $config.TestResult.OutputPath
        CoverageFile = if ($config.CodeCoverage.Enabled) { $config.CodeCoverage.OutputPath } else { $null }
        HtmlReport = if ($GenerateReport) { $reportPath } else { $null }
    }

    $outputPath = if ($OutputPath) { $OutputPath } else { Join-Path $bulletproofDir "bulletproof-output.json" }
    $outputData | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputPath -Encoding UTF8
    Write-BulletproofLog "📊 Structured output saved to: $outputPath" -Level INFO
}

exit $exitCode

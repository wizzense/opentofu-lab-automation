#!/usr/bin/env pwsh
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
<#
.SYNOPSIS
    Master test and lint runner for OpenTofu Lab Automation project.

.DESCRIPTION
    This script runs both Pester (PowerShell) and pytest (Python) test suites,
    plus PSScriptAnalyzer and Python linting, using parallel execution based
    on CPU core count for optimal performance.

.PARAMETER TestSuite
    Specify which test suite to run: 'All', 'Test', 'Lint', 'Pester', 'Python'

.PARAMETER Detailed
    Show detailed output for all tests

.PARAMETER MaxConcurrency
    Override maximum concurrent jobs (defaults to CPU core count)

.PARAMETER NoLinting
    Skip linting and only run tests

.PARAMETER LintOnly
    Only run linting, skip tests

.EXAMPLE
    .\Run-AllTests.ps1
    Run all test suites and linting with parallel execution

.EXAMPLE
    .\Run-AllTests.ps1 -TestSuite Test -Detailed
    Run only tests with detailed output

.EXAMPLE
    .\Run-AllTests.ps1 -LintOnly
    Run only linting tasks
#>

param(
    [ValidateSet('All', 'Test', 'Lint', 'Pester', 'Python')]
    [string]$TestSuite = 'All',
    
    [switch]$Detailed,
    
    [int]$MaxConcurrency = [Environment]::ProcessorCount,
    
    [switch]$NoLinting,
    
    [switch]$LintOnly
)

# Test configuration
$ErrorActionPreference = 'Stop'
$PesterPath = './tests/pester'
$PytestPath = './tests/pytest'
$PythonExe = './.venv/Scripts/python.exe'

# Import existing logging module
$loggingModulePath = Join-Path $env:PWSH_MODULES_PATH "Logging"
if (Test-Path $loggingModulePath) {
    try {
        Import-Module $loggingModulePath -Force
        if (Get-Command "Initialize-LoggingSystem" -ErrorAction SilentlyContinue) {
            Initialize-LoggingSystem -LogLevel "INFO" -ConsoleLevel "INFO" -EnablePerformance
        }
    } catch {
        Write-Warning "Could not initialize advanced logging: $($_.Exception.Message)"
    }
} 

# Fallback logging function if advanced logging fails
if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        param($Message, $Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "SUCCESS" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "Cyan" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

# Fallback performance tracking functions
if (-not (Get-Command "Start-PerformanceTrace" -ErrorAction SilentlyContinue)) {
    $script:PerformanceCounters = @{}
    function Start-PerformanceTrace { 
        param($OperationName)
        $script:PerformanceCounters[$OperationName] = Get-Date
    }
    function Stop-PerformanceTrace { 
        param($OperationName)
        if ($script:PerformanceCounters[$OperationName]) {
            $duration = (Get-Date) - $script:PerformanceCounters[$OperationName]
            Write-CustomLog "Performance: $OperationName completed in $($duration.TotalSeconds.ToString('F2'))s" -Level DEBUG
            $script:PerformanceCounters.Remove($OperationName)
        }
    }
}

# Import parallel execution module
$parallelModulePath = './src/pwsh/modules/ParallelExecution/ParallelExecution.psm1'
if (Test-Path $parallelModulePath) {
    Import-Module $parallelModulePath -Force
} else {
    Write-CustomLog "ParallelExecution module not found, using single-threaded execution" -Level WARN
}

# Ensure we're in the project root
if (-not (Test-Path './src') -or -not (Test-Path './tests')) {
    Write-CustomLog "Please run this script from the project root directory" -Level ERROR
    exit 1
}

# Initialize results tracking
$Results = @{
    TestResults = $null
    LintResults = $null
    StartTime = Get-Date
    Success = $true
}

Write-CustomLog "OpenTofu Lab Automation - Scientific Test and Lint Runner" -Level INFO
Write-CustomLog "Test Suite: $TestSuite, CPU Cores: $MaxConcurrency" -Level INFO
Write-CustomLog "Mode: $(if ($LintOnly) { 'Lint Only' } elseif ($NoLinting) { 'Tests Only' } else { 'Tests + Linting' })" -Level INFO
Write-CustomLog "Started: $($Results.StartTime)" -Level INFO

# Function to create test tasks
function New-TestTasks {
    $testTasks = @()
    
    if ($TestSuite -eq 'All' -or $TestSuite -eq 'Test' -or $TestSuite -eq 'Pester') {
        # Add Pester test files
        Get-ChildItem $PesterPath -Filter "*.Tests.ps1" | ForEach-Object {
            $testTasks += @{ 
                Type = 'Pester'; 
                Path = $_.FullName; 
                Name = $_.Name 
            }
        }
    }
    
    if ($TestSuite -eq 'All' -or $TestSuite -eq 'Test' -or $TestSuite -eq 'Python') {
        # Add Python test files
        Get-ChildItem $PytestPath -Filter "test_*.py" | ForEach-Object {
            $testTasks += @{ 
                Type = 'Pytest'; 
                Path = $_.FullName; 
                Name = $_.Name 
            }
        }
    }
    
    return $testTasks
}

# Function to create lint tasks
function New-LintTasks {
    $lintTasks = @()
    
    if ($TestSuite -eq 'All' -or $TestSuite -eq 'Lint') {
        # Add PowerShell lint tasks
        Get-ChildItem -Path './src/pwsh' -Filter "*.ps1" -Recurse | ForEach-Object {
            $lintTasks += @{ 
                Type = 'PSScriptAnalyzer'; 
                Path = $_.FullName; 
                Name = $_.Name 
            }
        }
        
        # Add Python lint task if Python files exist
        if (Get-ChildItem -Path './src/python' -Filter "*.py" -Recurse -ErrorAction SilentlyContinue) {
            $lintTasks += @{ 
                Type = 'Pylint'; 
                Path = './src/python'; 
                Name = 'Python Linting' 
            }
        }
    }
    
    return $lintTasks
}

# Function to analyze test result files
function Get-TestResultSummary {
    param(
        [string]$ResultsPath = "tests/results",
        [string]$CoveragePath = "coverage"
    )
    
    $summary = @{
        PesterResults = $null
        PytestResults = $null
        CoverageResults = $null
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        SkippedTests = 0
        TestFiles = @()
        Issues = @()
    }
    
    # Ensure results directories exist
    @($ResultsPath, $CoveragePath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
        }
    }
    
    # Parse Pester NUnit XML results
    $pesterXmlPath = Join-Path $CoveragePath "testResults.xml"
    if (Test-Path $pesterXmlPath) {
        Write-CustomLog "Analyzing Pester test results from: $pesterXmlPath" -Level INFO
        try {
            [xml]$pesterXml = Get-Content $pesterXmlPath
            $testSuite = $pesterXml.'test-results'.'test-suite'
            
            $summary.PesterResults = @{
                Total = [int]$testSuite.total
                Executed = [int]$testSuite.executed
                Success = [int]$testSuite.success
                Failures = [int]$testSuite.failures
                Errors = [int]$testSuite.errors
                Skipped = [int]$testSuite.skipped
                Duration = [double]$testSuite.time
            }
            
            $summary.TotalTests += $summary.PesterResults.Total
            $summary.PassedTests += $summary.PesterResults.Success
            $summary.FailedTests += ($summary.PesterResults.Failures + $summary.PesterResults.Errors)
            $summary.SkippedTests += $summary.PesterResults.Skipped
            
            # Extract individual test failures
            $testSuite.'test-suite'.results.'test-case' | Where-Object { $_.result -eq 'Failure' } | ForEach-Object {
                $summary.Issues += @{
                    Type = 'Pester Test Failure'
                    Test = $_.name
                    Message = $_.failure.message
                    StackTrace = $_.failure.'stack-trace'
                }
            }
            
        } catch {
            Write-CustomLog "Failed to parse Pester XML results: $($_.Exception.Message)" -Level ERROR
        }
    }
    
    # Parse pytest JSON results
    $pytestJsonPath = Join-Path $ResultsPath "pytest_results.json"
    if (Test-Path $pytestJsonPath) {
        Write-CustomLog "Analyzing pytest results from: $pytestJsonPath" -Level INFO
        try {
            $pytestJson = Get-Content $pytestJsonPath | ConvertFrom-Json
            
            $summary.PytestResults = @{
                Total = $pytestJson.summary.total
                Passed = $pytestJson.summary.passed
                Failed = $pytestJson.summary.failed
                Skipped = $pytestJson.summary.skipped
                Errors = $pytestJson.summary.error
                Duration = $pytestJson.duration
            }
            
            $summary.TotalTests += $summary.PytestResults.Total
            $summary.PassedTests += $summary.PytestResults.Passed
            $summary.FailedTests += ($summary.PytestResults.Failed + $summary.PytestResults.Errors)
            $summary.SkippedTests += $summary.PytestResults.Skipped
            
            # Extract individual test failures
            $pytestJson.tests | Where-Object { $_.outcome -in @('failed', 'error') } | ForEach-Object {
                $summary.Issues += @{
                    Type = 'Pytest Test Failure'
                    Test = $_.nodeid
                    Message = $_.call.longrepr.reprcrash.message
                    StackTrace = $_.call.longrepr.reprtraceback.reprentries[-1].lines -join "`n"
                }
            }
            
        } catch {
            Write-CustomLog "Failed to parse pytest JSON results: $($_.Exception.Message)" -Level ERROR
        }
    }
    
    # Parse coverage results
    $coverageXmlPath = Join-Path $CoveragePath "coverage.xml"
    if (Test-Path $coverageXmlPath) {
        Write-CustomLog "Analyzing coverage results from: $coverageXmlPath" -Level INFO
        try {
            [xml]$coverageXml = Get-Content $coverageXmlPath
            $summary.CoverageResults = @{
                LineRate = [double]$coverageXml.coverage.'line-rate'
                BranchRate = [double]$coverageXml.coverage.'branch-rate'
                LinesValid = [int]$coverageXml.coverage.'lines-valid'
                LinesCovered = [int]$coverageXml.coverage.'lines-covered'
                BranchesValid = [int]$coverageXml.coverage.'branches-valid'
                BranchesCovered = [int]$coverageXml.coverage.'branches-covered'
            }
        } catch {
            Write-CustomLog "Failed to parse coverage XML results: $($_.Exception.Message)" -Level ERROR
        }
    }
    
    # Collect result file information
    Get-ChildItem -Path $ResultsPath -Filter "*.*" -ErrorAction SilentlyContinue | ForEach-Object {
        $summary.TestFiles += @{
            Name = $_.Name
            Path = $_.FullName
            Size = $_.Length
            LastModified = $_.LastWriteTime
        }
    }
    
    Get-ChildItem -Path $CoveragePath -Filter "*.*" -ErrorAction SilentlyContinue | ForEach-Object {
        $summary.TestFiles += @{
            Name = $_.Name
            Path = $_.FullName
            Size = $_.Length
            LastModified = $_.LastWriteTime
        }
    }
    
    return $summary
}

# Execute test suites and linting based on parameters
if (-not $LintOnly) {
    $testTasks = New-TestTasks
    if ($testTasks.Count -gt 0) {
        Write-CustomLog "Executing $($testTasks.Count) test tasks in parallel" -Level INFO
        $Results.TestResults = Invoke-ParallelTaskExecution -Tasks $testTasks -TaskType 'Test' -MaxConcurrency $MaxConcurrency -ShowProgress
        
        if (-not $Results.TestResults.Success) {
            $Results.Success = $false
        }
    } else {
        Write-CustomLog "No test tasks found for the specified criteria" -Level WARN
    }
}

if (-not $NoLinting) {
    $lintTasks = New-LintTasks
    if ($lintTasks.Count -gt 0) {
        Write-CustomLog "Executing $($lintTasks.Count) linting tasks in parallel" -Level INFO
        $Results.LintResults = Invoke-ParallelTaskExecution -Tasks $lintTasks -TaskType 'Lint' -MaxConcurrency $MaxConcurrency -ShowProgress
        
        if (-not $Results.LintResults.Success) {
            $Results.Success = $false
        }
    } else {
        Write-CustomLog "No lint tasks found for the specified criteria" -Level WARN
    }
}

# Analyze detailed test results from output files
Write-CustomLog "Analyzing test result files..." -Level INFO
$DetailedResults = Get-TestResultSummary

# Display final summary
$EndTime = Get-Date
$Duration = $EndTime - $Results.StartTime

Write-CustomLog "Analysis Summary" -Level INFO
Write-CustomLog "===============" -Level INFO

if ($Results.TestResults) {
    Write-CustomLog "Test Execution:" -Level INFO
    Write-CustomLog "  Total Tasks: $($Results.TestResults.TotalTasks)" -Level INFO
    Write-CustomLog "  Successful: $($Results.TestResults.SuccessfulTasks)" -Level $(if ($Results.TestResults.FailedTasks -eq 0) { 'SUCCESS' } else { 'WARN' })
    Write-CustomLog "  Failed: $($Results.TestResults.FailedTasks)" -Level $(if ($Results.TestResults.FailedTasks -eq 0) { 'SUCCESS' } else { 'ERROR' })
    Write-CustomLog "  Duration: $($Results.TestResults.Duration.TotalSeconds.ToString('F2'))s" -Level INFO
}

if ($Results.LintResults) {
    Write-CustomLog "Linting:" -Level INFO
    Write-CustomLog "  Total Tasks: $($Results.LintResults.TotalTasks)" -Level INFO
    Write-CustomLog "  Successful: $($Results.LintResults.SuccessfulTasks)" -Level $(if ($Results.LintResults.FailedTasks -eq 0) { 'SUCCESS' } else { 'WARN' })
    Write-CustomLog "  Failed: $($Results.LintResults.FailedTasks)" -Level $(if ($Results.LintResults.FailedTasks -eq 0) { 'SUCCESS' } else { 'ERROR' })
    Write-CustomLog "  Duration: $($Results.LintResults.Duration.TotalSeconds.ToString('F2'))s" -Level INFO
}

# Display detailed test results if available
if ($DetailedResults.TotalTests -gt 0) {
    Write-CustomLog "Detailed Test Results:" -Level INFO
    Write-CustomLog "  Total Tests: $($DetailedResults.TotalTests)" -Level INFO
    Write-CustomLog "  Passed: $($DetailedResults.PassedTests)" -Level $(if ($DetailedResults.FailedTests -eq 0) { 'SUCCESS' } else { 'WARN' })
    Write-CustomLog "  Failed: $($DetailedResults.FailedTests)" -Level $(if ($DetailedResults.FailedTests -eq 0) { 'SUCCESS' } else { 'ERROR' })
    Write-CustomLog "  Skipped: $($DetailedResults.SkippedTests)" -Level INFO
    
    if ($DetailedResults.PesterResults) {
        Write-CustomLog "  Pester: $($DetailedResults.PesterResults.Success)/$($DetailedResults.PesterResults.Total) passed" -Level INFO
    }
    
    if ($DetailedResults.PytestResults) {
        Write-CustomLog "  Pytest: $($DetailedResults.PytestResults.Passed)/$($DetailedResults.PytestResults.Total) passed" -Level INFO
    }
    
    if ($DetailedResults.CoverageResults) {
        $coveragePercent = ($DetailedResults.CoverageResults.LineRate * 100).ToString('F1')
        Write-CustomLog "  Code Coverage: $coveragePercent%" -Level INFO
    }
}

# Display test result files
if ($DetailedResults.TestFiles.Count -gt 0) {
    Write-CustomLog "Test Result Files:" -Level INFO
    $DetailedResults.TestFiles | ForEach-Object {
        Write-CustomLog "  $($_.Name) ($($_.Size) bytes) - $($_.LastModified)" -Level INFO
    }
}

# Display detailed failure information
if ($DetailedResults.Issues.Count -gt 0 -and $Detailed) {
    Write-CustomLog "Test Failure Details:" -Level ERROR
    $DetailedResults.Issues | ForEach-Object {
        Write-CustomLog "  [$($_.Type)] $($_.Test)" -Level ERROR
        Write-CustomLog "    Message: $($_.Message)" -Level ERROR
        if ($_.StackTrace) {
            Write-CustomLog "    Stack: $($_.StackTrace -split "`n" | Select-Object -First 3 -join "; ")" -Level ERROR
        }
    }
} elseif ($DetailedResults.Issues.Count -gt 0) {
    Write-CustomLog "Test Failures Detected: $($DetailedResults.Issues.Count) issues (use -Detailed for full report)" -Level ERROR
}

Write-CustomLog "Total Duration: $($Duration.TotalSeconds.ToString('F2')) seconds" -Level INFO

# Overall status - consider detailed results
$overallSuccess = $Results.Success -and ($DetailedResults.FailedTests -eq 0)

if ($overallSuccess) {
    Write-CustomLog "ALL TESTS COMPLETED SUCCESSFULLY" -Level SUCCESS
    exit 0
} else {
    Write-CustomLog "TEST FAILURES DETECTED" -Level ERROR
    exit 1
}

#Requires -Version 7.0

<#
.SYNOPSIS
    Multiprocessing test and linting runner for OpenTofu Lab Automation

.DESCRIPTION
    Executes tests and linting in parallel batches based on CPU core count.
    Integrates PSScriptAnalyzer for PowerShell and Python linting tools.
    Uses existing centralized logging system.

.PARAMETER MaxJobs
    Maximum number of parallel jobs (defaults to CPU core count)

.PARAMETER TestType
    Type of tests to run: All, Pester, Python, Lint

.PARAMETER Detailed
    Show detailed output for all operations
#>

param(
    [int]$MaxJobs = [System.Environment]::ProcessorCount,
    
    [ValidateSet('All', 'Pester', 'Python', 'Lint', 'Setup')]
    [string]$TestType = 'All',
    
    [switch]$Detailed
)

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
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
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
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
        $script:PerformanceCounters[$OperationName] = Get-Date
    }
    function Stop-PerformanceTrace { 
        param($OperationName)
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
        if ($script:PerformanceCounters[$OperationName]) {
            $duration = (Get-Date) - $script:PerformanceCounters[$OperationName]
            Write-CustomLog "Performance: $OperationName completed in $($duration.TotalSeconds.ToString('F2'))s" -Level DEBUG
            $script:PerformanceCounters.Remove($OperationName)
        }
    }
}

Write-CustomLog "OpenTofu Lab Automation - Multiprocessing Test Runner" -Level INFO
Write-CustomLog "CPU Cores: $([System.Environment]::ProcessorCount), Max Jobs: $MaxJobs" -Level INFO

# Test configuration
$config = @{
    PesterPath = './tests/pester'
    PytestPath = './tests/pytest' 
    PythonExe = './.venv/Scripts/python.exe'
    MaxJobs = $MaxJobs
    StartTime = Get-Date
}

# Results tracking
$script:Results = @{
    PesterTests = @{ Passed = 0; Failed = 0; Total = 0; Duration = 0 }
    PythonTests = @{ Passed = 0; Failed = 0; Total = 0; Duration = 0 }
    PowerShellLint = @{ Passed = 0; Failed = 0; Total = 0; Duration = 0 }
    PythonLint = @{ Passed = 0; Failed = 0; Total = 0; Duration = 0 }
}

function Get-PowerShellFiles {
    return Get-ChildItem -Recurse -Include "*.ps1", "*.psm1" | 
           Where-Object { $_.FullName -notmatch "\\tests\\|\\archive\\|\\cleanup-" }
}

function Get-PythonFiles {
    return Get-ChildItem -Recurse -Include "*.py" | 
           Where-Object { $_.FullName -notmatch "\\tests\\|\\archive\\|\\cleanup-|\\.venv\\" }
}

function Split-ArrayIntoBatches {
    param(
        [array]$Array,
        [int]$BatchCount
    )
    
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
    if ($Array.Count -eq 0) { return @() }
    
    $batchSize = [Math]::Ceiling($Array.Count / $BatchCount)
    $batches = @()
    
    for ($i = 0; $i -lt $Array.Count; $i += $batchSize) {
        $end = [Math]::Min($i + $batchSize - 1, $Array.Count - 1)
        $batches += ,@($Array[$i..$end])
    }
    
    return $batches
}

function # Invoke-PowerShellLint deprecateding {
    param([switch]$Detailed)
    
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
    Write-CustomLog "Starting PowerShell linting with PSScriptAnalyzer" -Level INFO
    Start-PerformanceTrace -OperationName "PowerShellLinting"
    
    $psFiles = Get-PowerShellFiles
    Write-CustomLog "Found $($psFiles.Count) PowerShell files to analyze" -Level INFO
    
    if ($psFiles.Count -eq 0) {
        Write-CustomLog "No PowerShell files found for linting" -Level WARN
        return
    }
    
    # Split files into batches for parallel processing
    $batches = Split-ArrayIntoBatches -Array $psFiles -BatchCount $config.MaxJobs
    Write-CustomLog "Split into $($batches.Count) batches for parallel processing" -Level DEBUG
    
    $jobs = @()
    foreach ($batch in $batches) {
        $job = Start-Job -ScriptBlock {
            param($Files, $SettingsPath, $Detailed)
            
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
            $results = @{
                Passed = 0
                Failed = 0
                Issues = @()
            }
            
            foreach ($file in $Files) {
                try {
                    if ($SettingsPath -and (Test-Path $SettingsPath)) {
                        $issues = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $SettingsPath
                    } else {
                        $issues = Invoke-ScriptAnalyzer -Path $file.FullName
                    }
                    
                    if ($issues) {
                        $results.Failed++
                        $results.Issues += @{
                            File = $file.FullName
                            Issues = $issues
                        }
                    } else {
                        $results.Passed++
                    }
                } catch {
                    $results.Failed++
                    $results.Issues += @{
                        File = $file.FullName
                        Error = $_.Exception.Message
                    }
                }
            }
            
            return $results
        } -ArgumentList $batch, "./tests/PSScriptAnalyzerSettings.psd1", $Detailed
        
        $jobs += $job
    }
    
    # Wait for all jobs and collect results
    $allResults = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    # Aggregate results
    $totalPassed = ($allResults | Measure-Object -Property Passed -Sum).Sum
    $totalFailed = ($allResults | Measure-Object -Property Failed -Sum).Sum
    $allIssues = $allResults | ForEach-Object { $_.Issues }
    
    $script:Results.PowerShellLint.Passed = $totalPassed
    $script:Results.PowerShellLint.Failed = $totalFailed
    $script:Results.PowerShellLint.Total = $totalPassed + $totalFailed
    
    if ($Detailed -and $allIssues) {
        Write-CustomLog "PowerShell linting issues found:" -Level WARN
        foreach ($issueGroup in $allIssues) {
            $relativePath = $issueGroup.File -replace [regex]::Escape($PWD.Path), "."
            if ($issueGroup.Error) {
                Write-CustomLog "  $relativePath - ERROR: $($issueGroup.Error)" -Level ERROR
            } else {
                Write-CustomLog "  $relativePath - $($issueGroup.Issues.Count) issue(s)" -Level WARN
                foreach ($issue in $issueGroup.Issues) {
                    Write-CustomLog "    Line $($issue.Line): $($issue.RuleName) - $($issue.Message)" -Level WARN
                }
            }
        }
    }
    
    Stop-PerformanceTrace -OperationName "PowerShellLinting"
    $script:Results.PowerShellLint.Duration = (Get-Date) - $config.StartTime
    
    Write-CustomLog "PowerShell linting completed: $totalPassed passed, $totalFailed failed" -Level $(if ($totalFailed -eq 0) { "SUCCESS" } else { "WARN" })
}

function Invoke-PythonLinting {
    param([switch]$Detailed)
    
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
    Write-CustomLog "Starting Python linting" -Level INFO
    Start-PerformanceTrace -OperationName "PythonLinting"
    
    $pythonFiles = Get-PythonFiles
    Write-CustomLog "Found $($pythonFiles.Count) Python files to analyze" -Level INFO
    
    if ($pythonFiles.Count -eq 0) {
        Write-CustomLog "No Python files found for linting" -Level WARN
        return
    }
    
    # Check if Python linting tools are available
    $pythonExe = if (Test-Path $config.PythonExe) { $config.PythonExe } else { "python" }
    
    try {
        # Test flake8 availability
        $flake8Test = & $pythonExe -m flake8 --version 2>&1
        Write-CustomLog "Using flake8 for Python linting" -Level DEBUG
        
        # Split files into batches
        $batches = Split-ArrayIntoBatches -Array $pythonFiles -BatchCount $config.MaxJobs
        
        $jobs = @()
        foreach ($batch in $batches) {
            $job = Start-Job -ScriptBlock {
                param($Files, $PythonExe, $Detailed)
                
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
                $results = @{
                    Passed = 0
                    Failed = 0
                    Issues = @()
                }
                
                foreach ($file in $Files) {
                    try {
                        $output = & $PythonExe -m flake8 $file.FullName 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            $results.Passed++
                        } else {
                            $results.Failed++
                            $results.Issues += @{
                                File = $file.FullName
                                Output = $output
                            }
                        }
                    } catch {
                        $results.Failed++
                        $results.Issues += @{
                            File = $file.FullName
                            Error = $_.Exception.Message
                        }
                    }
                }
                
                return $results
            } -ArgumentList $batch, $pythonExe, $Detailed
            
            $jobs += $job
        }
        
        # Wait for all jobs and collect results
        $allResults = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        # Aggregate results
        $totalPassed = ($allResults | Measure-Object -Property Passed -Sum).Sum
        $totalFailed = ($allResults | Measure-Object -Property Failed -Sum).Sum
        $allIssues = $allResults | ForEach-Object { $_.Issues }
        
        $script:Results.PythonLint.Passed = $totalPassed
        $script:Results.PythonLint.Failed = $totalFailed
        $script:Results.PythonLint.Total = $totalPassed + $totalFailed
        
        if ($Detailed -and $allIssues) {
            Write-CustomLog "Python linting issues found:" -Level WARN
            foreach ($issueGroup in $allIssues) {
                $relativePath = $issueGroup.File -replace [regex]::Escape($PWD.Path), "."
                if ($issueGroup.Error) {
                    Write-CustomLog "  $relativePath - ERROR: $($issueGroup.Error)" -Level ERROR
                } else {
                    Write-CustomLog "  $relativePath" -Level WARN
                    $issueGroup.Output | ForEach-Object {
                        Write-CustomLog "    $_" -Level WARN
                    }
                }
            }
        }
        
        Write-CustomLog "Python linting completed: $totalPassed passed, $totalFailed failed" -Level $(if ($totalFailed -eq 0) { "SUCCESS" } else { "WARN" })
        
    } catch {
        Write-CustomLog "Python linting failed: $($_.Exception.Message)" -Level ERROR
        Write-CustomLog "Ensure flake8 is installed: pip install flake8" -Level INFO
    }
    
    Stop-PerformanceTrace -OperationName "PythonLinting"
    $script:Results.PythonLint.Duration = (Get-Date) - $config.StartTime
}

function Invoke-PesterTests {
    param([switch]$Detailed)
    
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
    Write-CustomLog "Starting Pester tests" -Level INFO
    Start-PerformanceTrace -OperationName "PesterTests"
    
    try {
        if ($Detailed) {
            $pesterResult = Invoke-Pester $config.PesterPath -Output Detailed -PassThru
        } else {
            $pesterResult = Invoke-Pester $config.PesterPath -Output Normal -PassThru
        }
        
        $script:Results.PesterTests.Passed = $pesterResult.PassedCount
        $script:Results.PesterTests.Failed = $pesterResult.FailedCount
        $script:Results.PesterTests.Total = $pesterResult.TotalCount
        
        Write-CustomLog "Pester tests completed: $($pesterResult.PassedCount)/$($pesterResult.TotalCount) passed" -Level $(if ($pesterResult.FailedCount -eq 0) { "SUCCESS" } else { "WARN" })
        
    } catch {
        Write-CustomLog "Pester tests failed: $($_.Exception.Message)" -Level ERROR
        $script:Results.PesterTests.Failed = 999
    }
    
    Stop-PerformanceTrace -OperationName "PesterTests"
    $script:Results.PesterTests.Duration = (Get-Date) - $config.StartTime
}

function Invoke-PythonTests {
    param([switch]$Detailed)
    
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
    Write-CustomLog "Starting Python tests" -Level INFO
    Start-PerformanceTrace -OperationName "PythonTests"
    
    try {
        $pythonExe = if (Test-Path $config.PythonExe) { $config.PythonExe } else { "python" }
        
        if ($Detailed) {
            $pytestOutput = & $pythonExe -m pytest $config.PytestPath -v --tb=short 2>&1
        } else {
            $pytestOutput = & $pythonExe -m pytest $config.PytestPath --tb=line 2>&1
        }
        
        # Parse pytest output
        $summaryLine = $pytestOutput | Where-Object { $_ -match '=+\s+(\d+)\s+passed' }
        if ($summaryLine -and $summaryLine -match '(\d+)\s+passed') {
            $script:Results.PythonTests.Passed = [int]$Matches[1]
        }
        
        if ($summaryLine -and $summaryLine -match '(\d+)\s+failed') {
            $script:Results.PythonTests.Failed = [int]$Matches[1]
        }
        
        $script:Results.PythonTests.Total = $script:Results.PythonTests.Passed + $script:Results.PythonTests.Failed
        
        if ($Detailed) {
            $pytestOutput | ForEach-Object { Write-CustomLog $_ -Level DEBUG }
        }
        
        Write-CustomLog "Python tests completed: $($script:Results.PythonTests.Passed)/$($script:Results.PythonTests.Total) passed" -Level $(if ($script:Results.PythonTests.Failed -eq 0) { "SUCCESS" } else { "WARN" })
        
    } catch {
        Write-CustomLog "Python tests failed: $($_.Exception.Message)" -Level ERROR
        $script:Results.PythonTests.Failed = 999
    }
    
    Stop-PerformanceTrace -OperationName "PythonTests"
    $script:Results.PythonTests.Duration = (Get-Date) - $config.StartTime
}

# Function to analyze test result files
function Get-TestResultSummary {
    param(
        [string]$ResultsPath = "tests/results",
        [string]$CoveragePath = "coverage"
    )
    
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
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

function Show-Summary {
    $endTime = Get-Date
    $totalDuration = $endTime - $config.StartTime
    
    # Analyze detailed test results from output files
    Write-CustomLog "Analyzing test result files..." -Level INFO
    $DetailedResults = Get-TestResultSummary
    
    Write-CustomLog "Test and Linting Summary" -Level INFO
    Write-CustomLog "========================" -Level INFO
    Write-CustomLog "PowerShell Tests: $($script:Results.PesterTests.Passed)/$($script:Results.PesterTests.Total) passed" -Level $(if ($script:Results.PesterTests.Failed -eq 0) { "SUCCESS" } else { "WARN" })
    Write-CustomLog "Python Tests:     $($script:Results.PythonTests.Passed)/$($script:Results.PythonTests.Total) passed" -Level $(if ($script:Results.PythonTests.Failed -eq 0) { "SUCCESS" } else { "WARN" })
    Write-CustomLog "PowerShell Lint:  $($script:Results.PowerShellLint.Passed)/$($script:Results.PowerShellLint.Total) passed" -Level $(if ($script:Results.PowerShellLint.Failed -eq 0) { "SUCCESS" } else { "WARN" })
    Write-CustomLog "Python Lint:      $($script:Results.PythonLint.Passed)/$($script:Results.PythonLint.Total) passed" -Level $(if ($script:Results.PythonLint.Failed -eq 0) { "SUCCESS" } else { "WARN" })
    
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
    
    Write-CustomLog "Total Duration:   $($totalDuration.TotalSeconds.ToString('F2')) seconds" -Level INFO
    
    $totalPassed = $script:Results.PesterTests.Passed + $script:Results.PythonTests.Passed + $script:Results.PowerShellLint.Passed + $script:Results.PythonLint.Passed
    $totalFailed = $script:Results.PesterTests.Failed + $script:Results.PythonTests.Failed + $script:Results.PowerShellLint.Failed + $script:Results.PythonLint.Failed
    $totalTests = $totalPassed + $totalFailed
    
    # Consider detailed results in overall success calculation
    $overallSuccess = ($totalFailed -eq 0 -and $totalPassed -gt 0) -and ($DetailedResults.FailedTests -eq 0)
    
    if ($overallSuccess) {
        Write-CustomLog "ALL CHECKS PASSED ($totalPassed/$totalTests)" -Level SUCCESS
        exit 0
    } else {
        Write-CustomLog "SOME CHECKS FAILED ($totalPassed/$totalTests passed, $totalFailed failed)" -Level ERROR
        exit 1
    }
}

# Main execution
try {
    Start-PerformanceTrace -OperationName "TotalExecution"
    
    switch ($TestType) {
        'Pester' { Invoke-PesterTests -Detailed:$Detailed }
        'Python' { Invoke-PythonTests -Detailed:$Detailed }
        'Lint' { 
            # Invoke-PowerShellLint deprecateding -Detailed:$Detailed
            Invoke-PythonLinting -Detailed:$Detailed
        }
        'All' {
            Invoke-PesterTests -Detailed:$Detailed
            Invoke-PythonTests -Detailed:$Detailed
            # Invoke-PowerShellLint deprecateding -Detailed:$Detailed
            Invoke-PythonLinting -Detailed:$Detailed
        }
    }
    
    Stop-PerformanceTrace -OperationName "TotalExecution"
    Show-Summary
    
} catch {
    Write-CustomLog "Critical error in test runner: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

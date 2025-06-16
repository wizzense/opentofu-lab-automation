#!/usr/bin/env pwsh
# Enhanced Parallel Pester Test Runner
# Provides faster test execution with parallel processing

CmdletBinding()
param(
 Parameter()
 string$TestPath = "./tests",
 
 Parameter()
 int$MaxConcurrency = Environment::ProcessorCount,
 
 Parameter()
 switch$CI,
 
 Parameter()
 string$OutputPath = "./coverage",
 
 Parameter()
 switch$EnableCodeCoverage,
 
 Parameter()
 ValidateSet('Normal', 'Detailed', 'Minimal')
 string$Verbosity = 'Normal'
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
 New-Item -ItemType Directory -Path $OutputPath -Force  Out-Null
}

Write-Host " Enhanced Parallel Pester Test Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Test Pester availability
if (-not (Get-Module -ListAvailable Pester)) {
 Write-Host " Installing Pester 5.7.1..." -ForegroundColor Yellow
 Install-Module Pester -RequiredVersion 5.7.1 -Force -Scope CurrentUser -SkipPublisherCheck
}

# Import required modules - ensure consistent Pester 5.7.1
Import-Module Pester -RequiredVersion 5.7.1 -Force
if (-not (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue)) {
 Write-Host " Installing ThreadJob module for parallel processing..." -ForegroundColor Yellow
 Install-Module ThreadJob -Force -Scope CurrentUser
 Import-Module ThreadJob -Force
}

# Discover test files
Write-Host " Discovering test files in: $TestPath" -ForegroundColor Blue
$testFiles = Get-ChildItem -Path $TestPath -Recurse -Filter "*.Tests.ps1"  Where-Object { $_.Name -notmatch '(integratione2e)' }

if ($testFiles.Count -eq 0) {
 Write-Warning "No test files found in $TestPath"
 exit 1
}

Write-Host " Found $($testFiles.Count) test files" -ForegroundColor Green
foreach ($file in $testFiles) {
 Write-Host " • $($file.Name)" -ForegroundColor Gray
}

# Group tests for parallel execution
$testGroups = @()
$groupSize = math::Max(1, math::Ceiling($testFiles.Count / $MaxConcurrency))

for ($i = 0; $i -lt $testFiles.Count; $i += $groupSize) {
 $group = $testFiles$i..(math::Min($i + $groupSize - 1, $testFiles.Count - 1))
 $testGroups += ,@($group)
}

Write-Host " Running tests in $($testGroups.Count) parallel groups (max concurrency: $MaxConcurrency)" -ForegroundColor Cyan

# Parallel execution script block
$testScriptBlock = {
 param($TestGroup, $CI, $EnableCodeCoverage, $Verbosity, $OutputPath)
  try {
 Import-Module Pester -RequiredVersion 5.7.1 -Force
 
 $results = @()
 
 foreach ($testFile in $TestGroup) {
 $testName = $testFile.BaseName
 $outputFile = Join-Path $OutputPath "$testName-results.xml"
 
 # Configure Pester
 $config = New-PesterConfiguration
 $config.Run.Path = $testFile.FullName
 $config.Output.Verbosity = $Verbosity
 $config.TestResult.Enabled = $true
 $config.TestResult.OutputPath = $outputFile
 $config.TestResult.OutputFormat = 'NUnitXml'
 
 if ($EnableCodeCoverage) {
 $config.CodeCoverage.Enabled = $true
 $config.CodeCoverage.OutputPath = Join-Path $OutputPath "$testName-coverage.xml"
 }
 
 if ($CI) {
 $config.Output.CIFormat = 'GithubActions'
 }
 
 # Run test
 $startTime = Get-Date
 $result = Invoke-Pester -Configuration $config
 $duration = (Get-Date) - $startTime
 
 $results += @{
 TestFile = $testFile.Name
 Passed = $result.PassedCount
 Failed = $result.FailedCount
 Skipped = $result.SkippedCount
 Duration = $duration.TotalSeconds
 Success = $result.FailedCount -eq 0
 }
 }
 
 return $results
 } catch {
 return @{
 Error = $_.Exception.Message
 TestFile = $TestGroup0.Name
 Success = $false
 }
 }
}

# Execute test groups in parallel
Write-Host " Starting parallel test execution..." -ForegroundColor Green

$jobs = @()
foreach ($group in $testGroups) {
 $job = Start-ThreadJob -ScriptBlock $testScriptBlock -ArgumentList $group, $CI.IsPresent, $EnableCodeCoverage.IsPresent, $Verbosity, $OutputPath
 $jobs += $job
}

# Monitor progress
$totalResults = @()
$completed = 0

while ($jobs.Count -gt 0) {
 $finishedJobs = $jobs  Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' }
 
 foreach ($job in $finishedJobs) {
 $jobResults = Receive-Job $job -ErrorAction SilentlyContinue
 if ($jobResults) {
 $totalResults += $jobResults
 }
 
 Remove-Job $job
 $jobs = $jobs  Where-Object { $_.Id -ne $job.Id }
 $completed++
 
 $percentComplete = math::Round(($completed / $testGroups.Count) * 100, 1)
 Write-Progress -Activity "Running Parallel Tests" -Status "$completed of $($testGroups.Count) groups completed" -PercentComplete $percentComplete
 }
 
 if ($jobs.Count -gt 0) {
 Start-Sleep -Milliseconds 500
 }
}

Write-Progress -Activity "Running Parallel Tests" -Completed

# Calculate summary statistics
$totalPassed = ($totalResults  Measure-Object -Property Passed -Sum).Sum
$totalFailed = ($totalResults  Measure-Object -Property Failed -Sum).Sum
$totalSkipped = ($totalResults  Measure-Object -Property Skipped -Sum).Sum
$totalDuration = ($totalResults  Measure-Object -Property Duration -Sum).Sum
$successfulTests = ($totalResults  Where-Object { $_.Success -eq $true }).Count
$failedTests = ($totalResults  Where-Object { $_.Success -eq $false }).Count

# Display results
Write-Host "`n Parallel Test Execution Results" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "PASS Passed: $totalPassed" -ForegroundColor Green
Write-Host "FAIL Failed: $totalFailed" -ForegroundColor Red
Write-Host "⏭ Skipped: $totalSkipped" -ForegroundColor Yellow
Write-Host " Duration: $(math::Round($totalDuration, 2)) seconds" -ForegroundColor Blue
Write-Host "� Test Files: $successfulTests successful, $failedTests failed" -ForegroundColor Cyan

# Performance comparison
$estimatedSequentialTime = ($totalResults  Measure-Object -Property Duration -Sum).Sum
$actualParallelTime = $totalDuration
$speedupRatio = if ($actualParallelTime -gt 0) { math::Round($estimatedSequentialTime / $actualParallelTime, 2) } else { 1 }

Write-Host "`n Performance Improvement" -ForegroundColor Magenta
Write-Host "Estimated Sequential Time: $(math::Round($estimatedSequentialTime, 2)) seconds" -ForegroundColor Gray
Write-Host "Actual Parallel Time: $(math::Round($actualParallelTime, 2)) seconds" -ForegroundColor Gray
Write-Host "Speedup Ratio: ${speedupRatio}x faster" -ForegroundColor Green

# Output detailed results if requested
if ($Verbosity -eq 'Detailed') {
 Write-Host "`n Detailed Test Results" -ForegroundColor Blue
 foreach ($result in $totalResults) {
 if ($result.Success) {
 Write-Host "PASS $($result.TestFile): $($result.Passed) passed, $($result.Failed) failed ($(math::Round($result.Duration, 2))s)" -ForegroundColor Green
 } else {
 Write-Host "FAIL $($result.TestFile): ERROR - $($result.Error)" -ForegroundColor Red
 }
 }
}

# Merge test results into a single file
$combinedResultsPath = Join-Path $OutputPath "combined-test-results.xml"
Write-Host "`n Combining test results: $combinedResultsPath" -ForegroundColor Blue

$resultFiles = Get-ChildItem -Path $OutputPath -Filter "*-results.xml"
if ($resultFiles.Count -gt 0) {
 # Simple XML combination (basic approach)
 $combinedXml = '<?xml version="1.0" encoding="UTF-8"?>'
 $combinedXml += '<test-results>'
 
 foreach ($file in $resultFiles) {
 $content = Get-Content $file.FullName -Raw
 if ($content -match '<test-suite.*?</test-suite>') {
 $combinedXml += $matches0
 }
 }
 
 $combinedXml += '</test-results>'
 Set-Content -Path $combinedResultsPath -Value $combinedXml -Encoding UTF8
}

# Exit with appropriate code
if ($totalFailed -gt 0) {
 Write-Host "`n Tests failed! Exiting with error code." -ForegroundColor Red
 exit 1
} else {
 Write-Host "`n All tests passed!" -ForegroundColor Green
 exit 0
}

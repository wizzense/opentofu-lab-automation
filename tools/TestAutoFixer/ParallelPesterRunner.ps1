# ParallelPesterRunner.ps1
# Implements parallel processing for Pester tests to improve performance

function Invoke-ParallelPesterTests {
 CmdletBinding()
 param(
 string$TestPath = "tests",
 int$MaxParallelJobs = Environment::ProcessorCount,
 switch$UseThreadJobs,
 string$OutputFormat = "NUnitXml",
 string$OutputPath = "TestResults-Parallel.xml",
 string$Tags = @(),
 string$ExcludeTags = @(),
 switch$PassThru
 )
 
 Write-Host " Starting Parallel Pester Test Execution" -ForegroundColor Cyan
 Write-Host "Max Parallel Jobs: $MaxParallelJobs" -ForegroundColor Yellow
 Write-Host "Using Thread Jobs: $UseThreadJobs" -ForegroundColor Yellow
 
 # Get all test files
 $testFiles = Get-ChildItem -Path $TestPath -Recurse -Include "*.Tests.ps1" | Where-Object{ $_.Name -notmatch "IntegrationE2ESlow" } # Exclude slow tests from parallel run
 
 Write-Host "Found $($testFiles.Count) test files" -ForegroundColor Green
 
 # Group tests into batches for parallel execution
 $batchSize = Math::Max(1, Math::Floor($testFiles.Count / $MaxParallelJobs))
 $batches = @()
 
 for ($i = 0; $i -lt $testFiles.Count; $i += $batchSize) {
 $batch = $testFiles$i..(Math::Min($i + $batchSize - 1, $testFiles.Count - 1))
 $batches += ,@($batch)
 }
 
 Write-Host "Created $($batches.Count) test batches" -ForegroundColor Green
 
 # Create the test execution script block
 $testScriptBlock = { param($TestBatch, $BatchId, $Tags, $ExcludeTags)
 
 # Import required modules in each job - ensure consistent Pester 5.7.1
 Import-Module Pester -RequiredVersion 5.7.1 -Force
 
 # Set up Pester configuration for this batch
 $config = New-PesterConfiguration
 $config.Run.Path = $TestBatch
 $config.Output.Verbosity = 'Minimal'
 $config.TestResult.Enabled = $true
 $config.TestResult.OutputFormat = 'NUnitXml'
 $config.TestResult.OutputPath = "TestResults-Batch-$BatchId.xml"
 
 if ($Tags.Count -gt 0) {
 $config.Filter.Tag = $Tags
 }
 if ($ExcludeTags.Count -gt 0) {
 $config.Filter.ExcludeTag = $ExcludeTags
 }
 
 # Run tests for this batch
 try {
 $result = Invoke-Pester -Configuration $config
 return @{
 BatchId = $BatchId
 Success = $true
 Result = $result
 TestFiles = TestBatch | ForEach-Object{ $_.Name }
 TestCount = $result.TotalCount
 PassedCount = $result.PassedCount
 FailedCount = $result.FailedCount
 SkippedCount = $result.SkippedCount
 Duration = $result.Duration
 }
 } catch {
 return @{
 BatchId = $BatchId
 Success = $false
 Error = $_.Exception.Message
 TestFiles = TestBatch | ForEach-Object{ $_.Name }
 }
 }
 }
 
 # Start parallel jobs
 $jobs = @()
 $startTime = Get-Date
 
 for ($i = 0; $i -lt $batches.Count; $i++) {
 $batch = $batches$i
 Write-Host "Starting batch $($i + 1) with $($batch.Count) test files" -ForegroundColor Yellow
 
 if ($UseThreadJobs) {
 $job = Start-ThreadJob -ScriptBlock $testScriptBlock -ArgumentList $batch, ($i + 1), $Tags, $ExcludeTags
 } else {
 $job = Start-Job -ScriptBlock $testScriptBlock -ArgumentList $batch, ($i + 1), $Tags, $ExcludeTags
 }
 $jobs += $job
 }
 
 # Wait for all jobs to complete with progress indication
 Write-Host "Waiting for parallel test execution to complete..." -ForegroundColor Cyan
 
 $completed = 0
 $results = @()
 
 while ($completed -lt $jobs.Count) {
 $finishedJobs = jobs | Where-Object{ $_.State -eq 'Completed' -or $_.State -eq 'Failed' }
 
 foreach ($job in $finishedJobs) {
 if ($job.Id -notin (results | ForEach-Object{ $_.JobId })) {
 try {
 $result = Receive-Job -Job $job -Wait
 $result.JobId = $job.Id
 $results += $result
 $completed++
 
 if ($result.Success) {
 Write-Host "PASS Batch $($result.BatchId) completed: $($result.PassedCount)/$($result.TestCount) passed" -ForegroundColor Green
 } else {
 Write-Host "FAIL Batch $($result.BatchId) failed: $($result.Error)" -ForegroundColor Red
 }
 } catch {
 Write-Host "WARN Failed to receive job result: $($_.Exception.Message)" -ForegroundColor Yellow
 $completed++
 }
 Remove-Job -Job $job -Force
 }
 }
 
 # Show progress
 $progress = Math::Round(($completed / $jobs.Count) * 100, 1)
 Write-Progress -Activity "Running Parallel Tests" -Status "$completed/$($jobs.Count) batches completed" -PercentComplete $progress
 
 if ($completed -lt $jobs.Count) {
 Start-Sleep -Milliseconds 500
 }
 }
 
 Write-Progress -Activity "Running Parallel Tests" -Completed
 
 $endTime = Get-Date
 $totalDuration = $endTime - $startTime
 
 # Aggregate results
 $successfulResults = results | Where-Object{ $_.Success }
 $failedResults = results | Where-Object{ -not $_.Success }
 
 $totalTests = (successfulResults | Measure-Object -Property TestCount -Sum).Sum
 $totalPassed = (successfulResults | Measure-Object -Property PassedCount -Sum).Sum
 $totalFailed = (successfulResults | Measure-Object -Property FailedCount -Sum).Sum
 $totalSkipped = (successfulResults | Measure-Object -Property SkippedCount -Sum).Sum
 
 # Merge XML results if needed
 if ($OutputFormat -eq "NUnitXml" -and $OutputPath) {
 Merge-TestResults -OutputPath $OutputPath
 }
 
 # Display summary
 Write-Host "`n� Parallel Test Execution Complete!" -ForegroundColor Cyan
 Write-Host "=" * 50 -ForegroundColor Gray
 Write-Host "Total Duration: $($totalDuration.ToString('mm\:ss\.fff'))" -ForegroundColor Yellow
 Write-Host "Successful Batches: $($successfulResults.Count)/$($results.Count)" -ForegroundColor Green
 Write-Host "Total Tests: $totalTests" -ForegroundColor White
 Write-Host "Passed: $totalPassed" -ForegroundColor Green
 Write-Host "Failed: $totalFailed" -ForegroundColor Red
 Write-Host "Skipped: $totalSkipped" -ForegroundColor Yellow
 
 if ($failedResults.Count -gt 0) {
 Write-Host "`nFAIL Failed Batches:" -ForegroundColor Red
 failedResults | ForEach-Object{
 Write-Host " Batch $($_.BatchId): $($_.Error)" -ForegroundColor Red
 }
 }
 
 # Calculate performance improvement
 $estimatedSequentialTime = (successfulResults | Measure-Object -Property Duration -Sum).Sum
 if ($estimatedSequentialTime -gt 0) {
 $speedup = $estimatedSequentialTime.TotalSeconds / $totalDuration.TotalSeconds
 Write-Host "Estimated Speedup: ${speedup:F1}x faster than sequential" -ForegroundColor Cyan
 }
 
 if ($PassThru) {
 return @{
 TotalDuration = $totalDuration
 TotalTests = $totalTests
 PassedTests = $totalPassed
 FailedTests = $totalFailed
 SkippedTests = $totalSkipped
 SuccessfulBatches = $successfulResults.Count
 FailedBatches = $failedResults.Count
 Results = $results
 }
 }
}

function Merge-TestResults {
 CmdletBinding()
 param(
 string$OutputPath = "TestResults-Parallel.xml"
 )
 
 # Find all batch result files
 $batchFiles = Get-ChildItem -Path "." -Name "TestResults-Batch-*.xml"
 
 if ($batchFiles.Count -eq 0) {
 Write-Warning "No batch result files found to merge"
 return
 }
 
 Write-Host "Merging $($batchFiles.Count) test result files..." -ForegroundColor Yellow
 
 # Create merged XML document
 $mergedXml = xml'<?xml version="1.0" encoding="utf-8"?><test-results />'
 $mergedRoot = $mergedXml.'test-results'
 
 $totalTests = 0
 $totalFailures = 0
 $totalNotRun = 0
 $totalTime = 0
 
 foreach ($file in $batchFiles) {
 try {
 xml$batchXml = Get-Content $file
 $batchRoot = $batchXml.'test-results'
 
 # Aggregate counts
 $totalTests += int$batchRoot.total
 $totalFailures += int$batchRoot.failures
 $totalNotRun += int$batchRoot.'not-run'
 $totalTime += double$batchRoot.time
 
 # Import test suites
 foreach ($testSuite in $batchRoot.'test-suite') {
 $importedNode = $mergedXml.ImportNode($testSuite, $true)
 $mergedRoot.AppendChild($importedNode) | Out-Null}
 } catch {
 Write-Warning "Failed to process $file : $($_.Exception.Message)"
 }
 }
 
 # Set merged attributes
 $mergedRoot.SetAttribute('total', $totalTests)
 $mergedRoot.SetAttribute('failures', $totalFailures)
 $mergedRoot.SetAttribute('not-run', $totalNotRun)
 $mergedRoot.SetAttribute('time', $totalTime)
 $mergedRoot.SetAttribute('date', (Get-Date).ToString('yyyy-MM-dd'))
 $mergedRoot.SetAttribute('time', (Get-Date).ToString('HH:mm:ss'))
 
 # Save merged results
 $mergedXml.Save((Resolve-Path $OutputPath))
 Write-Host "PASS Merged results saved to $OutputPath" -ForegroundColor Green
 
 # Clean up batch files
 $batchFiles  Remove-Item -Force
 Write-Host "� Cleaned up batch result files" -ForegroundColor Gray
}

# Function to run integration tests separately (these shouldn't be parallelized)
function Invoke-IntegrationTests {
 CmdletBinding()
 param(
 string$TestPath = "tests",
 string$OutputPath = "IntegrationTestResults.xml"
 )
 
 Write-Host " Running Integration Tests (Sequential)" -ForegroundColor Cyan
 
 $integrationTests = Get-ChildItem -Path $TestPath -Recurse -Include "*.Tests.ps1" | Where-Object{ $_.Name -match "IntegrationE2ESlow" }
 
 if ($integrationTests.Count -eq 0) {
 Write-Host "No integration tests found" -ForegroundColor Yellow
 return
 }
 
 $config = New-PesterConfiguration
 $config.Run.Path = $integrationTests
 $config.Output.Verbosity = 'Detailed'
 $config.TestResult.Enabled = $true
 $config.TestResult.OutputFormat = 'NUnitXml'
 $config.TestResult.OutputPath = $OutputPath
 
 $result = Invoke-Pester -Configuration $config
 
 Write-Host "Integration Tests Complete: $($result.PassedCount)/$($result.TotalCount) passed" -ForegroundColor Green
 return $result
}

# Export functions
Export-ModuleMember -Function Invoke-ParallelPesterTests, Invoke-IntegrationTests, Merge-TestResults



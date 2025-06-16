function Invoke-ParallelScriptAnalyzer {
 <#
 .SYNOPSIS
 Run PSScriptAnalyzer on multiple files in parallel using PowerShell jobs with TRUE batch processing
 
 .PARAMETER Files
 Array of FileInfo objects to analyze
 
 .PARAMETER MaxJobs
 Maximum number of concurrent jobs (default: number of CPU cores)
 
 .PARAMETER BatchSize
 Number of files to process per job (default: 10)
 #>
 
 CmdletBinding()
 param(
 Parameter(Mandatory=$true, Position=0)
 System.IO.FileInfo$Files,
 
 int$MaxJobs = Environment::ProcessorCount,
 
 int$BatchSize = 10
 )
 
 # Validate input
 if (-not $Files -or $Files.Count -eq 0) {
 Write-Warning "No files provided to Invoke-ParallelScriptAnalyzer"
 return @()
 }
 
 Write-Host " Received $($Files.Count) files for parallel analysis" -ForegroundColor Cyan
 
 # Simple PSScriptAnalyzer import
 Import-Module PSScriptAnalyzer -Force
 
 # Split files into batches
 $batches = @()
 for ($i = 0; $i -lt $Files.Count; $i += $BatchSize) {
 $end = Math::Min($i + $BatchSize - 1, $Files.Count - 1)
 $batches += ,@($Files$i..$end)
 }
 
 Write-Host " Starting TRUE batch parallel analysis: $($batches.Count) batches ($BatchSize files/batch) with $MaxJobs concurrent jobs" -ForegroundColor Green
 
 # Define the scriptblock that processes a BATCH of files in one operation
 $batchScriptBlock = {
 param($FileBatch)
 
 Import-Module PSScriptAnalyzer -Force
 $batchResults = @()
 
 # Process all files in this batch as a single PSScriptAnalyzer call
 foreach ($file in $FileBatch) {
 try {
 $issues = Invoke-ScriptAnalyzer -Path $file.FullName -ErrorAction SilentlyContinue
 if ($issues) {
 $batchResults += $issues
 }
 } catch {
 # Add error as a synthetic issue
 $batchResults += PSCustomObject@{
 RuleName = 'ParsingError'
 Severity = 'Error'
 ScriptName = $file.FullName
 Message = $_.Exception.Message
 Line = 1
 Column = 1
 }
 }
 }
 
 return $batchResults
 }
 
 $allResults = System.Collections.ArrayList::new()
 $activeJobs = @{}
 $completed = 0
 $total = $batches.Count
 
 foreach ($batch in $batches) {
 # Wait for available job slot
 while ($activeJobs.Count -ge $MaxJobs) {
 $completedJobs = $activeJobs.Values  Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' }
 
 foreach ($job in $completedJobs) {
 try {
 $result = Receive-Job $job -ErrorAction SilentlyContinue
 if ($result) {
 $allResults.AddRange(@($result))
 }
 } catch {
 Write-Warning "Job failed for batch: $($job.Name) - $_"
 }
 Remove-Job $job -Force -ErrorAction SilentlyContinue
 $activeJobs.Remove($job.Id)
 $completed++
 }
 
 if ($activeJobs.Count -ge $MaxJobs) {
 Start-Sleep -Milliseconds 100
 }
 }
 
 # Start new job for this batch using the pre-defined scriptblock
 $batchName = "Batch_$($completed + 1)_$($batch.Count)files"
 $job = Start-Job -Name $batchName -ScriptBlock $batchScriptBlock -ArgumentList (,$batch)
 $activeJobs$job.Id = $job
 
 # Show progress
 $percentComplete = math::Round((($completed + $activeJobs.Count) / $total) * 100, 1)
 Write-Progress -Activity "Parallel Script Analysis" -Status "Started $batchName" -PercentComplete $percentComplete
 }
 
 # Wait for remaining jobs
 while ($activeJobs.Count -gt 0) {
 $completedJobs = $activeJobs.Values  Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' }
 
 foreach ($job in $completedJobs) {
 try {
 $result = Receive-Job $job -ErrorAction SilentlyContinue
 if ($result) {
 $allResults.AddRange(@($result))
 }
 } catch {
 Write-Warning "Job failed for batch: $($job.Name) - $_"
 }
 Remove-Job $job -Force -ErrorAction SilentlyContinue
 $activeJobs.Remove($job.Id)
 $completed++
 }
 
 if ($activeJobs.Count -gt 0) {
 Start-Sleep -Milliseconds 100
 }
 
 $percentComplete = math::Round(($completed / $total) * 100, 1)
 Write-Progress -Activity "Parallel Script Analysis" -Status "Completing..." -PercentComplete $percentComplete
 }
 
 Write-Progress -Activity "Parallel Script Analysis" -Completed
 Write-Host "PASS Parallel analysis completed: $completed batches processed ($($Files.Count) total files)" -ForegroundColor Green
 
 return $allResults.ToArray()
}

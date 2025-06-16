<#
.SYNOPSIS
Runs PowerShell code linting and analysis

.DESCRIPTION
This func if ($Parallel -and $psaAvailable -and $powerShellFiles.Count -gt 5) {
 Write-Host " Using parallel processing for $($powerShellFiles.Count) files..." -ForegroundColor Cyan
 
 # Simple parallel processing using ThreadJob
 try {
 if (-not (Get-Module -ListAvailable ThreadJob)) {
 Install-Module ThreadJob -Force -Scope CurrentUser -ErrorAction SilentlyContinue
 }
 Import-Module ThreadJob -Force -ErrorAction SilentlyContinue
 
 $jobs = @()
 $maxConcurrency = Math::Min(Environment::ProcessorCount, 4)
 
 # Process files in parallel
 foreach ($file in $powerShellFiles) {
 # Wait if we've hit max concurrency
 while ($jobs.Count -ge $maxConcurrency) {
 $completedJobs = jobs | Where-Object{ $_.State -eq 'Completed' -or $_.State -eq 'Failed' }
 foreach ($job in $completedJobs) {
 $result = Receive-Job $job -ErrorAction SilentlyContinue
 if ($result) { $allIssues += $result }
 Remove-Job $job
 }
 $jobs = jobs | Where-Object{ $_.Id -notin $completedJobs.Id }
 Start-Sleep -Milliseconds 100
 }
 
 # Start new job
 $job = Start-ThreadJob -ScriptBlock {
 param($FilePath)
 


try {
 Import-Module PSScriptAnalyzer -Force -ErrorAction SilentlyContinue
 return Invoke-ScriptAnalyzer -Path $FilePath -Severity Error,Warning -ErrorAction SilentlyContinue
 } catch {
 return @()
 }
 } -ArgumentList $file.FullName
 
 $jobs += $job
 }
 
 # Wait for remaining jobs
 $jobs  Wait-Job | ForEach-Object{
 $result = Receive-Job $_ -ErrorAction SilentlyContinue
 if ($result) { $allIssues += $result }
 Remove-Job $_
 }
 
 Write-Host " Parallel analysis complete: $($allIssues.Count) issues found" -ForegroundColor Blue
 
 } catch {
 Write-Host "WARN Parallel processing failed, falling back to sequential: $($_.Exception.Message)" -ForegroundColor Yellow
 $Parallel = $false
 }
 }
 
 if (-not $Parallel) { performs comprehensive PowerShell linting using PSScriptAnalyzer
and AST parsing to identify syntax errors, style issues, and potential problems.

.PARAMETER Path
Root path to scan for PowerShell files (default: current directory)

.PARAMETER OutputFormat
Output format: Text (console), JSON, or CI (for pipelines)

.PARAMETER PassThru
Return the lint results object

.EXAMPLE
Invoke-PowerShellLint

.EXAMPLE
Invoke-PowerShellLint -Path "/scripts" -OutputFormat JSON
#>
function Invoke-PowerShellLint {
 CmdletBinding()
 param(
 string$Path = ".",
 ValidateSet('Text', 'JSON', 'CI')



 string$OutputFormat = 'Text',
 switch$PassThru,
 switch$Parallel
 )
 
 $ErrorActionPreference = "Continue"
 
 Write-Host "Running PowerShell linting..." -ForegroundColor Cyan
 
 # Initialize PSScriptAnalyzer using the robust private function
 $psaAvailable = & {
 try {
 # Simple import first (the pattern that works)
 Import-Module PSScriptAnalyzer -Force
 
 # Test it works
 $null = Invoke-ScriptAnalyzer -ScriptDefinition "Write-Host 'test'" -ErrorAction Stop
 
 Write-Host "PASS PSScriptAnalyzer ready" -ForegroundColor Green
 return $true
 } catch {
 Write-Host "WARN PSScriptAnalyzer not available, using fallback methods" -ForegroundColor Yellow
 
 # Install using the proven method
 try {
 Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
 Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -AllowClobber -SkipPublisherCheck -ErrorAction SilentlyContinue
 Import-Module PSScriptAnalyzer -Force
 
 Write-Host "PASS PSScriptAnalyzer installed and ready" -ForegroundColor Green
 return $true
 } catch {
 Write-Host "FAIL PSScriptAnalyzer initialization failed, using AST-only analysis" -ForegroundColor Red
 return $false
 }
 }
 }
 
 # Find all PowerShell files
 $powerShellFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1", "*.psd1" -File
 
 if ($powerShellFiles.Count -eq 0) {
 Write-Host "No PowerShell files found in $Path" -ForegroundColor Yellow
 return
 }
 
 Write-Host "Found $($powerShellFiles.Count) PowerShell files to analyze" -ForegroundColor Green
 
 $allIssues = @()
 
 if ($Parallel -and $psaAvailable -and $powerShellFiles.Count -gt 5) {
 Write-Host " Using parallel processing for $($powerShellFiles.Count) files..." -ForegroundColor Cyan
 $allIssues = Invoke-ParallelScriptAnalyzer -Files $powerShellFiles
 } else {
 Write-Host " Processing files sequentially..." -ForegroundColor Yellow
 foreach ($file in $powerShellFiles) {
 Write-Host " Analyzing: $($file.Name)" -ForegroundColor Gray
 
 if ($psaAvailable) {
 try {
 $issues = Invoke-ScriptAnalyzer -Path $file.FullName -Severity Error,Warning
 $allIssues += $issues
 } catch {
 Write-Host " WARN Analysis failed: $($_.Exception.Message)" -ForegroundColor Yellow
 }
 } else {
 # Fallback to basic syntax checking
 try {
 $content = Get-Content $file.FullName -Raw
 $null = System.Management.Automation.PSParser::Tokenize($content, ref$null)
 Write-Host " PASS Syntax OK" -ForegroundColor Green
 } catch {
 Write-Host " FAIL Syntax Error: $($_.Exception.Message)" -ForegroundColor Red
 $allIssues += PSCustomObject@{
 RuleName = "SyntaxError"
 Severity = "Error"
 ScriptName = $file.Name
 Line = 0
 Message = $_.Exception.Message
 }
 }
 }
 }
 }
 Write-Host "No PowerShell files found in $Path" -ForegroundColor Yellow
 return
 }
 
 Write-Host "Found $($powerShellFiles.Count) PowerShell files" -ForegroundColor Green
 
 # Use parallel processing for faster analysis
 if ($Parallel -and $powerShellFiles.Count -gt 1) {
 Write-Host " Using parallel analysis for faster processing..." -ForegroundColor Green
 $allResults = Invoke-ParallelScriptAnalyzer -Path $Path -MaxConcurrency (Environment::ProcessorCount) -Severity 'Information'
 } else {
 # Sequential processing (original logic)
 $allResults = @()
 
 foreach ($file in $powerShellFiles) {
 Write-Host "Analyzing: $($file.Name)" -ForegroundColor Gray
 
 try {
 # First check for syntax errors using AST parsing
 $tokens = $null
 $parseErrors = $null
 $ast = System.Management.Automation.Language.Parser::ParseFile(
 $file.FullName, 
 ref$tokens, 
 ref$parseErrors
 )
 
 # Add parse errors to results
 foreach ($error in $parseErrors) {
 $allResults += PSCustomObject@{
 File = $file.FullName
 Line = $error.Extent.StartLineNumber
 Column = $error.Extent.StartColumnNumber
 Severity = 'Error'
 RuleName = 'ParseError'
 Message = $error.Message
 ScriptName = $file.Name
 ErrorType = 'Syntax'
 FixSuggestion = Get-SyntaxFixSuggestion -Error $error
 }
 }
 
 # Run PSScriptAnalyzer if available and no parse errors
 if ($parseErrors.Count -eq 0 -and $psAnalyzerAvailable) {
 try {
 $scriptAnalyzerResults = Invoke-ScriptAnalyzer -Path $file.FullName -ErrorAction SilentlyContinue
 
 foreach ($result in $scriptAnalyzerResults) {
 $allResults += PSCustomObject@{
 File = $file.FullName
 Line = $result.Line
 Column = $result.Column
 Severity = $result.Severity
 RuleName = $result.RuleName
 Message = $result.Message
 ScriptName = $file.Name
 ErrorType = 'Style'
 FixSuggestion = $null
 }
 }
 } catch {
 # PSScriptAnalyzer failed, add note about it
 $allResults += PSCustomObject@{
 File = $file.FullName
 Line = 1
 Column = 1
 Severity = 'Information'
 RuleName = 'PSScriptAnalyzerError'
 Message = "PSScriptAnalyzer analysis failed: $($_.Exception.Message)"
 ScriptName = $file.Name
 ErrorType = 'Tool'
 FixSuggestion = "Ensure PSScriptAnalyzer is properly installed"
 }
 }
 } elseif ($parseErrors.Count -eq 0 -and -not $psAnalyzerAvailable) {
 # Note that PSScriptAnalyzer analysis was skipped
 $allResults += PSCustomObject@{
 File = $file.FullName
 Line = 1
 Column = 1
 Severity = 'Information'
 RuleName = 'PSScriptAnalyzerUnavailable'
 Message = "PSScriptAnalyzer not available - using AST analysis only"
 ScriptName = $file.Name
 ErrorType = 'Tool'
 FixSuggestion = "Install PSScriptAnalyzer for enhanced analysis"
 }
 }
 
 } catch {
 $allResults += PSCustomObject@{
 File = $file.FullName
 Line = 1
 Column = 1
 Severity = 'Error'
 RuleName = 'FileError'
 Message = "Failed to analyze file: $($_.Exception.Message)"
 ScriptName = $file.Name
 ErrorType = 'System'
 FixSuggestion = $null
 }
 }
 }
 
 # Output results based on format
 $errorCount = (allIssues | Where-Object{ $_.Severity -eq 'Error' }).Count
 $warningCount = (allIssues | Where-Object{ $_.Severity -eq 'Warning' }).Count
 $totalIssues = $allIssues.Count
 
 switch ($OutputFormat) {
 'JSON' {
 $result = @{
 TotalFiles = $powerShellFiles.Count
 TotalIssues = $totalIssues
 ErrorCount = $errorCount
 WarningCount = $warningCount
 Issues = $allIssues
 Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 }
 result | ConvertTo-Json-Depth 10
 }
 'CI' {
 Write-Host "::group::PowerShell Linting Results"
 Write-Host "Files analyzed: $($powerShellFiles.Count)"
 Write-Host "Total issues: $totalIssues (Errors: $errorCount, Warnings: $warningCount)"
 
 foreach ($issue in $allIssues) {
 $level = if ($issue.Severity -eq 'Error') { 'error' } else { 'warning' }
 Write-Host "::$level file=$($issue.ScriptName),line=$($issue.Line)::$($issue.RuleName): $($issue.Message)"
 }
 Write-Host "::endgroup::"
 }
 default {
 Write-Host "`n Linting Summary:" -ForegroundColor Cyan
 Write-Host " Files analyzed: $($powerShellFiles.Count)" -ForegroundColor White
 Write-Host " Issues found: $totalIssues" -ForegroundColor White
 Write-Host " Errors: $errorCount" -ForegroundColor Red
 Write-Host " Warnings: $warningCount" -ForegroundColor Yellow
 
 if ($allIssues.Count -gt 0) {
 Write-Host "`n Issues Details:" -ForegroundColor Yellow
 allIssues | Group-ObjectSeverity | ForEach-Object{
 $severityColor = if ($_.Name -eq 'Error') { 'Red' } else { 'Yellow' }
 Write-Host "`n $($_.Name) ($($_.Count)):" -ForegroundColor $severityColor
 $_.Group | ForEach-Object{
 Write-Host " $($_.ScriptName):$($_.Line) - $($_.RuleName): $($_.Message)" -ForegroundColor Gray
 }
 }
 } else {
 Write-Host "`nPASS No issues found!" -ForegroundColor Green
 }
 }
 }
 
 if ($PassThru) {
 return @{
 TotalFiles = $powerShellFiles.Count
 TotalIssues = $totalIssues
 ErrorCount = $errorCount
 WarningCount = $warningCount
 Issues = $allIssues
 }
 }
}








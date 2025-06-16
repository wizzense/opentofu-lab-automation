<#
.SYNOPSIS
Runs PowerShell code linting and analysis

.DESCRIPTION
This function performs comprehensive PowerShell linting using PSScriptAnalyzer
and AST parsing to identify syntax errors, style issues, and potential problems.

.PARAMETER Path
Root path to scan for PowerShell files (default: current directory)

.PARAMETER OutputFormat
Output format: Text (console), JSON, or CI (for pipelines)

.PARAMETER PassThru
Return the lint results object

.PARAMETER Parallel
Use parallel processing for faster analysis

.EXAMPLE
Invoke-PowerShellLint

.EXAMPLE
Invoke-PowerShellLint -Path "/scripts" -OutputFormat JSON -Parallel
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
 
 # Simple PSScriptAnalyzer import - copy the working pattern that's used elsewhere
 try {
 Import-Module PSScriptAnalyzer -Force
 $null = Invoke-ScriptAnalyzer -ScriptDefinition "Write-Host 'test'" -ErrorAction Stop
 $psaAvailable = $true
 Write-Host "PASS PSScriptAnalyzer imported successfully" -ForegroundColor Green
 } catch {
 Write-Host "FAIL PSScriptAnalyzer failed to import: $($_.Exception.Message)" -ForegroundColor Red
 $psaAvailable = $false
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



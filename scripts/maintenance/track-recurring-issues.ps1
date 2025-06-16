#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/track-recurring-issues.ps1

<#
.SYNOPSIS
Tracks recurring issues and maintains a summary of the biggest problems.

.DESCRIPTION
This script analyzes test results, identifies recurring patterns, and maintains
a comprehensive issue tracking system including:
- Analysis of existing test results without re-running tests
- Recurring issue pattern detection
- Automated diff tracking for changelog
- Issue severity classification
- Prevention recommendations

.PARAMETER Mode
Mode to run: Analyze, Track, GenerateReport, UpdateChangelog

.PARAMETER IncludePreventionCheck
Run prevention checks to ensure known issues don't reoccur

.EXAMPLE
./scripts/maintenance/track-recurring-issues.ps1 -Mode "Analyze"

.EXAMPLE
./scripts/maintenance/track-recurring-issues.ps1 -Mode "Track" -IncludePreventionCheck
#>

CmdletBinding()
param(
 Parameter(Mandatory = $true)







 ValidateSet('Analyze', 'Track', 'GenerateReport', 'UpdateChangelog', 'All')
 string$Mode,
 
 Parameter()
 switch$IncludePreventionCheck
)

$ErrorActionPreference = "Stop"
# Detect the correct project root based on the current environment
if ($IsWindows -or $env:OS -eq "Windows_NT") {
 $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
 $ProjectRoot = "/workspaces/opentofu-lab-automation"
}
$IssueTrackingPath = "$ProjectRoot/docs/reports/issue-tracking"

function Write-TrackLog {
 param(string$Message, string$Level = "INFO")
 






$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 $color = switch ($Level) {
 "INFO" { "Cyan" }
 "SUCCESS" { "Green" }
 "WARNING" { "Yellow" }
 "ERROR" { "Red" }
 "TRACK" { "Magenta" }
 "PREVENT" { "Blue" }
 default { "White" }
 }
 Write-Host "$timestamp $Level $Message" -ForegroundColor $color
}

function Get-LatestTestResults {
 Write-TrackLog "Analyzing existing test results..." "TRACK"
 
 # Search for test results in multiple locations
 $possiblePaths = @(
 "$ProjectRoot/TestResults.xml",
 "$ProjectRoot/scripts/testing/TestResults.xml",
 "$ProjectRoot/coverage/testResults.xml",
 "$ProjectRoot/archive/testResults.xml"
 )
 
 $testResultsFile = $null
 $latestTime = DateTime::MinValue
 
 foreach ($path in $possiblePaths) {
 if (Test-Path $path) {
 $lastModified = (Get-Item $path).LastWriteTime
 if ($lastModified -gt $latestTime) {
 $latestTime = $lastModified
 $testResultsFile = $path
 }
 }
 }
 
 if (-not $testResultsFile) {
 Write-TrackLog "No existing test results found in any location" "WARNING"
 return $null
 }
 
 Write-TrackLog "Found latest test results: $testResultsFile" "SUCCESS"
 Write-TrackLog "Results from: $latestTime" "SUCCESS"
 
 try {
 xml$testResults = Get-Content $testResultsFile
 return $testResults
 }
 catch {
 Write-TrackLog "Failed to parse test results: $($_.Exception.Message)" "ERROR"
 return $null
 }
}

function Analyze-RecurringIssues {
 param(xml$TestResults)
 
 






Write-TrackLog "Analyzing recurring issue patterns..." "TRACK"
 
 $issuePatterns = @{}
 $testFailures = $TestResults.SelectNodes("//test-case@result='Failure'")
 
 foreach ($failure in $testFailures) {
 $message = $failure.failure.message
 $testName = $failure.name
 
 # Categorize common error patterns
 $category = switch -Regex ($message) {
 "CommandNotFoundException.*'errors'" { "Missing Command: errors" }
 "CommandNotFoundException.*'Format-Config'" { "Missing Command: Format-Config" }
 "CommandNotFoundException.*'Invoke-LabStep'" { "Missing Command: Invoke-LabStep" }
 "CommandNotFoundException.*'Write-Continue'" { "Missing Command: Write-Continue" }
 "Missing closing '\}'" { "Syntax Error: Missing Closing Brace" }
 "Unexpected token" { "Syntax Error: Token Issues" }
 "Import-Module.*not loaded" { "Module Import Error" }
 "ParseException" { "PowerShell Parse Error" }
 "npm.*JSON\.parse" { "NPM Environment Error" }
 "git.*not a git repository" { "Git Context Error" }
 default { "Other: $($message.Split('.')0)" }
 }
 
 if (-not $issuePatterns.ContainsKey($category)) {
 $issuePatterns$category = @{
 Count = 0
 Examples = @()
 Severity = "Medium"
 Prevention = ""
 }
 }
 
 $issuePatterns$category.Count++
 $issuePatterns$category.Examples += @{
 Test = $testName
 Message = $message
 }
 }
 
 # Classify severity based on count and impact
 foreach ($category in $issuePatterns.Keys) {
 $count = $issuePatterns$category.Count
 $issuePatterns$category.Severity = switch ($count) {
 { $_ -gt 10 } { "Critical" }
 { $_ -gt 5 } { "High" }
 { $_ -gt 2 } { "Medium" }
 default { "Low" }
 }
 
 # Add prevention recommendations
 $issuePatterns$category.Prevention = switch -Regex ($category) {
 "Missing Command:" { "Add mock function to TestHelpers.ps1" }
 "Syntax Error:" { "Run fix-test-syntax.ps1 before commits" }
 "Module Import Error" { "Update import paths with fix-infrastructure-issues.ps1" }
 "NPM Environment Error" { "Mock NPM functions in test environment" }
 "Git Context Error" { "Expected in Codespaces - add skip conditions" }
 default { "Manual investigation required" }
 }
 }
 
 return $issuePatterns
}

function Generate-IssueSummary {
 param(hashtable$IssuePatterns, xml$TestResults)
 
 






$summary = @{
 Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 TestResultsDate = (Get-Item "$ProjectRoot/TestResults.xml").LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
 TotalTests = int$TestResults.'test-results'.total
 TotalFailures = int$TestResults.'test-results'.failures
 TotalSkipped = int$TestResults.'test-results'.skipped
 SuccessRate = math::Round((($TestResults.'test-results'.total - $TestResults.'test-results'.failures) / $TestResults.'test-results'.total) * 100, 2)
 RecurringIssues = $IssuePatterns
 TopIssues = @()
 }
 
 # Sort issues by severity and count
 $sortedIssues = $IssuePatterns.GetEnumerator()  Sort-Object { 
 $severityOrder = @{ "Critical" = 4; "High" = 3; "Medium" = 2; "Low" = 1 }
 $severityOrder$_.Value.Severity * 1000 + $_.Value.Count 
 } -Descending
 
 $summary.TopIssues = $sortedIssues  Select-Object -First 10
 
 return $summary
}

function Save-IssueTracking {
 param(object$Summary)
 
 






# Ensure issue tracking directory exists
 if (-not (Test-Path $IssueTrackingPath)) {
 New-Item -ItemType Directory -Path $IssueTrackingPath -Force  Out-Null
 }
 
 # Save current summary
 $currentFile = "$IssueTrackingPath/current-issues.json"
 $Summary  ConvertTo-Json -Depth 10  Set-Content $currentFile
 
 # Save historical record
 $date = Get-Date -Format "yyyy-MM-dd-HHmm"
 $historicalFile = "$IssueTrackingPath/issues-$date.json"
 $Summary  ConvertTo-Json -Depth 10  Set-Content $historicalFile
 
 Write-TrackLog "Saved issue tracking to: $currentFile" "SUCCESS"
 Write-TrackLog "Historical record: $historicalFile" "SUCCESS"
}

function Generate-IssueReport {
 param(object$Summary)
 
 






$reportContent = @"
# Recurring Issues Summary - $(Get-Date -Format "yyyy-MM-dd")

**Last Test Results**: $($Summary.TestResultsDate) 
**Analysis Time**: $($Summary.Timestamp)

## Test Health Overview

 Metric  Value  Status 
-----------------------
 **Total Tests**  $($Summary.TotalTests)  PASS 
 **Success Rate**  $($Summary.SuccessRate)%  $(if($Summary.SuccessRate -gt 80) { "PASS" } elseif($Summary.SuccessRate -gt 60) { "WARN" } else { "FAIL" }) 
 **Total Failures**  $($Summary.TotalFailures)  $(if($Summary.TotalFailures -lt 20) { "PASS" } elseif($Summary.TotalFailures -lt 50) { "WARN" } else { "FAIL" }) 
 **Skipped Tests**  $($Summary.TotalSkipped)  INFO 

## Top Recurring Issues

"@

 foreach ($issue in $Summary.TopIssues) {
 $severity = $issue.Value.Severity
 $icon = switch ($severity) {
 "Critical" { "�" }
 "High" { "�" }
 "Medium" { "�" }
 "Low" { "�" }
 }
 
 $reportContent += @"

### $icon **$($issue.Key)** - $severity Priority
- **Occurrences**: $($issue.Value.Count)
- **Prevention**: $($issue.Value.Prevention)
- **Example**: ``$($issue.Value.Examples0.Message.Split("`n")0)``

"@
 }

 $reportContent += @"

## Quick Fix Commands

Based on the current issues, run these commands to address problems:

``````powershell
# Fix missing commands (most common issue)
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "MissingCommands"

# Fix syntax errors
./scripts/maintenance/fix-test-syntax.ps1

# Comprehensive fix
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "All"

# Validate improvements
./scripts/maintenance/track-recurring-issues.ps1 -Mode "Analyze"
``````

## Prevention Checklist

-   Add missing command mocks to TestHelpers.ps1
-   Run syntax validation before commits
-   Update test templates to avoid common errors
-   Consider adding pre-commit hooks for validation

---

*This report is auto-generated from the latest test results. Re-run tests only when needed.*
"@

 $reportFile = "$ProjectRoot/docs/reports/issue-tracking/$(Get-Date -Format "yyyy-MM-dd")-recurring-issues-summary.md"
 $reportContent  Set-Content $reportFile
 
 Write-TrackLog "Generated issue report: $reportFile" "SUCCESS"
 return $reportFile
}

function Run-PreventionChecks {
 Write-TrackLog "Running prevention checks..." "PREVENT"
 
 $checks = @{
 "TestHelpers Mock Functions" = $false
 "Syntax Validation Tools" = $false
 "Import Path Consistency" = $false
 "Pre-commit Hooks" = $false
 }
 
 # Check TestHelpers.ps1 for mock functions
 $testHelpersPath = "$ProjectRoot/tests/helpers/TestHelpers.ps1"
 if (Test-Path $testHelpersPath) {
 $content = Get-Content $testHelpersPath -Raw
 $checks"TestHelpers Mock Functions" = $content -match "function.*Format-Configfunction.*Invoke-LabStepfunction.*Write-Continue"
 }
 
 # Check for syntax validation tools
 $checks"Syntax Validation Tools" = (Test-Path "$ProjectRoot/scripts/maintenance/fix-test-syntax.ps1")
 
 # Check for consistent import paths
 $deprecatedPaths = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1", "*.psm1"  
 Select-String -Pattern "pwsh/modules" -SimpleMatch -ErrorAction SilentlyContinue
 $checks"Import Path Consistency" = $deprecatedPaths.Count -eq 0
 
 # Check for pre-commit hooks
 $checks"Pre-commit Hooks" = (Test-Path "$ProjectRoot/.git/hooks/pre-commit")
 
 foreach ($check in $checks.GetEnumerator()) {
 $status = if ($check.Value) { "PASS PASS" } else { "FAIL FAIL" }
 Write-TrackLog " $($check.Key): $status" "PREVENT"
 }
 
 return $checks
}

function Update-ChangelogWithIssues {
 param(object$Summary, string$ReportFile)
 
 






$changelogPath = "$ProjectRoot/CHANGELOG.md"
 if (-not (Test-Path $changelogPath)) {
 Write-TrackLog "CHANGELOG.md not found" "WARNING"
 return
 }
 
 $content = Get-Content $changelogPath -Raw
 $date = Get-Date -Format "yyyy-MM-dd"
 
 $issueUpdate = @"

### Recurring Issues Tracking ($date)
- **Test Success Rate**: $($Summary.SuccessRate)% ($($Summary.TotalTests - $Summary.TotalFailures)/$($Summary.TotalTests) tests passing)
- **Top Issue**: $($Summary.TopIssues0.Key) ($($Summary.TopIssues0.Value.Count) occurrences)
- **Detailed Analysis**: Recurring Issues Summary($ReportFile)
- **Prevention Status**: $(if((Run-PreventionChecks).Values -contains $false) { "WARN Needs Attention" } else { "PASS Good" })
"@

 # Insert after the Unreleased section
 $updatedContent = $content -replace "(\Unreleased\\s*\n)", "`$1$issueUpdate`n"
 
 Set-Content $changelogPath $updatedContent
 Write-TrackLog "Updated CHANGELOG.md with issue tracking" "SUCCESS"
}

# Main execution
Write-TrackLog "Starting recurring issues tracking in mode: $Mode" "TRACK"

try {
 switch ($Mode) {
 'Analyze' {
 $testResults = Get-LatestTestResults
 if ($testResults) {
 $issues = Analyze-RecurringIssues $testResults
 $summary = Generate-IssueSummary $issues $testResults
 Save-IssueTracking $summary
 
 Write-TrackLog "Analysis complete - Top issue: $($summary.TopIssues0.Key)" "SUCCESS"
 Write-TrackLog "Success rate: $($summary.SuccessRate)%" "SUCCESS"
 }
 }
 
 'Track' {
 $testResults = Get-LatestTestResults
 if ($testResults) {
 $issues = Analyze-RecurringIssues $testResults
 $summary = Generate-IssueSummary $issues $testResults
 Save-IssueTracking $summary
 
 if ($IncludePreventionCheck) {
 Run-PreventionChecks  Out-Null
 }
 }
 }
 
 'GenerateReport' {
 $currentIssuesFile = "$IssueTrackingPath/current-issues.json"
 if (Test-Path $currentIssuesFile) {
 $summary = Get-Content $currentIssuesFile  ConvertFrom-Json
 $reportFile = Generate-IssueReport $summary
 Write-TrackLog "Report generated: $reportFile" "SUCCESS"
 } else {
 Write-TrackLog "No current issues data found. Run -Mode Analyze first." "WARNING"
 }
 }
 
 'UpdateChangelog' {
 $currentIssuesFile = "$IssueTrackingPath/current-issues.json"
 if (Test-Path $currentIssuesFile) {
 $summary = Get-Content $currentIssuesFile  ConvertFrom-Json
 $reportFile = "docs/reports/issue-tracking/$(Get-Date -Format "yyyy-MM-dd")-recurring-issues-summary.md"
 Update-ChangelogWithIssues $summary $reportFile
 } else {
 Write-TrackLog "No current issues data found. Run -Mode Analyze first." "WARNING"
 }
 }
 
 'All' {
 $testResults = Get-LatestTestResults
 if ($testResults) {
 $issues = Analyze-RecurringIssues $testResults
 $summary = Generate-IssueSummary $issues $testResults
 Save-IssueTracking $summary
 $reportFile = Generate-IssueReport $summary
 Update-ChangelogWithIssues $summary $reportFile
 
 if ($IncludePreventionCheck) {
 Run-PreventionChecks  Out-Null
 }
 
 Write-TrackLog "Complete tracking cycle finished" "SUCCESS"
 }
 }
 }
}
catch {
 Write-TrackLog "Tracking failed: $($_.Exception.Message)" "ERROR"
 exit 1
}





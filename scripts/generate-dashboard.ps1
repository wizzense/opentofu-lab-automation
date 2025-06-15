#!/usr/bin/env pwsh
<#
.SYNOPSIS
 Generates a comprehensive dashboard report for the README.md
.DESCRIPTION
 This script analyzes workflow health, Pester test results, and system status
 to generate a comprehensive dashboard section for the README.md file.
.PARAMETER UpdateReadme
 If specified, automatically updates the README.md file with the new dashboard
.PARAMETER OutputPath
 Path where to save the dashboard report (default: reports/dashboard-report.md)
.EXAMPLE
 ./scripts/generate-dashboard.ps1 -UpdateReadme
 Generates dashboard and updates README.md
.EXAMPLE
 ./scripts/generate-dashboard.ps1 -OutputPath "custom-dashboard.md"
 Generates dashboard and saves to custom file
#>

[CmdletBinding()]
param(
 [switch]$UpdateReadme,
 [string]$OutputPath = "reports/dashboard-report.md"
)








$ErrorActionPreference = "Stop"

Write-Host " Generating Comprehensive Dashboard Report..." -ForegroundColor Cyan

# Ensure reports directory exists
$reportsDir = Split-Path $OutputPath -Parent
if ($reportsDir -and -not (Test-Path $reportsDir)) {
 New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"

# Initialize dashboard data
$dashboardData = @{
 Timestamp = $timestamp
 OverallHealth = "Unknown"
 HealthScore = 0
 Workflows = @()
 PesterResults = @{}
 SystemStatus = @{}
 RecentChanges = @()
 Recommendations = @()
}

Write-Host " Analyzing Pester test results..." -ForegroundColor Yellow

# Check for recent Pester test results
$testResultFiles = Get-ChildItem -Path "." -Filter "*TestResults*.xml" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 5

$pesterSummary = @{
 TotalTests = 0
 PassedTests = 0
 FailedTests = 0
 SkippedTests = 0
 LastRun = "Never"
 SuccessRate = 0
}

if ($testResultFiles) {
 try {
 $latestResult = $testResultFiles[0]
 $pesterSummary.LastRun = $latestResult.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
 
 # Try to parse XML test results
 [xml]$testXml = Get-Content $latestResult.FullName
 
 # Handle different XML formats (NUnit/JUnit)
 if ($testXml.testResults) {
 # NUnit format
 $pesterSummary.TotalTests = [int]$testXml.testResults.total
 $pesterSummary.PassedTests = [int]$testXml.testResults.passed
 $pesterSummary.FailedTests = [int]$testXml.testResults.failures
 $pesterSummary.SkippedTests = [int]$testXml.testResults.skipped
 } elseif ($testXml.testsuite) {
 # JUnit format
 $pesterSummary.TotalTests = [int]$testXml.testsuite.tests
 $pesterSummary.PassedTests = [int]$testXml.testsuite.tests - [int]$testXml.testsuite.failures - [int]$testXml.testsuite.errors
 $pesterSummary.FailedTests = [int]$testXml.testsuite.failures + [int]$testXml.testsuite.errors
 $pesterSummary.SkippedTests = [int]$testXml.testsuite.skipped
 }
 
 if ($pesterSummary.TotalTests -gt 0) {
 $pesterSummary.SuccessRate = [math]::Round(($pesterSummary.PassedTests / $pesterSummary.TotalTests) * 100, 1)
 }
 } catch {
 Write-Warning "Could not parse test results: $($_.Exception.Message)"
 }
}

$dashboardData.PesterResults = $pesterSummary

Write-Host " Checking system components..." -ForegroundColor Yellow

# Check key system components
$systemChecks = @{
 "PowerShell Scripts" = @{
 Status = "Unknown"
 Details = ""
 }
 "Workflow Files" = @{
 Status = "Unknown" 
 Details = ""
 }
 "Test Coverage" = @{
 Status = "Unknown"
 Details = ""
 }
}

# Check PowerShell scripts
try {
 if (Test-Path "pwsh/runner_scripts") {
 $psScripts = Get-ChildItem "pwsh/runner_scripts" -Filter "*.ps1" | Measure-Object
 $systemChecks["PowerShell Scripts"].Status = "[PASS] Healthy"
 $systemChecks["PowerShell Scripts"].Details = "$($psScripts.Count) scripts found"
 } else {
 $systemChecks["PowerShell Scripts"].Status = "[FAIL] Missing"
 $systemChecks["PowerShell Scripts"].Details = "Runner scripts directory not found"
 }
} catch {
 $systemChecks["PowerShell Scripts"].Status = "[WARN] Error"
 $systemChecks["PowerShell Scripts"].Details = $_.Exception.Message
}

# Check workflow files
try {
 if (Test-Path ".github/workflows") {
 $workflows = Get-ChildItem ".github/workflows" -Filter "*.yml" | Measure-Object
 $systemChecks["Workflow Files"].Status = "[PASS] Healthy"
 $systemChecks["Workflow Files"].Details = "$($workflows.Count) workflows found"
 } else {
 $systemChecks["Workflow Files"].Status = "[FAIL] Missing"
 $systemChecks["Workflow Files"].Details = "Workflows directory not found"
 }
} catch {
 $systemChecks["Workflow Files"].Status = "[WARN] Error"
 $systemChecks["Workflow Files"].Details = $_.Exception.Message
}

# Check test coverage
try {
 if (Test-Path "tests") {
 $testFiles = Get-ChildItem "tests" -Filter "*.Tests.ps1" | Measure-Object
 $systemChecks["Test Coverage"].Status = "[PASS] Healthy"
 $systemChecks["Test Coverage"].Details = "$($testFiles.Count) test files found"
 } else {
 $systemChecks["Test Coverage"].Status = "[FAIL] Missing"
 $systemChecks["Test Coverage"].Details = "Tests directory not found"
 }
} catch {
 $systemChecks["Test Coverage"].Status = "[WARN] Error"
 $systemChecks["Test Coverage"].Details = $_.Exception.Message
}

$dashboardData.SystemStatus = $systemChecks

Write-Host " Calculating overall health score..." -ForegroundColor Yellow

# Calculate overall health score
$healthComponents = @()

# Pester test health (40% weight)
if ($pesterSummary.SuccessRate -gt 0) {
 $healthComponents += $pesterSummary.SuccessRate * 0.4
} else {
 $healthComponents += 0
}

# System component health (60% weight)
$systemHealthScore = 0
$systemComponentCount = 0

foreach ($component in $systemChecks.Values) {
 $systemComponentCount++
 if ($component.Status -like "*[PASS]*") {
 $systemHealthScore += 100
 } elseif ($component.Status -like "*[WARN]*") {
 $systemHealthScore += 50
 } else {
 $systemHealthScore += 0
 }
}

if ($systemComponentCount -gt 0) {
 $avgSystemHealth = $systemHealthScore / $systemComponentCount
 $healthComponents += $avgSystemHealth * 0.6
}

$dashboardData.HealthScore = [math]::Round(($healthComponents | Measure-Object -Sum).Sum, 1)

# Determine overall health status
if ($dashboardData.HealthScore -ge 95) {
 $dashboardData.OverallHealth = "� Excellent"
} elseif ($dashboardData.HealthScore -ge 85) {
 $dashboardData.OverallHealth = "� Good"
} elseif ($dashboardData.HealthScore -ge 70) {
 $dashboardData.OverallHealth = "� Fair"
} else {
 $dashboardData.OverallHealth = "� Poor"
}

# Generate recommendations
$recommendations = @()

if ($pesterSummary.SuccessRate -lt 95 -and $pesterSummary.TotalTests -gt 0) {
 $recommendations += " Review failed Pester tests and improve test coverage"
}

if ($pesterSummary.TotalTests -eq 0) {
 $recommendations += " Set up Pester tests for better code quality monitoring"
}

$failingComponents = $systemChecks.Keys | Where-Object { $systemChecks[$_].Status -notlike "*[PASS]*" }
if ($failingComponents) {
 $recommendations += " Address issues with: $($failingComponents -join ', ')"
}

if ($dashboardData.HealthScore -lt 85) {
 $recommendations += " Overall system health needs improvement - focus on critical issues first"
}

if (-not $recommendations) {
 $recommendations += " System is healthy! Continue monitoring and maintain current standards"
}

$dashboardData.Recommendations = $recommendations

Write-Host " Generating dashboard content..." -ForegroundColor Yellow

# Generate dashboard markdown
$dashboardContent = @"
<!-- DASHBOARD START -->
## Workflow Health Dashboard

**Last Updated:** $timestamp 
**Overall Health:** $($dashboardData.OverallHealth) ($($dashboardData.HealthScore)%)

### Current Status

| Component | Status | Details |
|-----------|--------|---------|
"@

foreach ($component in $systemChecks.Keys) {
 $status = $systemChecks[$component]
 $dashboardContent += "| $component | $($status.Status) | $($status.Details) |`n"
}

$dashboardContent += @"

### Test Results Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | $($pesterSummary.TotalTests) |
| **Passed** | $($pesterSummary.PassedTests) [PASS] |
| **Failed** | $($pesterSummary.FailedTests) [FAIL] |
| **Skipped** | $($pesterSummary.SkippedTests) ⏭ |
| **Success Rate** | $($pesterSummary.SuccessRate)% |
| **Last Run** | $($pesterSummary.LastRun) |

### Health Metrics

``````
 Overall Health Score: $($dashboardData.HealthScore)%
 Test Success Rate: $($pesterSummary.SuccessRate)%
 Last Updated: $timestamp
``````

### Quick Actions

- [Run Final Automation Test](../../final-automation-test.ps1)
- [Run Pester Tests](../../actions/workflows/pester.yml) 
- [Run PowerShell Validation](../../tools/Validate-PowerShellScripts.ps1)
- [Generate Health Report](../../scripts/generate-dashboard.ps1)

### Recommendations

"@

foreach ($rec in $recommendations) {
 $dashboardContent += "- $rec`n"
}

$dashboardContent += @"

### Health Score Legend

- � **Excellent (95-100%)**: All systems operational
- � **Good (85-94%)**: Minor issues, generally stable 
- � **Fair (70-84%)**: Some issues need attention
- � **Poor (<70%)**: Critical issues require immediate attention

<!-- DASHBOARD END -->
"@

# Save dashboard report
Set-Content -Path $OutputPath -Value $dashboardContent -Encoding UTF8
Write-Host "[PASS] Dashboard report saved to: $OutputPath" -ForegroundColor Green

# Update README.md if requested
if ($UpdateReadme) {
 Write-Host " Updating README.md with new dashboard..." -ForegroundColor Yellow
 
 if (Test-Path "README.md") {
 $readmeContent = Get-Content "README.md" -Raw
 
 if ($readmeContent -match '<!-- DASHBOARD START -->.*<!-- DASHBOARD END -->') {
 # Replace existing dashboard
 $newReadmeContent = $readmeContent -replace '<!-- DASHBOARD START -->.*?<!-- DASHBOARD END -->', $dashboardContent
 Set-Content -Path "README.md" -Value $newReadmeContent -Encoding UTF8
 Write-Host "[PASS] README.md dashboard section updated!" -ForegroundColor Green
 } else {
 # Insert dashboard before "## Contributing & Testing" section
 $contributingSection = '## Contributing & Testing'
 if ($readmeContent -match $contributingSection) {
 $newReadmeContent = $readmeContent -replace $contributingSection, "$dashboardContent`n`n$contributingSection"
 Set-Content -Path "README.md" -Value $newReadmeContent -Encoding UTF8
 Write-Host "[PASS] Dashboard section added to README.md!" -ForegroundColor Green
 } else {
 # Append to end of file
 $newReadmeContent = $readmeContent + "`n`n" + $dashboardContent
 Set-Content -Path "README.md" -Value $newReadmeContent -Encoding UTF8
 Write-Host "[PASS] Dashboard section appended to README.md!" -ForegroundColor Green
 }
 }
 } else {
 Write-Warning "README.md not found - cannot update"
 }
}

Write-Host "`n� Dashboard Generation Complete!" -ForegroundColor Cyan
Write-Host "Overall Health: $($dashboardData.OverallHealth) ($($dashboardData.HealthScore)%)" -ForegroundColor Cyan

if ($dashboardData.HealthScore -lt 85) {
 Write-Host "`n[WARN] Health score is below 85% - consider reviewing the recommendations above" -ForegroundColor Yellow
}




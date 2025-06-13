#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/infrastructure-health-check.ps1

<#
.SYNOPSIS
Comprehensive infrastructure health check and issue tracking.

.DESCRIPTION
This script provides a comprehensive health check of the project infrastructure
without relying on existing test results. It analyzes the current state and 
generates actionable reports.

.PARAMETER Mode
Mode to run: Quick, Full, Report, All

.PARAMETER AutoFix
Automatically apply fixes where possible

.EXAMPLE
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Full" -AutoFix
#>

[CmdletBinding()]
param(
    [Parameter()






]
    [ValidateSet('Quick', 'Full', 'Report', 'All')]
    [string]$Mode = 'Full',
    
    [Parameter()]
    [switch]$AutoFix
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "/workspaces/opentofu-lab-automation"
$ReportPath = "$ProjectRoot/docs/reports/project-status"

function Write-HealthLog {
    param([string]$Message, [string]$Level = "INFO")
    






$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "HEALTH" { "Magenta" }
        "FIX" { "Blue" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    






try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $FilePath -Raw), [ref]$null)
        return $true
    }
    catch {
        return $false
    }
}

function Get-InfrastructureHealth {
    Write-HealthLog "Running infrastructure health check..." "HEALTH"
    
    $health = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OverallStatus = "Unknown"
        Issues = @()
        Metrics = @{}
        Recommendations = @()
    }
    
    # 1. Check PowerShell script syntax
    Write-HealthLog "Checking PowerShell syntax..." "INFO"
    $psFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1", "*.psm1" -Exclude "archive/*", "backups/*", "cleanup-backup*"
    $syntaxIssues = @()
    
    foreach ($file in $psFiles) {
        if (-not (Test-PowerShellSyntax $file.FullName)) {
            $syntaxIssues += $file.FullName.Replace($ProjectRoot, ".")
        }
    }
    
    if ($syntaxIssues.Count -gt 0) {
        $health.Issues += @{
            Category = "PowerShell Syntax"
            Severity = "High"
            Count = $syntaxIssues.Count
            Description = "PowerShell files with syntax errors"
            Files = $syntaxIssues[0..4]  # Show first 5
            Fix = "./scripts/maintenance/fix-test-syntax.ps1"
        }
    }
    
    # 2. Check for missing command mocks
    Write-HealthLog "Checking TestHelpers.ps1..." "INFO"
    $testHelpersPath = "$ProjectRoot/tests/helpers/TestHelpers.ps1"
    $missingMocks = @()
    
    if (Test-Path $testHelpersPath) {
        $content = Get-Content $testHelpersPath -Raw
        $requiredMocks = @("Format-Config", "Invoke-LabStep", "Write-Continue", "Get-Platform", "Get-LabConfig")
        
        foreach ($mock in $requiredMocks) {
            if ($content -notmatch "function.*$mock") {
                $missingMocks += $mock
            }
        }
    } else {
        $missingMocks = $requiredMocks
    }
    
    if ($missingMocks.Count -gt 0) {
        $health.Issues += @{
            Category = "Missing Test Mocks"
            Severity = "Medium"
            Count = $missingMocks.Count
            Description = "Missing mock functions in TestHelpers.ps1"
            Details = $missingMocks
            Fix = "./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix MissingCommands"
        }
    }
    
    # 3. Check import paths
    Write-HealthLog "Checking import paths..." "INFO"
    $deprecatedImports = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1", "*.psm1" | 
        Select-String -Pattern "pwsh/lab_utils" -SimpleMatch -ErrorAction SilentlyContinue
    
    if ($deprecatedImports.Count -gt 0) {
        $health.Issues += @{
            Category = "Deprecated Import Paths"
            Severity = "Medium"
            Count = $deprecatedImports.Count
            Description = "Files using old lab_utils import paths"
            Files = $deprecatedImports.Filename | Select-Object -First 5
            Fix = "./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix ImportPaths"
        }
    }
    
    # 4. Check module structure
    Write-HealthLog "Checking module structure..." "INFO"
    $moduleIssues = @()
    
    $expectedModules = @("LabRunner", "CodeFixer")
    foreach ($module in $expectedModules) {
        $modulePath = "$ProjectRoot/pwsh/modules/$module"
        if (-not (Test-Path $modulePath)) {
            $moduleIssues += "Missing module: $module"
        } else {
            $manifestPath = "$modulePath/$module.psd1"
            if (-not (Test-Path $manifestPath)) {
                $moduleIssues += "Missing manifest: $module.psd1"
            }
        }
    }
    
    if ($moduleIssues.Count -gt 0) {
        $health.Issues += @{
            Category = "Module Structure"
            Severity = "High"
            Count = $moduleIssues.Count
            Description = "Module structure problems"
            Details = $moduleIssues
            Fix = "Manual module restructuring required"
        }
    }
    
    # 5. Check for test organization
    Write-HealthLog "Checking test organization..." "INFO"
    $testFiles = Get-ChildItem -Path "$ProjectRoot/tests" -Include "*.Tests.ps1" -Recurse
    $testIssues = @()
    
    # Look for tests that might have container issues
    foreach ($testFile in $testFiles) {
        $content = Get-Content $testFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match 'Describe\s+"[^"]*"\s+\{[^}]*Describe\s+"' -or 
            $content -match 'Context\s+"[^"]*"\s+\{[^}]*Context\s+"') {
            $testIssues += $testFile.Name
        }
    }
    
    if ($testIssues.Count -gt 0) {
        $health.Issues += @{
            Category = "Test Structure"
            Severity = "Medium"
            Count = $testIssues.Count
            Description = "Tests with nested container issues"
            Files = $testIssues[0..4]
            Fix = "./scripts/maintenance/fix-test-syntax.ps1"
        }
    }
    
    # Calculate overall status
    $criticalIssues = ($health.Issues | Where-Object { $_.Severity -eq "High" -or $_.Severity -eq "Critical" }).Count
    $health.OverallStatus = switch ($criticalIssues) {
        0 { if ($health.Issues.Count -eq 0) { "Healthy" } else { "Good" } }
        { $_ -le 2 } { "Warning" }
        default { "Critical" }
    }
    
    # Add metrics
    $health.Metrics = @{
        TotalPowerShellFiles = $psFiles.Count
        SyntaxErrorFiles = $syntaxIssues.Count
        DeprecatedImports = $deprecatedImports.Count
        MissingMocks = $missingMocks.Count
        TestFiles = $testFiles.Count
        IssueCount = $health.Issues.Count
    }
    
    # Add recommendations
    if ($health.Issues.Count -gt 0) {
        $health.Recommendations += "Run automated fixes: ./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix All"
    }
    if ($syntaxIssues.Count -gt 0) {
        $health.Recommendations += "Fix syntax errors: ./scripts/maintenance/fix-test-syntax.ps1"
    }
    if ($missingMocks.Count -gt 0) {
        $health.Recommendations += "Update TestHelpers.ps1 with missing mock functions"
    }
    
    return $health
}

function Generate-HealthReport {
    param([object]$Health)
    
    






# Ensure report directory exists
    if (-not (Test-Path $ReportPath)) {
        New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
    }
    
    $statusIcon = switch ($Health.OverallStatus) {
        "Healthy" { "✅" }
        "Good" { "🟢" }
        "Warning" { "⚠️" }
        "Critical" { "❌" }
        default { "❓" }
    }
    
    $reportContent = @"
# Infrastructure Health Report - $(Get-Date -Format "yyyy-MM-dd")

**Analysis Time**: $($Health.Timestamp)  
**Overall Status**: $statusIcon **$($Health.OverallStatus)**

## Health Metrics

| Metric | Value | Status |
|--------|-------|--------|
| **PowerShell Files** | $($Health.Metrics.TotalPowerShellFiles) | ℹ️ |
| **Syntax Errors** | $($Health.Metrics.SyntaxErrorFiles) | $(if($Health.Metrics.SyntaxErrorFiles -eq 0) { "✅" } else { "❌" }) |
| **Deprecated Imports** | $($Health.Metrics.DeprecatedImports) | $(if($Health.Metrics.DeprecatedImports -eq 0) { "✅" } else { "⚠️" }) |
| **Missing Mocks** | $($Health.Metrics.MissingMocks) | $(if($Health.Metrics.MissingMocks -eq 0) { "✅" } else { "⚠️" }) |
| **Test Files** | $($Health.Metrics.TestFiles) | ℹ️ |
| **Total Issues** | $($Health.Metrics.IssueCount) | $(if($Health.Metrics.IssueCount -eq 0) { "✅" } elseif($Health.Metrics.IssueCount -le 3) { "⚠️" } else { "❌" }) |

"@

    if ($Health.Issues.Count -gt 0) {
        $reportContent += @"

## Issues Detected

"@
        foreach ($issue in $Health.Issues) {
            $severityIcon = switch ($issue.Severity) {
                "Critical" { "🔴" }
                "High" { "🟠" }
                "Medium" { "🟡" }
                "Low" { "🟢" }
            }
            
            $reportContent += @"

### $severityIcon **$($issue.Category)** - $($issue.Severity) Priority
- **Count**: $($issue.Count)
- **Description**: $($issue.Description)
- **Fix Command**: ``$($issue.Fix)``

"@
            if ($issue.Files) {
                $reportContent += "- **Example Files**: $($issue.Files -join ', ')`n"
            }
            if ($issue.Details) {
                $reportContent += "- **Details**: $($issue.Details -join ', ')`n"
            }
        }
    } else {
        $reportContent += @"

## ✅ No Issues Detected

The infrastructure appears to be in good health!

"@
    }
    
    if ($Health.Recommendations.Count -gt 0) {
        $reportContent += @"

## Recommended Actions

"@
        foreach ($rec in $Health.Recommendations) {
            $reportContent += "- $rec`n"
        }
    }
    
    $reportContent += @"

## Quick Fix Commands

``````powershell
# Run comprehensive infrastructure fixes
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "All"

# Fix syntax errors specifically
./scripts/maintenance/fix-test-syntax.ps1

# Run this health check again
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Full"

# Generate a new report
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Report"
``````

---

*This report analyzes the current state without running tests. For test-specific issues, run the comprehensive test suite.*
"@

    $reportFile = "$ReportPath/$(Get-Date -Format "yyyy-MM-dd")-infrastructure-health.md"
    $reportContent | Set-Content $reportFile
    
    Write-HealthLog "Generated health report: $reportFile" "SUCCESS"
    return $reportFile
}

function Apply-AutoFixes {
    param([object]$Health)
    
    






if (-not $AutoFix) {
        return
    }
    
    Write-HealthLog "Applying automatic fixes..." "FIX"
    
    foreach ($issue in $Health.Issues) {
        if ($issue.Fix -like "*fix-infrastructure-issues.ps1*" -or $issue.Fix -like "*fix-test-syntax.ps1*") {
            try {
                Write-HealthLog "Applying fix: $($issue.Fix)" "FIX"
                Invoke-Expression $issue.Fix
            }
            catch {
                Write-HealthLog "Fix failed: $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

function Update-ReportIndex {
    param([string]$ReportFile)
    
    






$indexPath = "$ProjectRoot/docs/reports/INDEX.md"
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw
        $newEntry = "- [$(Get-Date -Format "yyyy-MM-dd") Infrastructure Health]($($ReportFile.Replace($ProjectRoot, '.')))"
        
        # Add to project-status section
        if ($content -match "(### Project Status Reports.*?\n)(.*?)((?:\n### |\n\n|$))") {
            $beforeMatch = $matches[1]
            $existingEntries = $matches[2]
            $afterMatch = $matches[3]
            
            # Check if entry already exists
            if ($existingEntries -notmatch [regex]::Escape($newEntry)) {
                $updatedEntries = "$existingEntries$newEntry`n"
                $updatedContent = $content -replace [regex]::Escape($matches[0]), "$beforeMatch$updatedEntries$afterMatch"
                Set-Content $indexPath $updatedContent
                Write-HealthLog "Updated report index" "SUCCESS"
            }
        }
    }
}

# Main execution
Write-HealthLog "Starting infrastructure health check in mode: $Mode" "HEALTH"

try {
    switch ($Mode) {
        'Quick' {
            $health = Get-InfrastructureHealth
            Write-HealthLog "Quick check complete - Status: $($health.OverallStatus)" "SUCCESS"
            Write-HealthLog "Issues found: $($health.Issues.Count)" "INFO"
        }
        
        'Full' {
            $health = Get-InfrastructureHealth
            Apply-AutoFixes $health
            Write-HealthLog "Full check complete - Status: $($health.OverallStatus)" "SUCCESS"
            
            # Save health data
            $healthFile = "$ReportPath/current-health.json"
            if (-not (Test-Path $ReportPath)) {
                New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
            }
            $health | ConvertTo-Json -Depth 10 | Set-Content $healthFile
        }
        
        'Report' {
            $healthFile = "$ReportPath/current-health.json"
            if (Test-Path $healthFile) {
                $health = Get-Content $healthFile | ConvertFrom-Json
            } else {
                $health = Get-InfrastructureHealth
            }
            
            $reportFile = Generate-HealthReport $health
            Update-ReportIndex $reportFile
        }
        
        'All' {
            $health = Get-InfrastructureHealth
            Apply-AutoFixes $health
            $reportFile = Generate-HealthReport $health
            Update-ReportIndex $reportFile
            
            # Save health data
            $healthFile = "$ReportPath/current-health.json"
            if (-not (Test-Path $ReportPath)) {
                New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
            }
            $health | ConvertTo-Json -Depth 10 | Set-Content $healthFile
            
            Write-HealthLog "Complete health check finished - Status: $($health.OverallStatus)" "SUCCESS"
        }
    }
}
catch {
    Write-HealthLog "Health check failed: $($_.Exception.Message)" "ERROR"
    exit 1
}




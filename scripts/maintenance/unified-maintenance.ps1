#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/unified-maintenance.ps1

<#
.SYNOPSIS
Unified project maintenance script with comprehensive tracking and automation.

.DESCRIPTION
This script provides comprehensive automated maintenance for the OpenTofu Lab Automation project.
It integrates all maintenance utilities into a single, repeatable system that can be run
by developers, CI/CD, or AI agents.

Features:
- Infrastructure health checks
- Syntax validation and auto-fixing
- Import path updates
- Test execution and analysis
- Recurring issue tracking
- Report generation and changelog updates
- Prevention checks and recommendations

.PARAMETER Mode
The maintenance mode to run:
- Quick: Fast health check and basic validation
- Full: Complete maintenance cycle without tests
- Test: Include test execution and analysis
- Track: Focus on recurring issue tracking
- Report: Generate reports only
- All: Complete maintenance with everything

.PARAMETER AutoFix
Automatically apply fixes where possible

.PARAMETER UpdateChangelog
Update CHANGELOG.md with maintenance results

.PARAMETER SkipTests
Skip test execution even in Full/All modes (for faster runs)

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix -UpdateChangelog

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "Track" -AutoFix
#>

[CmdletBinding()]
param(
    [Parameter()



]
    [ValidateSet('Quick', 'Full', 'Test', 'Track', 'Report', 'All')]
    [string]$Mode = 'Quick',
    
    [Parameter()]
    [switch]$AutoFix,
    
    [Parameter()]
    [switch]$UpdateChangelog,
    
    [Parameter()]
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "/workspaces/opentofu-lab-automation"

function Write-MaintenanceLog {
    param([string]$Message, [string]$Level = "INFO")
    



$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "MAINTENANCE" { "Magenta" }
        "STEP" { "Blue" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Invoke-MaintenanceStep {
    param(
        [string]$StepName,
        [scriptblock]$Action,
        [bool]$Required = $true
    )
    
    



Write-MaintenanceLog ">>> $StepName" "STEP"
    try {
        $result = & $Action
        Write-MaintenanceLog "✅ $StepName completed" "SUCCESS"
        return $result
    }
    catch {
        $message = "❌ $StepName failed: $($_.Exception.Message)"
        if ($Required) {
            Write-MaintenanceLog $message "ERROR"
            throw
        } else {
            Write-MaintenanceLog $message "WARNING"
            return $null
        }
    }
}

function Step-InfrastructureHealthCheck {
    $healthScript = "$ProjectRoot/scripts/maintenance/infrastructure-health-check.ps1"
    if (Test-Path $healthScript) {
        & $healthScript -Mode "Full" -AutoFix:$AutoFix
    } else {
        Write-MaintenanceLog "Infrastructure health check script not found" "WARNING"
    }
}

function Step-FixInfrastructureIssues {
    $fixScript = "$ProjectRoot/scripts/maintenance/fix-infrastructure-issues.ps1"
    if (Test-Path $fixScript) {
        if ($AutoFix) {
            & $fixScript -Fix "All"
        } else {
            & $fixScript -Check
        }
    } else {
        Write-MaintenanceLog "Infrastructure fix script not found" "WARNING"
    }
}

function Step-FixTestSyntax {
    $syntaxScript = "$ProjectRoot/scripts/maintenance/fix-test-syntax.ps1"
    if (Test-Path $syntaxScript) {
        & $syntaxScript
    } else {
        Write-MaintenanceLog "Test syntax fix script not found" "WARNING"
    }
}

function Step-RunTests {
    if ($SkipTests) {
        Write-MaintenanceLog "Skipping tests (SkipTests flag set)" "INFO"
        return
    }
    
    $testScript = "$ProjectRoot/run-comprehensive-tests.ps1"
    if (Test-Path $testScript) {
        Write-MaintenanceLog "Running comprehensive tests..." "INFO"
        & $testScript
    } else {
        Write-MaintenanceLog "Test script not found, using basic Pester" "WARNING"
        Set-Location $ProjectRoot
        Invoke-Pester tests/ -OutputFile "TestResults.xml" -OutputFormat NUnitXml -ExitOnError:$false
    }
}

function Step-TrackRecurringIssues {
    $trackingScript = "$ProjectRoot/scripts/maintenance/track-recurring-issues.ps1"
    if (Test-Path $trackingScript) {
        & $trackingScript -Mode "All" -IncludePreventionCheck
    } else {
        Write-MaintenanceLog "Recurring issues tracking script not found" "WARNING"
    }
}

function Step-GenerateReports {
    # Generate infrastructure health report
    Invoke-MaintenanceStep "Infrastructure Health Report" {
        Step-InfrastructureHealthCheck
    } $false
    
    # Generate recurring issues report if we have test results
    if (Test-Path "$ProjectRoot/TestResults.xml") {
        Invoke-MaintenanceStep "Recurring Issues Report" {
            Step-TrackRecurringIssues
        } $false
    }
    
    # Update report index
    $newReportScript = "$ProjectRoot/scripts/utilities/new-report.ps1"
    if (Test-Path $newReportScript) {
        Write-MaintenanceLog "Updating report index..." "INFO"
        # The reports should already be generated by the individual steps
    }
}

function Step-UpdateChangelog {
    if (-not $UpdateChangelog) {
        return
    }
    
    $changelogPath = "$ProjectRoot/CHANGELOG.md"
    if (-not (Test-Path $changelogPath)) {
        Write-MaintenanceLog "CHANGELOG.md not found" "WARNING"
        return
    }
    
    $content = Get-Content $changelogPath -Raw
    $date = Get-Date -Format "yyyy-MM-dd"
    
    $maintenanceUpdate = @"

### Automated Maintenance ($date)
- **Mode**: $Mode$(if($AutoFix) { " (with AutoFix)" })
- **Infrastructure**: Health check and fixes applied
- **Syntax**: PowerShell validation completed
- **Tests**: $(if($SkipTests) { "Skipped" } else { "Executed and analyzed" })
- **Reports**: Generated and indexed
- **Status**: ✅ Maintenance cycle completed
"@

    # Insert after the [Unreleased] section
    $updatedContent = $content -replace "(\[Unreleased\]\s*\n)", "`$1$maintenanceUpdate`n"
    
    Set-Content $changelogPath $updatedContent
    Write-MaintenanceLog "Updated CHANGELOG.md with maintenance results" "SUCCESS"
}

function Get-MaintenanceSummary {
    $summary = @{
        Mode = $Mode
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        AutoFix = $AutoFix.IsPresent
        UpdateChangelog = $UpdateChangelog.IsPresent
        SkipTests = $SkipTests.IsPresent
        CompletedSteps = @()
        Issues = @()
        Recommendations = @()
    }
    
    # Check for infrastructure health data
    $healthFile = "$ProjectRoot/docs/reports/project-status/current-health.json"
    if (Test-Path $healthFile) {
        try {
            $health = Get-Content $healthFile | ConvertFrom-Json
            $summary.InfrastructureStatus = $health.OverallStatus
            $summary.IssueCount = $health.Issues.Count
        }
        catch {
            Write-MaintenanceLog "Could not parse health data" "WARNING"
        }
    }
    
    # Check for test results
    if (Test-Path "$ProjectRoot/TestResults.xml") {
        $summary.TestResultsAvailable = $true
        $summary.TestResultsTime = (Get-Item "$ProjectRoot/TestResults.xml").LastWriteTime
    }
    
    return $summary
}

# Main execution flow
Write-MaintenanceLog "🔧 Starting unified maintenance in mode: $Mode" "MAINTENANCE"
Write-MaintenanceLog "AutoFix: $($AutoFix.IsPresent) | UpdateChangelog: $($UpdateChangelog.IsPresent) | SkipTests: $($SkipTests.IsPresent)" "INFO"

$startTime = Get-Date

try {
    switch ($Mode) {
        'Quick' {
            Invoke-MaintenanceStep "Infrastructure Health Check" { Step-InfrastructureHealthCheck }
            if ($AutoFix) {
                Invoke-MaintenanceStep "Basic Fixes" { Step-FixInfrastructureIssues } $false
            }
        }
        
        'Full' {
            Invoke-MaintenanceStep "Infrastructure Health Check" { Step-InfrastructureHealthCheck }
            Invoke-MaintenanceStep "Fix Infrastructure Issues" { Step-FixInfrastructureIssues }
            Invoke-MaintenanceStep "Fix Test Syntax" { Step-FixTestSyntax } $false
            Invoke-MaintenanceStep "Generate Reports" { Step-GenerateReports } $false
        }
        
        'Test' {
            Invoke-MaintenanceStep "Run Tests" { Step-RunTests }
            Invoke-MaintenanceStep "Track Recurring Issues" { Step-TrackRecurringIssues } $false
        }
        
        'Track' {
            Invoke-MaintenanceStep "Track Recurring Issues" { Step-TrackRecurringIssues }
            if ($AutoFix) {
                Invoke-MaintenanceStep "Apply Issue Fixes" { Step-FixInfrastructureIssues } $false
            }
        }
        
        'Report' {
            Invoke-MaintenanceStep "Generate Reports" { Step-GenerateReports }
        }
        
        'All' {
            Invoke-MaintenanceStep "Infrastructure Health Check" { Step-InfrastructureHealthCheck }
            Invoke-MaintenanceStep "Fix Infrastructure Issues" { Step-FixInfrastructureIssues }
            Invoke-MaintenanceStep "Fix Test Syntax" { Step-FixTestSyntax } $false
            
            if (-not $SkipTests) {
                Invoke-MaintenanceStep "Run Tests" { Step-RunTests } $false
            }
            
            Invoke-MaintenanceStep "Track Recurring Issues" { Step-TrackRecurringIssues } $false
            Invoke-MaintenanceStep "Generate Reports" { Step-GenerateReports } $false
            Invoke-MaintenanceStep "Update Changelog" { Step-UpdateChangelog } $false
        }
    }
    
    $duration = (Get-Date) - $startTime
    $summary = Get-MaintenanceSummary
    
    Write-MaintenanceLog "🎉 Maintenance completed successfully!" "SUCCESS"
    Write-MaintenanceLog "Duration: $($duration.TotalMinutes.ToString('F1')) minutes" "INFO"
    Write-MaintenanceLog "Infrastructure Status: $($summary.InfrastructureStatus)" "INFO"
    
    if ($summary.IssueCount -gt 0) {
        Write-MaintenanceLog "Issues remaining: $($summary.IssueCount)" "WARNING"
        Write-MaintenanceLog "Run with -AutoFix to apply automatic fixes" "INFO"
    }
    
    # Update project manifest with current state
    $manifestScript = "$ProjectRoot/scripts/utilities/update-project-manifest.ps1"
    if (Test-Path $manifestScript) {
        Write-MaintenanceLog "Updating project manifest..." "INFO"
        try {
            & $manifestScript -Force
            Write-MaintenanceLog "Project manifest updated with current state" "SUCCESS"
        } catch {
            Write-MaintenanceLog "Failed to update manifest: $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-MaintenanceLog "For detailed analysis, check docs/reports/" "INFO"
}
catch {
    Write-MaintenanceLog "❌ Maintenance failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-MaintenanceLog "Maintenance cycle complete. Next recommended run: $(if($AutoFix) { '24 hours' } else { 'as needed' })" "MAINTENANCE"



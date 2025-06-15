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
    [Parameter()]
    [ValidateSet('Quick', 'Full', 'Report', 'All')]
    [string]$Mode = 'Full',
    
    [Parameter()]
    [switch]$AutoFix
)

$ErrorActionPreference = "Stop"

# Detect the correct project root
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $projectRoot = "/workspaces/opentofu-lab-automation"
}

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

function Test-ProjectStructure {
    Write-HealthLog "Checking project structure..." "INFO"

    $requiredDirs = @{
        "scripts" = "Core automation scripts"
        "pwsh" = "PowerShell modules and utilities"
        "tests" = "Test framework and test files"
        ".github" = "GitHub Actions workflows"
        "configs" = "Configuration files"
        "docs" = "Documentation"
        "backups" = "Backup storage"
    }

    $structureCheck = @{
        Name = "ProjectStructure"
        Passed = $true
        Issues = @()
        Details = @{}
    }

    # Check each directory
    foreach ($dirName in $requiredDirs.Keys) {
        $dirPath = Join-Path $projectRoot $dirName
        if (Test-Path $dirPath) {
            Write-HealthLog "✓ Directory exists: $dirName" "SUCCESS"
            $structureCheck.Details[$dirName] = "EXISTS"
        } else {
            Write-HealthLog "✗ Directory missing: $dirName" "ERROR"
            $structureCheck.Issues += "Missing directory: $dirName"
            $structureCheck.Passed = $false

            if ($AutoFix) {
                try {
                    New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
                    Write-HealthLog "✓ Created missing directory: $dirName" "FIX"
                    $structureCheck.Details[$dirName] = "CREATED"
                } catch {
                    Write-HealthLog "✗ Failed to create directory: $dirName - $_" "ERROR"
                    $structureCheck.Details[$dirName] = "FAILED"
                }
            } else {
                $structureCheck.Details[$dirName] = "MISSING"
            }
        }
    }

    return $structureCheck
}

function Test-ModuleHealth {
    Write-HealthLog "Checking module health..." "INFO"
    
    $moduleCheck = @{
        Name = "ModuleHealth"
        Passed = $true
        Issues = @()
        Details = @{}
    }
      $modulesDirs = @(
        "pwsh/modules/LabRunner",
        "pwsh/modules/CodeFixer",
        "pwsh/modules/BackupManager"
    )
    
    foreach ($moduleDir in $modulesDirs) {
        $modulePath = Join-Path $projectRoot $moduleDir
        if (Test-Path $modulePath) {
            Write-HealthLog "✓ Module directory exists: $moduleDir" "SUCCESS"
            $moduleCheck.Details[$moduleDir] = "EXISTS"
        } else {
            Write-HealthLog "✗ Module directory missing: $moduleDir" "ERROR"
            $moduleCheck.Issues += "Missing module directory: $moduleDir"
            $moduleCheck.Passed = $false
            $moduleCheck.Details[$moduleDir] = "MISSING"
        }
    }
    
    return $moduleCheck
}

function Test-ConfigurationFiles {
    Write-HealthLog "Validating configuration files..." "INFO"
    
    $configCheck = @{
        Name = "ConfigurationFiles"
        Passed = $true
        Issues = @()
        Details = @{}
    }
    
    $configFiles = @{
        "PROJECT-MANIFEST.json" = "Project manifest"
        "configs/lab_config.yaml" = "Lab configuration"
        "configs/yamllint.yaml" = "YAML lint configuration"
    }
    
    foreach ($file in $configFiles.Keys) {
        $filePath = Join-Path $projectRoot $file
        if (Test-Path $filePath) {
            Write-HealthLog "✓ Configuration file exists: $file" "SUCCESS"
            $configCheck.Details[$file] = "EXISTS"
        } else {
            Write-HealthLog "✗ Missing configuration file: $file" "ERROR"
            $configCheck.Issues += "Missing configuration file: $file"
            $configCheck.Passed = $false
            $configCheck.Details[$file] = "MISSING"
        }
    }
    
    return $configCheck
}

function Test-GitHubWorkflows {
    Write-HealthLog "Checking GitHub Actions workflows..." "INFO"
    
    $workflowCheck = @{
        Name = "GitHubWorkflows"
        Passed = $true
        Issues = @()
        Details = @{}
    }
    
    $workflowDir = Join-Path $projectRoot ".github/workflows"
    
    if (Test-Path $workflowDir) {
        $workflows = Get-ChildItem -Path $workflowDir -Filter "*.yml" -ErrorAction SilentlyContinue
        $workflows += Get-ChildItem -Path $workflowDir -Filter "*.yaml" -ErrorAction SilentlyContinue
        
        $workflowCheck.Details.TotalWorkflows = $workflows.Count
        $workflowCheck.Details.ValidWorkflows = 0
        $workflowCheck.Details.InvalidWorkflows = 0
        
        Write-HealthLog "Found $($workflows.Count) workflow files" "INFO"
        
        foreach ($workflow in $workflows) {
            try {
                $content = Get-Content $workflow.FullName -Raw
                if ($content.Contains("name:") -and $content.Contains("on:") -and $content.Contains("jobs:")) {
                    $workflowCheck.Details.ValidWorkflows++
                    Write-HealthLog "✓ Workflow structure valid: $($workflow.Name)" "SUCCESS"
                } else {
                    $workflowCheck.Details.InvalidWorkflows++
                    $workflowCheck.Issues += "Invalid workflow structure: $($workflow.Name)"
                    $workflowCheck.Passed = $false
                    Write-HealthLog "✗ Invalid workflow structure: $($workflow.Name)" "ERROR"
                }
            } catch {
                $workflowCheck.Details.InvalidWorkflows++
                $workflowCheck.Issues += "Workflow parse error: $($workflow.Name)"
                $workflowCheck.Passed = $false
                Write-HealthLog "✗ Workflow parse error: $($workflow.Name)" "ERROR"
            }
        }
    } else {
        Write-HealthLog "✗ GitHub workflows directory missing" "ERROR"
        $workflowCheck.Passed = $false
        $workflowCheck.Issues += "GitHub workflows directory missing"
    }
    
    return $workflowCheck
}

function Test-PowerShellSyntax {
    Write-HealthLog "Running PowerShell syntax validation..." "INFO"
    
    $syntaxCheck = @{
        Name = "PowerShellSyntax"
        Passed = $true
        Issues = @()
        Details = @{
            ValidScripts = 0
            ErrorScripts = 0
        }
    }
      # Find PowerShell files (excluding archive directories)
    $scriptPaths = Get-ChildItem -Path $projectRoot -Include "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -notmatch "\\(archive|backups|deprecated|coverage|build)\\|\\archive$|\\backups$" }
    
    Write-HealthLog "Found $($scriptPaths.Count) PowerShell files to validate" "INFO"
    
    foreach ($script in $scriptPaths) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$null)
            $syntaxCheck.Details.ValidScripts++
        } catch {
            $syntaxCheck.Details.ErrorScripts++
            $syntaxCheck.Issues += "Syntax error in $($script.Name): $($_.Exception.Message)"
            $syntaxCheck.Passed = $false
            Write-HealthLog "✗ Syntax error in $($script.Name)" "ERROR"
        }
    }
    
    Write-HealthLog "Syntax validation completed. Valid: $($syntaxCheck.Details.ValidScripts), Errors: $($syntaxCheck.Details.ErrorScripts)" "INFO"
    
    return $syntaxCheck
}

function Test-GitHubActionsStatus {
    Write-HealthLog "Checking GitHub Actions status..." "INFO"

    $actionsCheck = @{
        Name = "GitHubActionsStatus"
        Passed = $true
        Issues = @()
        Details = @{
            TotalRuns = 0
            SuccessfulRuns = 0
            FailedRuns = 0
            RecentFailures = @()
            WorkflowStatuses = @{}
            LastChecked = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
    }

    try {
        # Check if GitHub CLI is available and authenticated
        $ghAuth = $null
        try {
            $ghAuth = & gh auth status 2>&1 | Out-String
            if ($ghAuth -notmatch "Logged in to github.com") {
                Write-HealthLog "GitHub CLI not authenticated - skipping Actions status check" "WARNING"
                $actionsCheck.Issues += "GitHub CLI not authenticated"
                $actionsCheck.Passed = $false
                return $actionsCheck
            }
        } catch {
            Write-HealthLog "GitHub CLI not available - skipping Actions status check" "WARNING"
            $actionsCheck.Issues += "GitHub CLI not available"
            $actionsCheck.Passed = $false
            return $actionsCheck
        }

        # Get recent workflow runs (last 10)
        $runsJson = & gh run list --limit 10 --json "id,conclusion,status,workflowName,createdAt,headBranch" 2>&1
        if ($runsJson) {
            $runs = $runsJson | ConvertFrom-Json
            $actionsCheck.Details.TotalRuns = $runs.Count

            foreach ($run in $runs) {
                $workflowName = $run.workflowName
                if (-not $actionsCheck.Details.WorkflowStatuses.ContainsKey($workflowName)) {
                    $actionsCheck.Details.WorkflowStatuses[$workflowName] = @{
                        LastStatus = $run.conclusion
                        LastRun = $run.createdAt
                        RunId = $run.id
                    }
                }

                if ($run.conclusion -eq "success") {
                    $actionsCheck.Details.SuccessfulRuns++
                } elseif ($run.conclusion -eq "failure") {
                    $actionsCheck.Details.FailedRuns++
                    $actionsCheck.Details.RecentFailures += @{
                        Workflow = $run.workflowName
                        RunId = $run.id
                        CreatedAt = $run.createdAt
                        Branch = $run.headBranch
                    }
                }
            }

            # Check failure rate
            $failureRate = if ($actionsCheck.Details.TotalRuns -gt 0) {
                [math]::Round(($actionsCheck.Details.FailedRuns / $actionsCheck.Details.TotalRuns) * 100, 1)
            } else { 0 }

            Write-HealthLog "GitHub Actions status: Total Runs=$($actionsCheck.Details.TotalRuns), Success=$($actionsCheck.Details.SuccessfulRuns), Failures=$($actionsCheck.Details.FailedRuns), Failure Rate=$failureRate%" "INFO"

            if ($failureRate -gt 50) {
                $actionsCheck.Passed = $false
                $actionsCheck.Issues += "High failure rate detected: $failureRate%"
            }
        } else {
            Write-HealthLog "Failed to retrieve GitHub Actions runs" "ERROR"
            $actionsCheck.Passed = $false
            $actionsCheck.Issues += "Failed to retrieve GitHub Actions runs"
        }
    } catch {
        Write-HealthLog "Error while checking GitHub Actions status: $($_.Exception.Message)" "ERROR"
        $actionsCheck.Passed = $false
        $actionsCheck.Issues += "Error while checking GitHub Actions status: $($_.Exception.Message)"
    }

    return $actionsCheck
}

function Save-WorkflowReports {
    param(
        [array]$Runs,
        [string]$ProjectRoot
    )
    
    Write-HealthLog "Saving automated workflow reports..." "INFO"
    
    try {
        # Create reports directory if it doesn't exist
        $reportsDir = Join-Path $ProjectRoot "docs/reports/workflow-runs"
        if (-not (Test-Path $reportsDir)) {
            New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
        }
        
        # Generate summary report
        $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        $summaryPath = Join-Path $reportsDir "workflow-summary-$timestamp.md"
        
        $summaryContent = @"
# GitHub Actions Workflow Summary Report
**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
**Total Runs Analyzed**: $($Runs.Count)

## Workflow Status Overview

| Workflow | Last Status | Last Run | Run ID |
|----------|-------------|----------|---------|
"@
        
        $workflowSummary = @{}
        foreach ($run in $Runs) {
            if (-not $workflowSummary.ContainsKey($run.workflowName)) {
                $status = switch ($run.conclusion) {
                    "success" { "✅ Success" }
                    "failure" { "❌ Failed" }
                    "cancelled" { "⏹️ Cancelled" }
                    default { "⏳ $($run.status)" }
                }
                
                $summaryContent += "| $($run.workflowName) | $status | $($run.createdAt) | [$($run.id)](https://github.com/$((gh repo view --json nameWithOwner | ConvertFrom-Json).nameWithOwner)/actions/runs/$($run.id)) |`n"
                $workflowSummary[$run.workflowName] = $true
            }
        }
        
        # Add failure analysis if there are failures
        $failures = $Runs | Where-Object { $_.conclusion -eq "failure" }
        if ($failures.Count -gt 0) {
            $summaryContent += @"

## Recent Failures Analysis

**Total Failures**: $($failures.Count) out of $($Runs.Count) runs

### Failed Runs:
"@
            foreach ($failure in $failures) {
                $summaryContent += @"

- **$($failure.workflowName)** (Run [$($failure.id)](https://github.com/$((gh repo view --json nameWithOwner | ConvertFrom-Json).nameWithOwner)/actions/runs/$($failure.id)))
  - Branch: $($failure.headBranch)
  - Time: $($failure.createdAt)
"@
            }
        }
        
        # Add recommendations
        $summaryContent += @"

## Recommendations

### Immediate Actions:
- Review failed workflow runs for common patterns
- Check if infrastructure changes are needed
- Verify all required secrets and variables are configured

### Monitoring:
- Set up notifications for workflow failures
- Regular review of workflow performance trends
- Update workflows based on failure patterns

---
*This report was automatically generated by the infrastructure health check system.*
"@
        
        # Save the summary report
        Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
        Write-HealthLog "✓ Workflow summary saved: $summaryPath" "SUCCESS"
        
        # Download artifacts from recent failed runs for analysis
        $failedRuns = $Runs | Where-Object { $_.conclusion -eq "failure" } | Select-Object -First 3
        foreach ($failedRun in $failedRuns) {
            try {
                $artifactDir = Join-Path $reportsDir "artifacts-$($failedRun.id)"
                if (-not (Test-Path $artifactDir)) {
                    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
                }
                
                # Download artifacts (if any)
                $artifactResult = & gh run download $failedRun.id --dir $artifactDir 2>&1
                if ($artifactResult -notmatch "no artifacts") {
                    Write-HealthLog "✓ Downloaded artifacts for failed run $($failedRun.id)" "INFO"
                    
                    # Create a summary for this specific run
                    $runSummaryPath = Join-Path $artifactDir "run-analysis.md"
                    $runSummary = @"
# Failed Run Analysis: $($failedRun.workflowName)

**Run ID**: $($failedRun.id)
**Branch**: $($failedRun.headBranch)
**Date**: $($failedRun.createdAt)
**Status**: $($failedRun.conclusion)

## Artifacts Downloaded
$(if (Test-Path $artifactDir) { (Get-ChildItem $artifactDir -Exclude "run-analysis.md" | ForEach-Object { "- $($_.Name)" }) -join "`n" } else { "No artifacts available" })

## Analysis Notes
- Check logs for error patterns
- Review test failures if present
- Verify environment configuration

## Next Steps
1. Review downloaded artifacts
2. Identify root cause
3. Apply fixes
4. Re-run workflow if needed

---
*Generated automatically on $(Get-Date)*
"@
                    Set-Content -Path $runSummaryPath -Value $runSummary -Encoding UTF8
                }
            } catch {
                Write-HealthLog "Could not download artifacts for run $($failedRun.id): $($_.Exception.Message)" "WARNING"
            }
        }
        
        # Create or update the main workflow dashboard
        Update-WorkflowDashboard -ProjectRoot $ProjectRoot -Runs $Runs
        
    } catch {
        Write-HealthLog "Error saving workflow reports: $($_.Exception.Message)" "ERROR"
    }
}

function Update-WorkflowDashboard {
    param(
        [string]$ProjectRoot,
        [array]$Runs
    )
    
    try {
        $dashboardPath = Join-Path $ProjectRoot "docs/reports/workflow-dashboard.md"
        
        # Calculate statistics
        $totalRuns = $Runs.Count
        $successRate = if ($totalRuns -gt 0) { 
            [math]::Round((($Runs | Where-Object { $_.conclusion -eq "success" }).Count / $totalRuns) * 100, 1) 
        } else { 0 }
        
        $dashboardContent = @"
# GitHub Actions Workflow Dashboard
**Last Updated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

## Overall Health Status
- **Success Rate**: $successRate% (last $totalRuns runs)
- **Total Workflows**: $(($Runs | Group-Object workflowName).Count)
- **Last Check**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Status Badge
$(if ($successRate -ge 90) { "🟢 **HEALTHY** - Workflows performing well" } 
  elseif ($successRate -ge 70) { "🟡 **WARNING** - Some issues detected" } 
  else { "🔴 **CRITICAL** - Multiple workflow failures" })

## Recent Activity
| Workflow | Status | Branch | Time | Run Link |
|----------|--------|--------|------|----------|
"@
        
        foreach ($run in $Runs | Select-Object -First 10) {
            $status = switch ($run.conclusion) {
                "success" { "✅" }
                "failure" { "❌" }
                "cancelled" { "⏹️" }
                default { "⏳" }
            }
            
            $runLink = "https://github.com/$((gh repo view --json nameWithOwner | ConvertFrom-Json).nameWithOwner)/actions/runs/$($run.id)"
            $dashboardContent += "| $($run.workflowName) | $status $($run.conclusion) | $($run.headBranch) | $($run.createdAt) | [View]($runLink) |`n"
        }
        
        # Add trends and recommendations
        $failures = $Runs | Where-Object { $_.conclusion -eq "failure" }
        if ($failures.Count -gt 0) {
            $dashboardContent += @"

## Failure Analysis
**Recent Failures**: $($failures.Count) out of $totalRuns runs

### Common Issues:
"@
            $failureGroups = $failures | Group-Object workflowName
            foreach ($group in $failureGroups) {
                $dashboardContent += "- **$($group.Name)**: $($group.Count) failure(s)`n"
            }
        }
        
        $dashboardContent += @"

## Maintenance Actions
- [ ] Review failed workflow logs
- [ ] Update workflow configurations if needed
- [ ] Check infrastructure dependencies
- [ ] Verify secrets and environment variables

---
*This dashboard is automatically updated by the infrastructure health check system.*
*For detailed reports, see the [workflow-runs](./workflow-runs/) directory.*
"@
        
        Set-Content -Path $dashboardPath -Value $dashboardContent -Encoding UTF8
        Write-HealthLog "✓ Workflow dashboard updated: $dashboardPath" "SUCCESS"
        
    } catch {
        Write-HealthLog "Error updating workflow dashboard: $($_.Exception.Message)" "ERROR"
    }
}

# Main execution
Write-HealthLog "Starting infrastructure health check in mode: $Mode" "INFO"
Write-HealthLog "Project root: $projectRoot" "INFO"
Write-HealthLog "AutoFix enabled: $($AutoFix.IsPresent)" "INFO"

# Initialize health check results
$healthResults = @{
    Timestamp = Get-Date
    Mode = $Mode
    AutoFix = $AutoFix.IsPresent
    ProjectRoot = $projectRoot
    Checks = @{}
    Summary = @{}
}

# Run health checks based on mode
switch ($Mode) {
    'Quick' {
        Write-HealthLog "Running quick health checks..." "INFO"
        $healthResults.Checks["ProjectStructure"] = Test-ProjectStructure
        $healthResults.Checks["ModuleHealth"] = Test-ModuleHealth
    }
    'Full' {
        Write-HealthLog "Running full health checks..." "INFO"
        $healthResults.Checks["ProjectStructure"] = Test-ProjectStructure
        $healthResults.Checks["ModuleHealth"] = Test-ModuleHealth
        $healthResults.Checks["ConfigurationFiles"] = Test-ConfigurationFiles
        $healthResults.Checks["GitHubWorkflows"] = Test-GitHubWorkflows
    }
    'All' {
        Write-HealthLog "Running comprehensive health checks..." "INFO"
        $healthResults.Checks["ProjectStructure"] = Test-ProjectStructure
        $healthResults.Checks["ModuleHealth"] = Test-ModuleHealth
        $healthResults.Checks["ConfigurationFiles"] = Test-ConfigurationFiles
        $healthResults.Checks["GitHubWorkflows"] = Test-GitHubWorkflows
        $healthResults.Checks["PowerShellSyntax"] = Test-PowerShellSyntax
    }
    'Report' {
        Write-HealthLog "Generating report only..." "INFO"
    }
}

# Calculate summary
$passedChecks = ($healthResults.Checks.Values | Where-Object { $_.Passed }).Count
$failedChecks = ($healthResults.Checks.Values | Where-Object { -not $_.Passed }).Count
$totalIssues = ($healthResults.Checks.Values | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum

$healthResults.Summary = @{
    TotalChecks = $healthResults.Checks.Keys.Count
    PassedChecks = $passedChecks
    FailedChecks = $failedChecks
    TotalIssues = $totalIssues
}

# Summary
Write-HealthLog "=== HEALTH CHECK SUMMARY ===" "HEALTH"
Write-HealthLog "Total checks: $($healthResults.Summary.TotalChecks)" "INFO"
Write-HealthLog "Passed: $($healthResults.Summary.PassedChecks)" "SUCCESS"
Write-HealthLog "Failed: $($healthResults.Summary.FailedChecks)" "ERROR"
Write-HealthLog "Total issues: $($healthResults.Summary.TotalIssues)" "WARNING"

# Show detailed results
foreach ($checkName in $healthResults.Checks.Keys) {
    $check = $healthResults.Checks[$checkName]
    if ($check.Issues.Count -gt 0) {
        Write-HealthLog "Issues in ${checkName}:" "WARNING"
        foreach ($issue in $check.Issues) {
            Write-HealthLog "  - $issue" "WARNING"
        }
    }
}

Write-HealthLog "Health check completed" "SUCCESS"

# Return appropriate exit code
if ($healthResults.Summary.FailedChecks -gt 0) {
    exit 1
} else {
    exit 0
}


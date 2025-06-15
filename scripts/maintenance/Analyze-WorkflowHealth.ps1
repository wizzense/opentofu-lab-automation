#!/usr/bin/env pwsh
#Requires -Version 7.0
#Requires -Modules CodeFixer

<#
.SYNOPSIS
    Comprehensive GitHub Actions workflow analysis and reporting tool.
.DESCRIPTION
    Analyzes GitHub Actions workflows, identifies issues, and generates detailed reports
    with recommendations for fixes. Integrates with the project's maintenance system.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Markdown", "JSON", "Host")]
    [string]$OutputFormat = "Markdown",
    
    [Parameter()]
    [string]$OutputPath = "./reports/workflow-health",
    
    [Parameter()]
    [switch]$AutoFix
)

$ErrorActionPreference = 'Stop'

if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module "/$ProjectRoot\pwsh\modules\CodeFixer" -Force -ErrorAction Stop
    Import-Module "/$ProjectRoot\pwsh\modules\LabRunner" -Force -ErrorAction Stop
} else {
    $ProjectRoot = "/workspaces/opentofu-lab-automation"
    Import-Module "/pwsh/modules/CodeFixer" -Force -ErrorAction Stop
    Import-Module "/pwsh/modules/LabRunner" -Force -ErrorAction Stop
}

function Get-WorkflowAnalysis {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Starting workflow analysis..." "INFO"
    
    # Get recent workflow runs
    $workflowRuns = gh run list --json status,conclusion,name,headSha,databaseId,workflowName,event,displayTitle --limit 100
    $runs = $workflowRuns | ConvertFrom-Json

    # Analyze patterns in failures
    $analysis = @{
        TotalRuns = $runs.Count
        FailedRuns = @($runs | Where-Object { $_.conclusion -eq 'failure' })
        SuccessRate = 0
        CommonFailures = @{}
        AffectedWorkflows = @{}
        TimeBasedPatterns = @{}
        RecommendedFixes = @()
    }

    # Calculate success rate
    $analysis.SuccessRate = ($runs.Count - $analysis.FailedRuns.Count) / $runs.Count * 100

    # Analyze each failed run in detail
    foreach ($failure in $analysis.FailedRuns) {
        $details = gh run view $failure.databaseId --json jobs
        $jobs = ($details | ConvertFrom-Json).jobs

        foreach ($job in $jobs | Where-Object { $_.conclusion -eq 'failure' }) {
            $errorPattern = Get-ErrorPattern -Steps $job.steps
            
            if (-not $analysis.CommonFailures.ContainsKey($errorPattern)) {
                $analysis.CommonFailures[$errorPattern] = 0
            }
            $analysis.CommonFailures[$errorPattern]++

            # Track affected workflows
            if (-not $analysis.AffectedWorkflows.ContainsKey($failure.workflowName)) {
                $analysis.AffectedWorkflows[$failure.workflowName] = @{
                    FailureCount = 0
                    Errors = @{}
                }
            }
            $analysis.AffectedWorkflows[$failure.workflowName].FailureCount++
            
            if (-not $analysis.AffectedWorkflows[$failure.workflowName].Errors.ContainsKey($errorPattern)) {
                $analysis.AffectedWorkflows[$failure.workflowName].Errors[$errorPattern] = 0
            }
            $analysis.AffectedWorkflows[$failure.workflowName].Errors[$errorPattern]++
        }
    }

    # Generate recommendations
    $analysis.RecommendedFixes = Get-FixRecommendations -Analysis $analysis

    return $analysis
}

function Get-ErrorPattern {
    param (
        [Parameter(Mandatory)]
        [object[]]$Steps
    )

    $failedSteps = $Steps | Where-Object { $_.conclusion -eq 'failure' }
    foreach ($step in $failedSteps) {
        if ($step.completed_at) {
            return "$(Split-Path -Leaf $step.name): $($step.conclusion)"
        }
    }
    return "Unknown error"
}

function Get-FixRecommendations {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Analysis
    )

    $recommendations = @()

    # Analyze common failure patterns and suggest fixes
    foreach ($failure in $Analysis.CommonFailures.GetEnumerator() | Sort-Object Value -Descending) {
        $recommendation = switch -Regex ($failure.Key) {
            'Setup-Directories: failure' {
                @{
                    Issue = "Directory setup failures"
                    Fix = "Update directory initialization in workflow to use absolute paths"
                    Priority = "High"
                    AutoFixable = $true
                    FixCommand = "Update-WorkflowPaths"
                }
            }
            'Install-Dependencies: failure' {
                @{
                    Issue = "Dependency installation failures"
                    Fix = "Update package versions and add retry logic"
                    Priority = "High"
                    AutoFixable = $true
                    FixCommand = "Update-DependencyHandling"
                }
            }
            'Run-Tests: failure' {
                @{
                    Issue = "Test execution failures"
                    Fix = "Add error handling and test result collection"
                    Priority = "Medium"
                    AutoFixable = $false
                    FixCommand = $null
                }
            }
            default {
                @{
                    Issue = $failure.Key
                    Fix = "Manual investigation required"
                    Priority = "Low"
                    AutoFixable = $false
                    FixCommand = $null
                }
            }
        }
        
        $recommendation['Occurrences'] = $failure.Value
        $recommendations += $recommendation
    }

    return $recommendations
}

function New-WorkflowReport {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Analysis
    )

    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $reportPath = "./docs/reports/workflow-analysis/workflow-health-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

    $report = @"
# GitHub Actions Workflow Health Report
Generated: $reportDate

## Executive Summary
- Total Runs Analyzed: $($Analysis.TotalRuns)
- Success Rate: $([math]::Round($Analysis.SuccessRate, 2))%
- Failed Runs: $($Analysis.FailedRuns.Count)
- Affected Workflows: $($Analysis.AffectedWorkflows.Count)

## Failure Analysis

### Common Failure Patterns
$(($Analysis.CommonFailures.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
"- $($_.Key): $($_.Value) occurrences"
}) -join "`n")

### Affected Workflows
$(($Analysis.AffectedWorkflows.GetEnumerator() | Sort-Object {$_.Value.FailureCount} -Descending | ForEach-Object {
@"
#### $($_.Key)
- Total Failures: $($_.Value.FailureCount)
- Error Distribution:
$(($_.Value.Errors.GetEnumerator() | ForEach-Object {"  - $($_.Key): $($_.Value) times"}) -join "`n")
"@
}) -join "`n`n")

## Recommendations
$(($Analysis.RecommendedFixes | ForEach-Object {
@"
### $($_.Issue)
- Fix: $($_.Fix)
- Priority: $($_.Priority)
- Auto-Fixable: $($_.AutoFixable)
- Occurrences: $($_.Occurrences)
"@
}) -join "`n`n")

## Action Items
1. Apply automated fixes for high-priority issues
2. Review and update workflow configurations
3. Implement error handling improvements
4. Update dependency management
5. Add comprehensive logging

## Next Steps
Run maintenance script with fixes:
\`\`\`powershell
./scripts/maintenance/Analyze-WorkflowHealth.ps1 -FixIssues
\`\`\`
"@

    # Create report directory if it doesn't exist
    $reportDir = Split-Path $reportPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    # Save report
    Set-Content -Path $reportPath -Value $report
    Write-CustomLog "Report generated at: $reportPath" "INFO"

    return $reportPath
}

function Start-WorkflowAnalysis {
    [CmdletBinding()]
    param()

    try {
        Write-CustomLog "Starting workflow analysis process..." "INFO"

        # Run analysis
        $analysis = Get-WorkflowAnalysis

        # Generate report if requested
        if ($GenerateReport) {
            $reportPath = New-WorkflowReport -Analysis $analysis
            Write-CustomLog "Report generated at: $reportPath" "SUCCESS"
        }

        # Apply fixes if requested
        if ($FixIssues) {
            Write-CustomLog "Applying automated fixes..." "INFO"
            foreach ($fix in $analysis.RecommendedFixes | Where-Object { $_.AutoFixable -eq $true }) {
                Write-CustomLog "Applying fix for: $($fix.Issue)" "INFO"
                & $fix.FixCommand
            }
        }

        # Run validation if requested
        if ($RunValidation) {
            Write-CustomLog "Running workflow validation..." "INFO"
            & "$PSScriptRoot/scripts/validation/Invoke-YamlValidation.ps1" -Mode "Check" -Path ".github/workflows"
        }

        return @{
            Success = $true
            Analysis = $analysis
            ReportPath = $reportPath
        }
    }
    catch {
        Write-CustomLog "Error during workflow analysis: $_" "ERROR"
        return @{
            Success = $false
            Error = $_
            Analysis = $null
            ReportPath = $null
        }
    }
}

# Main execution
$result = Start-WorkflowAnalysis
if (-not $result.Success) {
    exit 1
}


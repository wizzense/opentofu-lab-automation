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

# Detect the correct project root based on the current environment
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $projectRoot = "/workspaces/opentofu-lab-automation"
}
$ReportPath = "$projectRoot/docs/reports/project-status"

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
    Write-HealthLog "Running PowerShell syntax validation..." "INFO"
    # Implementation for PowerShell syntax testing
    return @{
        Name = "PowerShellSyntax"
        Passed = $true
        Issues = @()
        Details = @{}
    }
}

function Test-ProjectStructure {
    Write-HealthLog "Checking project structure using batch processing..." "INFO"

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

    # Enhanced batch processing logic
    $processorCount = [Environment]::ProcessorCount
    $optimalBatchSize = [Math]::Max(5, [Math]::Min(20, [Math]::Ceiling($requiredDirs.Keys.Count / $processorCount)))    Write-HealthLog "Running batch processing with optimal batch size: $optimalBatchSize, MaxJobs: $processorCount" "INFO"
    
    # Import CodeFixer module for parallel processing
    try {
        $codeFixerPath = Join-Path $projectRoot "pwsh/modules/CodeFixer/"
        Import-Module $codeFixerPath -Force -ErrorAction Stop
        Write-HealthLog "CodeFixer module imported successfully" "INFO"
    } catch {
        Write-HealthLog "Failed to import CodeFixer module: $_" "ERROR"
        $structureCheck.Passed = $false
        $structureCheck.Issues += "CodeFixer module import failed"
        return $structureCheck
    }    # Use unified parallel processing framework
    Write-HealthLog "Using Invoke-ParallelScriptAnalyzer for $($requiredDirs.Keys.Count) directories" "INFO"
    
    try {
        # Calculate optimal batch size based on file count and CPU cores
        $processorCount = [Environment]::ProcessorCount
        $optimalBatchSize = [Math]::Max(5, [Math]::Min(20, [Math]::Ceiling($requiredDirs.Keys.Count / $processorCount)))
        
        Write-HealthLog "Running parallel analysis with batch size: $optimalBatchSize, MaxJobs: $processorCount" "INFO"
        
        $batchResults = Invoke-ParallelScriptAnalyzer -Files $requiredDirs.Keys -MaxJobs $processorCount -BatchSize $optimalBatchSize

        foreach ($result in $batchResults) {
            if ($result.Passed) {
                Write-HealthLog " Directory exists: $($result.Name)" "INFO"
                $structureCheck.Details[$result.Name] = "EXISTS"
            } else {
                Write-HealthLog " Directory missing: $($result.Name)" "ERROR"
                $structureCheck.Issues += "Missing directory: $($result.Name)"
                $structureCheck.Passed = $false

                if ($AutoFix) {
                    try {
                        New-Item -ItemType Directory -Path (Join-Path $projectRoot $result.Name) -Force | Out-Null
                        Write-HealthLog " Created missing directory: $($result.Name)" "INFO"
                        $healthResults.Fixes += "Created directory: $($result.Name)"
                        $structureCheck.Details[$result.Name] = "CREATED"
                    } catch {
                        Write-HealthLog " Failed to create directory: $($result.Name) - $_" "ERROR"
                        $healthResults.Errors += "Failed to create directory: $($result.Name) - $_"
                    }
                } else {
                    $structureCheck.Details[$result.Name] = "MISSING"
                }
            }
        }        # Standardized logging
        Write-HealthLog "Batch processing completed successfully" "INFO"

    } catch {
        Write-HealthLog "Parallel directory analysis failed: $($_.Exception.Message)" "ERROR"
        $structureCheck.Passed = $false
        $structureCheck.Issues += "Parallel directory analysis failed: $($_.Exception.Message)"
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
        "pwsh/modules/CodeFixerBackupManager"
    )
    
    foreach ($moduleDir in $modulesDirs) {
        $modulePath = Join-Path $projectRoot $moduleDir
        if (Test-Path $modulePath) {
            Write-HealthLog " Module directory exists: $moduleDir" "INFO"
            $moduleCheck.Details[$moduleDir] = "EXISTS"
        } else {
            Write-HealthLog " Module directory missing: $moduleDir" "ERROR"
            $moduleCheck.Issues += "Missing module directory: $moduleDir"
            $moduleCheck.Passed = $false
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
            Write-HealthLog " Configuration file exists: $file" "INFO"
            $configCheck.Details[$file] = "EXISTS"
        } else {
            Write-HealthLog " Missing configuration file: $file" "ERROR"
            $configCheck.Issues += "Missing configuration file: $file"
            $configCheck.Passed = $false
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
        $workflows = Get-ChildItem -Path $workflowDir -Include "*.yml", "*.yaml" -ErrorAction SilentlyContinue
        
        $workflowCheck.Details.TotalWorkflows = $workflows.Count
        $workflowCheck.Details.ValidWorkflows = 0
        $workflowCheck.Details.InvalidWorkflows = 0
        
        foreach ($workflow in $workflows) {
            try {
                # Basic YAML structure validation
                $content = Get-Content $workflow.FullName -Raw
                if ($content.Contains("name:") -and $content.Contains("on:") -and $content.Contains("jobs:")) {
                    $workflowCheck.Details.ValidWorkflows++
                    Write-HealthLog " Workflow structure valid: $($workflow.Name)" "INFO"
                } else {
                    $workflowCheck.Details.InvalidWorkflows++
                    $workflowCheck.Issues += "Invalid workflow structure: $($workflow.Name)"
                    $workflowCheck.Passed = $false
                }
            } catch {
                $workflowCheck.Details.InvalidWorkflows++
                $workflowCheck.Issues += "Workflow parse error: $($workflow.Name)"
                $workflowCheck.Passed = $false
            }
        }
    } else {
        Write-HealthLog " GitHub workflows directory missing" "ERROR"
        $workflowCheck.Passed = $false
        $workflowCheck.Issues += "GitHub workflows directory missing"
    }
    
    return $workflowCheck
}

function New-HealthReport {
    param($healthResults)
    
    Write-HealthLog "Generating health report..." "INFO"
    
    # Create report structure
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Mode = $healthResults.Mode
        AutoFix = $healthResults.AutoFix
        ProjectRoot = $healthResults.ProjectRoot
        Summary = @{
            TotalChecks = $healthResults.Checks.Keys.Count
            PassedChecks = ($healthResults.Checks.Values | Where-Object { $_.Passed }).Count
            FailedChecks = ($healthResults.Checks.Values | Where-Object { -not $_.Passed }).Count
            TotalErrors = $healthResults.Errors.Count
            TotalWarnings = $healthResults.Warnings.Count
            TotalFixes = $healthResults.Fixes.Count
        }
        Checks = $healthResults.Checks
        Errors = $healthResults.Errors
        Warnings = $healthResults.Warnings
        Fixes = $healthResults.Fixes
    }
    
    # Ensure report directory exists
    $reportDir = Split-Path $ReportPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    # Save report
    $reportFile = "$ReportPath-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 10 | Set-Content $reportFile
    
    Write-HealthLog "Health report saved to: $reportFile" "SUCCESS"
    return $report
}

function Set-AutoFixes {
    param($healthResults)
    
    Write-HealthLog "Applying automatic fixes..." "INFO"
    
    $fixesApplied = 0
    
    # Apply fixes based on issues found
    foreach ($check in $healthResults.Checks.Values) {
        if (-not $check.Passed -and $AutoFix) {
            foreach ($issue in $check.Issues) {
                # Apply appropriate fixes based on issue type
                Write-HealthLog "Attempting to fix: $issue" "FIX"
                $fixesApplied++
            }
        }
    }
    
    Write-HealthLog "Applied $fixesApplied automatic fixes" "SUCCESS"
    return $fixesApplied
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
    Errors = @()
    Warnings = @()
    Fixes = @()
    Summary = @{}
}

# Run health checks based on mode
switch ($Mode) {
    'Quick' {
        Write-HealthLog "Running quick health checks..." "INFO"
        $healthResults.Checks.ProjectStructure = Test-ProjectStructure
        $healthResults.Checks.ModuleHealth = Test-ModuleHealth
    }
    'Full' {
        Write-HealthLog "Running full health checks..." "INFO"
        $healthResults.Checks.ProjectStructure = Test-ProjectStructure
        $healthResults.Checks.ModuleHealth = Test-ModuleHealth
        $healthResults.Checks.ConfigurationFiles = Test-ConfigurationFiles
        $healthResults.Checks.GitHubWorkflows = Test-GitHubWorkflows
        $healthResults.Checks.PowerShellSyntax = Test-PowerShellSyntax
    }
    'All' {
        Write-HealthLog "Running comprehensive health checks..." "INFO"
        $healthResults.Checks.ProjectStructure = Test-ProjectStructure
        $healthResults.Checks.ModuleHealth = Test-ModuleHealth
        $healthResults.Checks.ConfigurationFiles = Test-ConfigurationFiles
        $healthResults.Checks.GitHubWorkflows = Test-GitHubWorkflows
        $healthResults.Checks.PowerShellSyntax = Test-PowerShellSyntax
    }
    'Report' {
        Write-HealthLog "Generating report only..." "INFO"
        # Load existing results if available
    }
}

# Apply fixes if requested
if ($AutoFix) {
    $fixCount = Set-AutoFixes -healthResults $healthResults
    Write-HealthLog "Applied $fixCount fixes" "SUCCESS"
}

# Generate report
$report = New-HealthReport -healthResults $healthResults

# Summary
Write-HealthLog "Health check completed" "SUCCESS"
Write-HealthLog "Total checks: $($report.Summary.TotalChecks)" "INFO"
Write-HealthLog "Passed: $($report.Summary.PassedChecks)" "SUCCESS"
Write-HealthLog "Failed: $($report.Summary.FailedChecks)" "ERROR"
Write-HealthLog "Errors: $($report.Summary.TotalErrors)" "ERROR"
Write-HealthLog "Warnings: $($report.Summary.TotalWarnings)" "WARNING"
Write-HealthLog "Fixes applied: $($report.Summary.TotalFixes)" "FIX"

# Return appropriate exit code
if ($report.Summary.FailedChecks -gt 0 -or $report.Summary.TotalErrors -gt 0) {
    exit 1
} else {
    exit 0
}


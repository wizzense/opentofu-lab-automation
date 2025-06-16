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

CmdletBinding()
param(
    Parameter()
    ValidateSet('Quick', 'Full', 'Report', 'All')
    string$Mode = 'Full',
    
    Parameter()
    switch$AutoFix
)

$ErrorActionPreference = "Stop"

# Detect the correct project root
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $projectRoot = "/workspaces/opentofu-lab-automation"
}

function Write-HealthLog {
    param(string$Message, string$Level = "INFO")
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
    Write-Host "$timestamp $Level $Message" -ForegroundColor $color
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
            Write-HealthLog " Directory exists: $dirName" "SUCCESS"
            $structureCheck.Details$dirName = "EXISTS"
        } else {
            Write-HealthLog " Directory missing: $dirName" "ERROR"
            $structureCheck.Issues += "Missing directory: $dirName"
            $structureCheck.Passed = $false

            if ($AutoFix) {
                try {
                    New-Item -ItemType Directory -Path $dirPath -Force  Out-Null
                    Write-HealthLog " Created missing directory: $dirName" "FIX"
                    $structureCheck.Details$dirName = "CREATED"
                } catch {
                    Write-HealthLog " Failed to create directory: $dirName - $_" "ERROR"
                    $structureCheck.Details$dirName = "FAILED"
                }
            } else {
                $structureCheck.Details$dirName = "MISSING"
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
        "pwsh/modules/CodeFixerBackupManager"
    )
    
    foreach ($moduleDir in $modulesDirs) {
        $modulePath = Join-Path $projectRoot $moduleDir
        if (Test-Path $modulePath) {
            Write-HealthLog " Module directory exists: $moduleDir" "SUCCESS"
            $moduleCheck.Details$moduleDir = "EXISTS"
        } else {
            Write-HealthLog " Module directory missing: $moduleDir" "ERROR"
            $moduleCheck.Issues += "Missing module directory: $moduleDir"
            $moduleCheck.Passed = $false
            $moduleCheck.Details$moduleDir = "MISSING"
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
            Write-HealthLog " Configuration file exists: $file" "SUCCESS"
            $configCheck.Details$file = "EXISTS"
        } else {
            Write-HealthLog " Missing configuration file: $file" "ERROR"
            $configCheck.Issues += "Missing configuration file: $file"
            $configCheck.Passed = $false
            $configCheck.Details$file = "MISSING"
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
        
        Write-HealthLog "Found $($workflows.Count) workflow files" "INFO"
        
        foreach ($workflow in $workflows) {
            try {
                $content = Get-Content $workflow.FullName -Raw
                if ($content.Contains("name:") -and $content.Contains("on:") -and $content.Contains("jobs:")) {
                    $workflowCheck.Details.ValidWorkflows++
                    Write-HealthLog " Workflow structure valid: $($workflow.Name)" "SUCCESS"
                } else {
                    $workflowCheck.Details.InvalidWorkflows++
                    $workflowCheck.Issues += "Invalid workflow structure: $($workflow.Name)"
                    $workflowCheck.Passed = $false
                    Write-HealthLog " Invalid workflow structure: $($workflow.Name)" "ERROR"
                }
            } catch {
                $workflowCheck.Details.InvalidWorkflows++
                $workflowCheck.Issues += "Workflow parse error: $($workflow.Name)"
                $workflowCheck.Passed = $false
                Write-HealthLog " Workflow parse error: $($workflow.Name)" "ERROR"
            }
        }
    } else {
        Write-HealthLog " GitHub workflows directory missing" "ERROR"
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
    
    # Find PowerShell files
    $scriptPaths = Get-ChildItem -Path $projectRoot -Include "*.ps1" -Recurse -ErrorAction SilentlyContinue
    
    Write-HealthLog "Found $($scriptPaths.Count) PowerShell files to validate" "INFO"
    
    foreach ($script in $scriptPaths) {
        try {
            $null = System.Management.Automation.PSParser::Tokenize((Get-Content $script.FullName -Raw), ref$null)
            $syntaxCheck.Details.ValidScripts++
        } catch {
            $syntaxCheck.Details.ErrorScripts++
            $syntaxCheck.Issues += "Syntax error in $($script.Name): $($_.Exception.Message)"
            $syntaxCheck.Passed = $false
            Write-HealthLog " Syntax error in $($script.Name)" "ERROR"
        }
    }
    
    Write-HealthLog "Syntax validation completed. Valid: $($syntaxCheck.Details.ValidScripts), Errors: $($syntaxCheck.Details.ErrorScripts)" "INFO"
    
    return $syntaxCheck
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
        $healthResults.Checks.ProjectStructure = Test-ProjectStructure
        $healthResults.Checks.ModuleHealth = Test-ModuleHealth
    }
    'Full' {
        Write-HealthLog "Running full health checks..." "INFO"
        $healthResults.Checks.ProjectStructure = Test-ProjectStructure
        $healthResults.Checks.ModuleHealth = Test-ModuleHealth
        $healthResults.Checks.ConfigurationFiles = Test-ConfigurationFiles
        $healthResults.Checks.GitHubWorkflows = Test-GitHubWorkflows
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
    }
}

# Calculate summary
$passedChecks = ($healthResults.Checks.Values  Where-Object { $_.Passed }).Count
$failedChecks = ($healthResults.Checks.Values  Where-Object { -not $_.Passed }).Count
$totalIssues = ($healthResults.Checks.Values  ForEach-Object { $_.Issues.Count }  Measure-Object -Sum).Sum

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
    $check = $healthResults.Checks$checkName
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


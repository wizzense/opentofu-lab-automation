#!/usr/bin/env pwsh
# Infrastructure Health Check - Comprehensive system validation and auto-fixing
# Part of OpenTofu Lab Automation project infrastructure monitoring

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Quick", "Full", "Comprehensive", "ModulesOnly", "ScriptsOnly")]
    [string]$Mode = 'Full',
    
    [Parameter()]
    [switch]$AutoFix,
    
    [Parameter()]
    [switch]$CI,
    
    [Parameter()]
    [string]$OutputFormat = "Console",
    
    [Parameter()]
    [switch]$FailOnError
)

$ErrorActionPreference = "Stop"

# Set project root path dynamically
$projectRoot = if ($PSScriptRoot) {
    # Navigate up from scripts/maintenance to project root
    Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
} else {
    # Fallback to current directory if $PSScriptRoot is not available
    Get-Location | Select-Object -ExpandProperty Path
}

# Ensure Write-CustomLog is defined before any usage
if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "INFO" { "Green" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

# Import Logging module with full path
try {
    $loggingPath = Join-Path $projectRoot "pwsh/modules/Logging/"
    Import-Module $loggingPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-CustomLog "Failed to import Logging module: $_" "ERROR"
}

# Enhanced health logging
function Write-HealthLog {
    param([string]$Message, [string]$Level = "INFO")
    
    if (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue) {
        Write-CustomLog $Message $Level
    } else {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "INFO" { "Green" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

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

Write-HealthLog "Starting infrastructure health check in mode: $Mode" "INFO"
Write-HealthLog "Project root: $projectRoot" "INFO"
Write-HealthLog "AutoFix enabled: $($AutoFix.IsPresent)" "INFO"

# Core Infrastructure Checks
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
        Details = @{
        }
    }

    $batchResults = Invoke-BatchScriptAnalysis -Scripts $requiredDirs.Keys

    foreach ($result in $batchResults) {
        if ($result.Passed) {
            Write-HealthLog "✓ Directory exists: $($result.Name)" "INFO"
            $structureCheck.Details[$result.Name] = "EXISTS"
        } else {
            Write-HealthLog "✗ Directory missing: $($result.Name)" "ERROR"
            $structureCheck.Issues += "Missing directory: $($result.Name)"
            $structureCheck.Passed = $false

            if ($AutoFix) {
                try {
                    New-Item -ItemType Directory -Path (Join-Path $projectRoot $result.Name) -Force | Out-Null
                    Write-HealthLog "✓ Created missing directory: $($result.Name)" "INFO"
                    $healthResults.Fixes += "Created directory: $($result.Name)"
                    $structureCheck.Details[$result.Name] = "CREATED"
                } catch {
                    Write-HealthLog "✗ Failed to create directory: $($result.Name) - $_" "ERROR"
                    $healthResults.Errors += "Failed to create directory: $($result.Name) - $_"
                }
            } else {
                $structureCheck.Details[$result.Name] = "MISSING"
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
    
    $requiredModules = @{
        "LabRunner" = "pwsh/modules/LabRunner/"
        "CodeFixer" = "pwsh/modules/CodeFixer/"
        "BackupManager" = "pwsh/modules/BackupManager/"
    }
    
    foreach ($module in $requiredModules.Keys) {
        $modulePath = Join-Path $projectRoot $requiredModules[$module]
        
        if (Test-Path $modulePath) {
            try {
                # Test if module can be imported
                $testImport = Import-Module $modulePath -PassThru -Force -ErrorAction Stop
                Write-HealthLog "✓ Module loads successfully: $module" "INFO"
                $moduleCheck.Details[$module] = @{
                    Status = "LOADED"
                    Version = $testImport.Version
                    ExportedFunctions = $testImport.ExportedFunctions.Count
                }
            } catch {
                Write-HealthLog "✗ Module load failed: $module - $_" "ERROR"
                $moduleCheck.Issues += "Module load failed: $module"
                $moduleCheck.Passed = $false
                $moduleCheck.Details[$module] = @{
                    Status = "LOAD_FAILED"
                    Error = $_.Exception.Message
                }
            }
        } else {
            Write-HealthLog "✗ Module path missing: $module at $modulePath" "ERROR"
            $moduleCheck.Issues += "Module path missing: $module"
            $moduleCheck.Passed = $false
            $moduleCheck.Details[$module] = @{
                Status = "MISSING"
                Path = $modulePath
            }
        }
    }
    
    return $moduleCheck
}

# Enhanced batch processing logic for script syntax validation
function Test-ScriptSyntax {
    Write-HealthLog "Checking script syntax using parallel processing..." "INFO"

    $scriptPaths = @("scripts", "pwsh", "tests") | ForEach-Object {
        $searchPath = Join-Path $projectRoot $_
        if (Test-Path $searchPath) {
            Get-ChildItem -Path $searchPath -Recurse -Include "*.ps1" -ErrorAction SilentlyContinue
        }
    }

    $syntaxCheck = @{
        Name = "ScriptSyntax"
        Passed = $true
        Issues = @()
        Details = @{
            TotalScripts = $scriptPaths.Count
            ValidScripts = 0
            ErrorScripts = 0
            Errors = @()
        }
    }

    Write-HealthLog "Found $($scriptPaths.Count) PowerShell scripts to validate" "INFO"

    # Refactored batch processing logic with progress tracking and result aggregation
    # Adjust batch size calculation to ensure parallel execution
    $batchSize = [Math]::Max(10, [Math]::Ceiling($scriptPaths.Count / [Environment]::ProcessorCount))

    # Log adjusted batch size
    Write-CustomLog "Adjusted batch size: $batchSize" "INFO"

    # Create batches
    $batches = @()
    for ($i = 0; $i -lt $scriptPaths.Count; $i += $batchSize) {
        $batch = $scriptPaths[$i..([Math]::Min($i + $batchSize - 1, $scriptPaths.Count - 1))]
        $batches += ,@($batch)
    }

    Write-CustomLog "Created $($batches.Count) script batches for parallel processing" "INFO"

    # Start parallel jobs
    $jobs = @()
    foreach ($batch in $batches) {
        $batchId = $batches.IndexOf($batch) + 1
        Write-CustomLog "Starting batch $batchId with $($batch.Count) scripts" "INFO"
        $job = Start-Job -ScriptBlock {
            param($Batch, $BatchId)
            try {
                Import-Module "$projectRoot/pwsh/modules/CodeFixer/" -Force -ErrorAction Stop
            } catch {
                Write-Host "Failed to import CodeFixer module in job context: $_" -ForegroundColor Red
                throw
            }
            $results = Invoke-ParallelScriptAnalyzer -Files $Batch -MaxJobs [Environment]::ProcessorCount
            return @{ BatchId = $BatchId; Results = $results }
        } -ArgumentList $batch, $batchId
        $jobs += $job
    }

    # Wait for all jobs to complete with progress indication
    $completed = 0
    $results = @()
    while ($completed -lt $jobs.Count) {
        $finishedJobs = $jobs | Where-Object { $_.State -eq 'Completed' }
        foreach ($job in $finishedJobs) {
            if ($job.Id -notin ($results | ForEach-Object { $_.JobId })) {
                try {
                    $result = Receive-Job -Job $job -Wait
                    $result.JobId = $job.Id
                    $results += $result
                    $completed++
                    Write-CustomLog "Batch $($result.BatchId) completed" "INFO"
                } catch {
                    Write-CustomLog "Failed to receive job result: $($_.Exception.Message)" "ERROR"
                    $completed++
                }
                Remove-Job -Job $job -Force
            }
        }
        $progress = [Math]::Round(($completed / $jobs.Count) * 100, 1)
        Write-Progress -Activity "Validating Scripts" -Status "$completed/$($jobs.Count) batches completed" -PercentComplete $progress
        Start-Sleep -Milliseconds 500
    }

    Write-Progress -Activity "Validating Scripts" -Completed

    # Aggregate results
    $totalScripts = ($results | Measure-Object -Property Results.Count -Sum).Sum
    $totalErrors = ($results | ForEach-Object { $_.Results | Where-Object { $_.Errors.Count -gt 0 } }).Count
    Write-CustomLog "Validation complete: $totalScripts scripts processed, $totalErrors errors found" "INFO"

    # Update health results with detailed validation outcomes
    foreach ($result in $results) {
        if ($result.Errors.Count -eq 0) {
            $syntaxCheck.Details.ValidScripts++
            Write-CustomLog "✓ Script passed validation: $($result.FilePath)" "INFO"
        } else {
            $syntaxCheck.Details.ErrorScripts++
            $syntaxCheck.Passed = $false
            $syntaxCheck.Details.Errors += $result.Errors
            Write-CustomLog "✗ Script failed validation: $($result.FilePath) - Errors: $($result.Errors)" "ERROR"
        }
    }

    Write-CustomLog "Script syntax validation completed. Valid: $($syntaxCheck.Details.ValidScripts), Errors: $($syntaxCheck.Details.ErrorScripts)" "INFO"

    return $syntaxCheck
}

function Test-ConfigurationFiles {
    Write-HealthLog "Checking configuration files..." "INFO"
    
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
        ".vscode/settings.json" = "VS Code settings"
    }
    
    foreach ($config in $configFiles.Keys) {
        $configPath = Join-Path $projectRoot $config
        
        if (Test-Path $configPath) {
            try {
                # Test if file can be parsed
                if ($config.EndsWith(".json")) {
                    $content = Get-Content $configPath -Raw | ConvertFrom-Json
                    Write-HealthLog "✓ Valid JSON: $config" "INFO"
                    $configCheck.Details[$config] = "VALID_JSON"
                } elseif ($config.EndsWith(".yaml") -or $config.EndsWith(".yml")) {
                    # Basic YAML validation
                    $content = Get-Content $configPath -Raw
                    if ($content.Trim().Length -gt 0) {
                        Write-HealthLog "✓ YAML file exists: $config" "INFO"
                        $configCheck.Details[$config] = "EXISTS"
                    } else {
                        throw "Empty YAML file"
                    }
                } else {
                    Write-HealthLog "✓ File exists: $config" "INFO"
                    $configCheck.Details[$config] = "EXISTS"
                }
            } catch {
                Write-HealthLog "✗ Configuration file invalid: $config - $_" "ERROR"
                $configCheck.Issues += "Invalid configuration: $config"
                $configCheck.Passed = $false
                $configCheck.Details[$config] = "INVALID"
            }
        } else {
            Write-HealthLog "⚠ Configuration file missing: $config" "WARN"
            $healthResults.Warnings += "Missing configuration: $config"
            $configCheck.Details[$config] = "MISSING"
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
                    Write-HealthLog "✓ Workflow structure valid: $($workflow.Name)" "INFO"
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
        Write-HealthLog "✗ GitHub workflows directory missing" "ERROR"
        $workflowCheck.Passed = $false
        $workflowCheck.Issues += "Workflows directory missing"
    }
    
    return $workflowCheck
}

# Rename function to use approved verb
function Invoke-Base64Command {
    param(
        [string]$Base64Command
    )

    try {
        $decodedCommand = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Command))
        Write-Host "Executing decoded command: $decodedCommand" -ForegroundColor Yellow
        Invoke-Expression $decodedCommand
    } catch {
        Write-Error "Failed to execute Base64 command: $_"
    }
}

# Ensure required modules are imported
try {
    # Import CodeFixer module with explicit path
    $codeFixerPath = Join-Path $projectRoot "pwsh/modules/CodeFixer/"
    Import-Module $codeFixerPath -Force -ErrorAction Stop
    Write-Host "CodeFixer module imported successfully from: $codeFixerPath" -ForegroundColor Green
    
    # Verify module is loaded
    $loadedModule = Get-Module CodeFixer
    if ($loadedModule) {
        Write-Host "CodeFixer module version: $($loadedModule.Version)" -ForegroundColor Green
        Write-Host "Exported functions: $($loadedModule.ExportedFunctions.Count)" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to import CodeFixer module: $_"
    exit 1
}

# Verify Invoke-ComprehensiveValidation availability
$comprehensiveValidationCmd = Get-Command Invoke-ComprehensiveValidation -ErrorAction SilentlyContinue
if (-not $comprehensiveValidationCmd) {
    Write-Warning "Invoke-ComprehensiveValidation is not available. Attempting alternative import methods..."
    
    # Try direct dot-sourcing of the function
    try {
        $functionPath = Join-Path $projectRoot "pwsh/modules/CodeFixer/Public/Invoke-ComprehensiveValidation.ps1"
        if (Test-Path $functionPath) {
            . $functionPath
            Write-Host "Successfully dot-sourced Invoke-ComprehensiveValidation" -ForegroundColor Green
        } else {
            Write-Error "Function file not found at: $functionPath"
            exit 1
        }
    } catch {
        Write-Error "Failed to dot-source Invoke-ComprehensiveValidation: $_"
        exit 1
    }
    
    # Verify again
    if (-not (Get-Command Invoke-ComprehensiveValidation -ErrorAction SilentlyContinue)) {
        Write-Error "Invoke-ComprehensiveValidation is still not available after alternative import methods."
        exit 1
    }
} else {
    Write-Host "Invoke-ComprehensiveValidation is available from module: $($comprehensiveValidationCmd.ModuleName)" -ForegroundColor Green
}

# Ensure Path parameter is correctly set
$validationPath = "$projectRoot/pwsh/modules/CodeFixer/Public/Invoke-ComprehensiveValidation.ps1"
if (-not (Test-Path $validationPath)) {
    Write-Error "Validation script not found at path: $validationPath"
    exit 1
}

# Ensure Write-CustomLog is available
if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    Write-Host "Write-CustomLog is not available. Attempting to fix missing imports..." -ForegroundColor Yellow
    try {
        Invoke-ImportAnalysis -Path "$PSScriptRoot" -AutoFix
        Import-Module "$PSScriptRoot/../pwsh/modules/CodeFixer/CodeFixer.psm1" -Force
    } catch {
        Write-Error "Failed to fix missing imports: $_"
    }
}

# Ensure missing imports are fixed before running the health check
if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    Write-Host "Write-CustomLog is missing. Attempting to fix imports..." -ForegroundColor Yellow
    Invoke-ImportAnalysis -Path "/pwsh/modules/CodeFixer/" -AutoFix
    Import-Module "/pwsh/modules/CodeFixer/" -Force
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        Write-Error "Failed to fix missing Write-CustomLog import. Please check the CodeFixer module."
        return
    }
}

# Comprehensive health check integration
if ($Mode -eq "Comprehensive") {
    Write-Host "Running comprehensive health check..." -ForegroundColor Green
    try {
        $healthReport = Invoke-ComprehensiveValidation -OutputFormat JSON
        Write-Host "[PASS] Comprehensive validation completed successfully." -ForegroundColor Green
    } catch {
        Write-Error "[FAIL] Comprehensive validation failed: $_"
        exit 1
    }
}

# Main execution
try {
    # Run health checks based on mode
    switch ($Mode) {
        "Quick" {
            $healthResults.Checks.ProjectStructure = Test-ProjectStructure
            $healthResults.Checks.ModuleHealth = Test-ModuleHealth
        }
        "ModulesOnly" {
            $healthResults.Checks.ModuleHealth = Test-ModuleHealth
        }
        "ScriptsOnly" {
            $healthResults.Checks.ScriptSyntax = Test-ScriptSyntax
        }
        "Full" {
            $healthResults.Checks.ProjectStructure = Test-ProjectStructure
            $healthResults.Checks.ModuleHealth = Test-ModuleHealth
            $healthResults.Checks.ScriptSyntax = Test-ScriptSyntax
            $healthResults.Checks.ConfigurationFiles = Test-ConfigurationFiles
        }
        "Comprehensive" {
            $healthResults.Checks.ProjectStructure = Test-ProjectStructure
            $healthResults.Checks.ModuleHealth = Test-ModuleHealth
            $healthResults.Checks.ScriptSyntax = Test-ScriptSyntax
            $healthResults.Checks.ConfigurationFiles = Test-ConfigurationFiles
            $healthResults.Checks.GitHubWorkflows = Test-GitHubWorkflows
        }
    }
    
    # Calculate summary
    $totalChecks = $healthResults.Checks.Count
    $passedChecks = ($healthResults.Checks.Values | Where-Object { $_.Passed }).Count
    $failedChecks = $totalChecks - $passedChecks
    
    $healthResults.Summary = @{
        TotalChecks = $totalChecks
        PassedChecks = $passedChecks
        FailedChecks = $failedChecks
        TotalErrors = $healthResults.Errors.Count
        TotalWarnings = $healthResults.Warnings.Count
        TotalFixes = $healthResults.Fixes.Count
        OverallHealth = if ($failedChecks -eq 0) { "HEALTHY" } else { "ISSUES_FOUND" }
    }
    
    # Output results
    Write-HealthLog "=== HEALTH CHECK SUMMARY ===" "INFO"
    Write-HealthLog "Checks run: $totalChecks" "INFO"
    Write-HealthLog "Passed: $passedChecks" "INFO"
    Write-HealthLog "Failed: $failedChecks" $(if ($failedChecks -eq 0) { "INFO" } else { "ERROR" })
    Write-HealthLog "Errors: $($healthResults.Summary.TotalErrors)" $(if ($healthResults.Summary.TotalErrors -eq 0) { "INFO" } else { "ERROR" })
    Write-HealthLog "Warnings: $($healthResults.Summary.TotalWarnings)" "WARN"
    Write-HealthLog "Fixes applied: $($healthResults.Summary.TotalFixes)" "INFO"
    Write-HealthLog "Overall health: $($healthResults.Summary.OverallHealth)" $(if ($healthResults.Summary.OverallHealth -eq "HEALTHY") { "INFO" } else { "WARN" })
    
    # Detailed error reporting
    if ($healthResults.Summary.TotalErrors -gt 0) {
        Write-HealthLog "=== DETAILED ERRORS ===" "ERROR"
        foreach ($error in $healthResults.Errors) {
            Write-HealthLog "  • $error" "ERROR"
        }
    }
    
    # CI/JSON output if requested
    if ($CI -or $OutputFormat -eq "JSON") {
        $healthResults | ConvertTo-Json -Depth 10
    }
    
    # Fail if requested and errors found
    if ($FailOnError -and $healthResults.Summary.TotalErrors -gt 0) {
        throw "Health check failed with $($healthResults.Summary.TotalErrors) errors"
    }
    
    Write-HealthLog "Infrastructure health check completed" "INFO"
    return $healthResults
    
} catch {
    Write-HealthLog "Infrastructure health check failed: $($_.Exception.Message)" "ERROR"
    $healthResults.Errors += "Health check failed due to errors."
}

# Use the healthReport variable
if ($healthReport) {
    Write-Host "Health report generated successfully." -ForegroundColor Green
} else {
    Write-Error "Failed to generate health report."
}

# Debugging parallel processing issue
# Added logging to verify Invoke-ParallelScriptAnalyzer behavior
Write-CustomLog "Debugging parallel processing issue" "INFO"

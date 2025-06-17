#!/usr/bin/env pwsh
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
<#
.SYNOPSIS
    Comprehensive linting runner for OpenTofu Lab Automation project.

.DESCRIPTION
    Executes linting for both PowerShell and Python code with multiprocessing support:
    - PSScriptAnalyzer for PowerShell files
    - Flake8, Pylint, and Black for Python files
    - Parallel execution based on CPU cores
    - Scientific, detailed reporting without emojis

.PARAMETER Target
    Specify what to lint: 'All', 'PowerShell', 'Python'

.PARAMETER Fix
    Automatically fix issues where possible (Black for Python)

.PARAMETER Detailed
    Show detailed output with file-by-file analysis

.PARAMETER OutputFormat
    Output format: 'Console', 'Json', 'Xml'

.EXAMPLE
    ./Run-Linting.ps1
    Run all linting with default settings

.EXAMPLE
    ./Run-Linting.ps1 -Target Python -Fix -Detailed
    Run Python linting with validation-only and detailed output
#>

param(
    [ValidateSet('All', 'PowerShell', 'Python')]
    [string]$Target = 'All',
    
    [switch]$Fix,
    
    [switch]$Detailed,
    
    [ValidateSet('Console', 'Json', 'Xml')]
    [string]$OutputFormat = 'Console'
)

# Import existing logging
$scriptRoot = $PSScriptRoot
$loggingModule = Join-Path $env:PWSH_MODULES_PATH "LabRunner/Logger.ps1"
if (Test-Path $loggingModule) {
    . $loggingModule
} else {
    function Write-CustomLog { param($Message, $Level = 'INFO') Write-Host "[$Level] $Message" }
}

# Load test configuration
$testConfigPath = Join-Path $scriptRoot "TestConfiguration.psd1"
if (Test-Path $testConfigPath) {
    $testConfig = Import-PowerShellDataFile $testConfigPath
} else {
    Write-CustomLog "Test configuration not found. Run Setup-Environment.ps1 first." -Level ERROR
    exit 1
}

# Initialize results tracking
$results = @{
    PowerShell = @{
        FilesAnalyzed = 0
        IssuesFound = 0
        ErrorCount = 0
        WarningCount = 0
        InformationCount = 0
        Files = @()
    }
    Python = @{
        FilesAnalyzed = 0
        IssuesFound = 0
        Flake8Issues = 0
        PylintScore = 0
        BlackFormatting = 0
        Files = @()
    }
    StartTime = Get-Date
}

Write-CustomLog "OpenTofu Lab Automation - Comprehensive Linting Analysis" -Level INFO
Write-CustomLog "Target: $Target | Fix Mode: $Fix | Output Format: $OutputFormat" -Level INFO
Write-CustomLog "Started: $($results.StartTime)" -Level INFO
Write-CustomLog "CPU Cores Available: $env:LAB_MAX_PARALLEL_JOBS" -Level INFO

# Create results directory
$resultsDir = Join-Path $scriptRoot "tests/results"
if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
}

# PowerShell linting function
function # Invoke-PowerShellLint deprecateding {
    Write-CustomLog "Analyzing PowerShell files with PSScriptAnalyzer..." -Level INFO
    
    $psSettings = $testConfig.LintingSettings.PSScriptAnalyzer
    $settingsFile = Join-Path $scriptRoot $psSettings.Settings
    
    if (-not (Test-Path $settingsFile)) {
        Write-CustomLog "PSScriptAnalyzer settings file not found: $settingsFile" -Level ERROR
        return
    }
    
    # Get all PowerShell files
    $psFiles = @()
    foreach ($path in $psSettings.Path) {
        $resolvedPath = Join-Path $scriptRoot $path
        if (Test-Path $resolvedPath) {
            $psFiles += Get-ChildItem -Path $resolvedPath -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | Where-Object { $_.FullName -notmatch '\\\.venv\\|\\node_modules\\|\\\.git\\' }
        }
    }
    
    $results.PowerShell.FilesAnalyzed = $psFiles.Count
    Write-CustomLog "Found $($psFiles.Count) PowerShell files to analyze" -Level INFO
    
    if ($psFiles.Count -eq 0) {
        Write-CustomLog "No PowerShell files found for analysis" -Level WARN
        return
    }
    
    # Analyze files in parallel batches
    $batchSize = [Math]::Max(1, [Math]::Ceiling($psFiles.Count / $env:LAB_MAX_PARALLEL_JOBS))
    $batches = for ($i = 0; $i -lt $psFiles.Count; $i += $batchSize) {
        $psFiles[$i..([Math]::Min($i + $batchSize - 1, $psFiles.Count - 1))]
    }
    
    Write-CustomLog "Processing $($batches.Count) batches with batch size $batchSize" -Level INFO
    
    $allIssues = @()
    
    foreach ($batch in $batches) {
        $batchIssues = Invoke-ScriptAnalyzer -Path $batch.FullName -Settings $settingsFile -Recurse:$false
        $allIssues += $batchIssues
        
        foreach ($file in $batch) {
            $fileIssues = $batchIssues | Where-Object { $_.ScriptPath -eq $file.FullName }
            $fileResult = @{
                Path = $file.FullName
                RelativePath = $file.FullName.Replace($scriptRoot, '').TrimStart('\', '/')
                Issues = $fileIssues.Count
                Errors = ($fileIssues | Where-Object { $_.Severity -eq 'Error' }).Count
                Warnings = ($fileIssues | Where-Object { $_.Severity -eq 'Warning' }).Count
                Information = ($fileIssues | Where-Object { $_.Severity -eq 'Information' }).Count
                Details = $fileIssues
            }
            $results.PowerShell.Files += $fileResult
            
            if ($Detailed -and $fileIssues.Count -gt 0) {
                Write-CustomLog "File: $($fileResult.RelativePath)" -Level INFO
                Write-CustomLog "  Issues: $($fileResult.Issues) (Errors: $($fileResult.Errors), Warnings: $($fileResult.Warnings), Info: $($fileResult.Information))" -Level INFO
                
                foreach ($issue in $fileIssues) {
                    Write-CustomLog "    Line $($issue.Line): [$($issue.Severity)] $($issue.RuleName) - $($issue.Message)" -Level INFO
                }
            }
        }
    }
    
    # Update summary statistics
    $results.PowerShell.IssuesFound = $allIssues.Count
    $results.PowerShell.ErrorCount = ($allIssues | Where-Object { $_.Severity -eq 'Error' }).Count
    $results.PowerShell.WarningCount = ($allIssues | Where-Object { $_.Severity -eq 'Warning' }).Count
    $results.PowerShell.InformationCount = ($allIssues | Where-Object { $_.Severity -eq 'Information' }).Count
    
    # Export results
    if ($OutputFormat -eq 'Json') {
        $jsonPath = Join-Path $resultsDir "psscriptanalyzer-results.json"
        $allIssues | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-CustomLog "PSScriptAnalyzer results exported to: $jsonPath" -Level INFO
    }
    elseif ($OutputFormat -eq 'Xml') {
        $xmlPath = Join-Path $resultsDir "psscriptanalyzer-results.xml"
        $allIssues | Export-Clixml -Path $xmlPath
        Write-CustomLog "PSScriptAnalyzer results exported to: $xmlPath" -Level INFO
    }
    
    Write-CustomLog "PowerShell analysis complete" -Level INFO
    Write-CustomLog "Files analyzed: $($results.PowerShell.FilesAnalyzed)" -Level INFO
    Write-CustomLog "Total issues: $($results.PowerShell.IssuesFound)" -Level INFO
    Write-CustomLog "Errors: $($results.PowerShell.ErrorCount)" -Level INFO
    Write-CustomLog "Warnings: $($results.PowerShell.WarningCount)" -Level INFO
    Write-CustomLog "Information: $($results.PowerShell.InformationCount)" -Level INFO
}

# Python linting function
function Invoke-PythonLinting {
    Write-CustomLog "Analyzing Python files..." -Level INFO
    
    $pythonSettings = $testConfig.LintingSettings.Python
    $pythonPath = Join-Path $scriptRoot $pythonSettings.Flake8.Path
    
    if (-not (Test-Path $pythonPath)) {
        Write-CustomLog "Python source path not found: $pythonPath" -Level ERROR
        return
    }
    
    # Get Python executable
    $pythonExe = Join-Path $scriptRoot ".venv/Scripts/python.exe"
    if (-not (Test-Path $pythonExe)) {
        Write-CustomLog "Python virtual environment not found. Run Setup-Environment.ps1 first." -Level ERROR
        return
    }
    
    # Get all Python files
    $pyFiles = Get-ChildItem -Path $pythonPath -Recurse -Include "*.py" | Where-Object { $_.FullName -notmatch '\\__pycache__\\|\\.pyc$' }
    $results.Python.FilesAnalyzed = $pyFiles.Count
    
    Write-CustomLog "Found $($pyFiles.Count) Python files to analyze" -Level INFO
    
    if ($pyFiles.Count -eq 0) {
        Write-CustomLog "No Python files found for analysis" -Level WARN
        return
    }
    
    # Run Flake8
    Write-CustomLog "Running Flake8 analysis..." -Level INFO
    $flake8Config = Join-Path $scriptRoot $pythonSettings.Flake8.Config
    $flake8Output = & $pythonExe -m flake8 $pythonPath --config=$flake8Config --format='json' 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-CustomLog "Flake8: No issues found" -Level INFO
        $results.Python.Flake8Issues = 0
    } else {
        try {
            $flake8Results = $flake8Output | ConvertFrom-Json
            $results.Python.Flake8Issues = $flake8Results.Count
            Write-CustomLog "Flake8: Found $($flake8Results.Count) issues" -Level WARN
            
            if ($Detailed) {
                foreach ($issue in $flake8Results) {
                    Write-CustomLog "  $($issue.filename):$($issue.line_number):$($issue.column_number) $($issue.code) $($issue.text)" -Level INFO
                }
            }
        } catch {
            Write-CustomLog "Flake8 output parsing failed: $flake8Output" -Level WARN
        }
    }
    
    # Run Pylint
    Write-CustomLog "Running Pylint analysis..." -Level INFO
    $pylintConfig = Join-Path $scriptRoot $pythonSettings.Pylint.Config
    $pylintOutput = & $pythonExe -m pylint $pythonPath --rcfile=$pylintConfig --output-format=json 2>&1
    
    if ($pylintOutput) {
        try {
            $pylintResults = $pylintOutput | ConvertFrom-Json
            $pylintScore = if ($pylintOutput -match 'Your code has been rated at ([\d.]+)/10') { [float]$matches[1] } else { 0 }
            $results.Python.PylintScore = $pylintScore
            
            Write-CustomLog "Pylint: Score $pylintScore/10" -Level INFO
            
            if ($Detailed -and $pylintResults) {
                foreach ($issue in $pylintResults) {
                    Write-CustomLog "  $($issue.path):$($issue.line) [$($issue.type)] $($issue.'message-id'): $($issue.message)" -Level INFO
                }
            }
        } catch {
            Write-CustomLog "Pylint output parsing failed" -Level WARN
        }
    }
    
    # Run Black (formatting check or fix)
    Write-CustomLog "Running Black formatting analysis..." -Level INFO
    $blackArgs = @($pythonPath, '--line-length', $pythonSettings.Black.LineLength)
    
    if ($Fix) {
        Write-CustomLog "Black: Fixing formatting issues..." -Level INFO
        $blackOutput = & $pythonExe -m black @blackArgs 2>&1
    } else {
        $blackArgs += '--check', '--diff'
        $blackOutput = & $pythonExe -m black @blackArgs 2>&1
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-CustomLog "Black: All files properly formatted" -Level INFO
        $results.Python.BlackFormatting = 0
    } else {
        $results.Python.BlackFormatting = 1
        if ($Fix) {
            Write-CustomLog "Black: Formatting issues fixed" -Level INFO
        } else {
            Write-CustomLog "Black: Formatting issues found" -Level WARN
            if ($Detailed) {
                Write-CustomLog "Black output:" -Level INFO
                $blackOutput | ForEach-Object { Write-CustomLog "  $_" -Level INFO }
            }
        }
    }
    
    # Update total issues
    $results.Python.IssuesFound = $results.Python.Flake8Issues + $results.Python.BlackFormatting
    
    Write-CustomLog "Python analysis complete" -Level INFO
    Write-CustomLog "Files analyzed: $($results.Python.FilesAnalyzed)" -Level INFO
    Write-CustomLog "Flake8 issues: $($results.Python.Flake8Issues)" -Level INFO
    Write-CustomLog "Pylint score: $($results.Python.PylintScore)/10" -Level INFO
    Write-CustomLog "Black formatting issues: $($results.Python.BlackFormatting)" -Level INFO
}

# Execute linting based on target
switch ($Target) {
    'PowerShell' { # Invoke-PowerShellLint deprecateding }
    'Python' { Invoke-PythonLinting }
    'All' {
        # Invoke-PowerShellLint deprecateding
        Invoke-PythonLinting
    }
}

# Generate final summary
$endTime = Get-Date
$duration = $endTime - $results.StartTime

Write-CustomLog "Linting Analysis Summary" -Level INFO
Write-CustomLog "Duration: $($duration.TotalSeconds.ToString('F2')) seconds" -Level INFO

if ($Target -eq 'All' -or $Target -eq 'PowerShell') {
    Write-CustomLog "PowerShell Results:" -Level INFO
    Write-CustomLog "  Files Analyzed: $($results.PowerShell.FilesAnalyzed)" -Level INFO
    Write-CustomLog "  Total Issues: $($results.PowerShell.IssuesFound)" -Level INFO
    Write-CustomLog "  Errors: $($results.PowerShell.ErrorCount)" -Level INFO
    Write-CustomLog "  Warnings: $($results.PowerShell.WarningCount)" -Level INFO
    Write-CustomLog "  Information: $($results.PowerShell.InformationCount)" -Level INFO
}

if ($Target -eq 'All' -or $Target -eq 'Python') {
    Write-CustomLog "Python Results:" -Level INFO
    Write-CustomLog "  Files Analyzed: $($results.Python.FilesAnalyzed)" -Level INFO
    Write-CustomLog "  Flake8 Issues: $($results.Python.Flake8Issues)" -Level INFO
    Write-CustomLog "  Pylint Score: $($results.Python.PylintScore)/10" -Level INFO
    Write-CustomLog "  Black Formatting Issues: $($results.Python.BlackFormatting)" -Level INFO
}

# Determine exit code based on critical issues
$totalCriticalIssues = $results.PowerShell.ErrorCount + $results.Python.Flake8Issues + $results.Python.BlackFormatting
if ($totalCriticalIssues -eq 0) {
    Write-CustomLog "PASS: No critical issues found" -Level INFO
    exit 0
} else {
    Write-CustomLog "FAIL: $totalCriticalIssues critical issues found" -Level ERROR
    exit 1
}

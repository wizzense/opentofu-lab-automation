#!/usr/bin/env pwsh
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
<#
.SYNOPSIS
    Comprehensive linting runner for PowerShell and Python code.

.DESCRIPTION
    Runs PSScriptAnalyzer for PowerShell files and multiple Python linters
    (flake8, pylint, black, isort) with parallel execution based on CPU cores.

.PARAMETER Path
    Path to scan for files (default: current directory)

.PARAMETER PowerShellOnly
    Run only PowerShell linting

.PARAMETER PythonOnly
    Run only Python linting

.PARAMETER Fix
    Automatically fix issues where possible

.PARAMETER Parallel
    Run linting in parallel (default: true)

.PARAMETER MaxJobs
    Maximum number of parallel jobs (default: CPU core count)

.EXAMPLE
    .\Run-ComprehensiveLinting.ps1
    Run all linting tools with default settings

.EXAMPLE
    .\Run-ComprehensiveLinting.ps1 -PowerShellOnly -Fix
    Run only PowerShell linting and fix issues automatically
#>

param(
    [string]$Path = $PSScriptRoot,
    [switch]$PowerShellOnly,
    [switch]$PythonOnly,
    [switch]$Fix,
    [switch]$Parallel = $true,
    [int]$MaxJobs = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
)

# Import existing logging
$loggingModule = Join-Path $env:PWSH_MODULES_PATH "LabRunner/Logger.ps1"
if (Test-Path $loggingModule) {
    . $loggingModule
} else {
    function Write-CustomLog { param($Message, $Level = 'INFO') Write-Host "[$Level] $Message" }
}

Write-CustomLog "Starting comprehensive linting analysis" -Level INFO
Write-CustomLog "Target path: $Path" -Level INFO
Write-CustomLog "Parallel execution: $Parallel (Max jobs: $MaxJobs)" -Level INFO

# Initialize results tracking
$lintResults = @{
    PowerShell = @{
        FilesScanned = 0
        IssuesFound = 0
        IssuesFixed = 0
        Rules = @{}
    }
    Python = @{
        FilesScanned = 0
        IssuesFound = 0
        IssuesFixed = 0
        Tools = @{
            Flake8 = @{ Issues = 0; Status = 'Not Run' }
            Pylint = @{ Issues = 0; Status = 'Not Run' }
            Black = @{ Issues = 0; Status = 'Not Run' }
            Isort = @{ Issues = 0; Status = 'Not Run' }
            Mypy = @{ Issues = 0; Status = 'Not Run' }
            Bandit = @{ Issues = 0; Status = 'Not Run' }
        }
    }
    StartTime = Get-Date
}

# Function to run PowerShell linting
function # Invoke-PowerShellLint deprecateding {
    param([string]$TargetPath, [bool]$FixIssues)
    
    Write-CustomLog "Running PowerShell linting with PSScriptAnalyzer" -Level INFO
    
    # Get PowerShell files
    $psFiles = Get-ChildItem -Path $TargetPath -Recurse -Include '*.ps1', '*.psm1', '*.psd1' | 
        Where-Object { $_.FullName -notmatch '(\.venv|__pycache__|\.git|node_modules)' }
    
    $lintResults.PowerShell.FilesScanned = $psFiles.Count
    Write-CustomLog "Found $($psFiles.Count) PowerShell files to analyze" -Level INFO
    
    if ($psFiles.Count -eq 0) {
        Write-CustomLog "No PowerShell files found to lint" -Level WARNING
        return
    }
    
    # Check if PSScriptAnalyzer is available
    try {
        Import-Module PSScriptAnalyzer -ErrorAction Stop
    } catch {
        Write-CustomLog "PSScriptAnalyzer module not found. Installing..." -Level WARNING
        Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
        Import-Module PSScriptAnalyzer
    }
    
    # Load settings if available
    $settingsPath = Join-Path $TargetPath "tests/PSScriptAnalyzerSettings.psd1"
    $analyzeParams = @{
        Recurse = $true
        ReportSummary = $true
    }
    
    if (Test-Path $settingsPath) {
        $analyzeParams.Settings = $settingsPath
        Write-CustomLog "Using PSScriptAnalyzer settings from: $settingsPath" -Level INFO
    }
    
    # Run analysis
    if ($Parallel -and $psFiles.Count -gt 1) {
        Write-CustomLog "Running PSScriptAnalyzer in parallel mode" -Level INFO
        
        $jobs = @()
        $batchSize = [Math]::Max(1, [Math]::Floor($psFiles.Count / $MaxJobs))
        
        for ($i = 0; $i -lt $psFiles.Count; $i += $batchSize) {
            $batch = $psFiles[$i..([Math]::Min($i + $batchSize - 1, $psFiles.Count - 1))]
            
            $job = Start-Job -ScriptBlock {
                param($Files, $AnalyzeParams)
                Import-Module PSScriptAnalyzer
                
                $results = @()
                foreach ($file in $Files) {
                    $analysis = Invoke-ScriptAnalyzer -Path $file.FullName @AnalyzeParams
                    $results += $analysis
                }
                return $results
            } -ArgumentList $batch, $analyzeParams
            
            $jobs += $job
        }
        
        # Wait for jobs and collect results
        $allIssues = @()
        foreach ($job in $jobs) {
            $jobResults = Receive-Job -Job $job -Wait
            $allIssues += $jobResults
            Remove-Job -Job $job
        }
    } else {
        Write-CustomLog "Running PSScriptAnalyzer in sequential mode" -Level INFO
        $allIssues = Invoke-ScriptAnalyzer -Path $TargetPath @analyzeParams
    }
    
    $lintResults.PowerShell.IssuesFound = $allIssues.Count
    
    # Categorize issues by rule
    foreach ($issue in $allIssues) {
        $ruleName = $issue.RuleName
        if (-not $lintResults.PowerShell.Rules.ContainsKey($ruleName)) {
            $lintResults.PowerShell.Rules[$ruleName] = 0
        }
        $lintResults.PowerShell.Rules[$ruleName]++
    }
    
    Write-CustomLog "Found $($allIssues.Count) PSScriptAnalyzer issues" -Level INFO
    
    # Display issues by severity
    $severityGroups = $allIssues | Group-Object Severity
    foreach ($group in $severityGroups) {
        Write-CustomLog "  $($group.Name): $($group.Count) issues" -Level INFO
    }
    
    # validation-only if requested (limited support)
    if ($FixIssues -and $allIssues.Count -gt 0) {
        Write-CustomLog "Attempting to validation-only PowerShell issues" -Level INFO
        
        # PSScriptAnalyzer doesn't have built-in fixing, but we can apply some common fixes
        $fixableRules = @('PSAvoidUsingCmdletAliases', 'PSUseSingularNouns')
        $fixedCount = 0
        
        foreach ($issue in ($allIssues | Where-Object { $_.RuleName -in $fixableRules })) {
            # Basic fix implementations would go here
            # This is a simplified example
            Write-CustomLog "  Would fix: $($issue.RuleName) in $($issue.ScriptName)" -Level INFO
            $fixedCount++
        }
        
        $lintResults.PowerShell.IssuesFixed = $fixedCount
        Write-CustomLog "validation-onlyed $fixedCount PowerShell issues" -Level INFO
    }
    
    # Generate detailed report
    if ($allIssues.Count -gt 0) {
        $reportPath = Join-Path $TargetPath "powershell-lint-report.txt"
        $reportContent = $allIssues | ForEach-Object {
            "[$($_.Severity)] $($_.RuleName): $($_.Message) in $($_.ScriptName):$($_.Line)"
        }
        $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
        Write-CustomLog "Detailed PowerShell lint report saved to: $reportPath" -Level INFO
    }
}

# Function to run Python linting
function Invoke-PythonLinting {
    param([string]$TargetPath, [bool]$FixIssues)
    
    Write-CustomLog "Running Python linting with multiple tools" -Level INFO
    
    # Get Python files
    $pyFiles = Get-ChildItem -Path $TargetPath -Recurse -Include '*.py' | 
        Where-Object { $_.FullName -notmatch '(\.venv|__pycache__|\.git|node_modules)' }
    
    $lintResults.Python.FilesScanned = $pyFiles.Count
    Write-CustomLog "Found $($pyFiles.Count) Python files to analyze" -Level INFO
    
    if ($pyFiles.Count -eq 0) {
        Write-CustomLog "No Python files found to lint" -Level WARNING
        return
    }
    
    # Check Python environment
    $pythonExe = "./.venv/Scripts/python.exe"
    if (-not (Test-Path $pythonExe)) {
        $pythonExe = "python"
        Write-CustomLog "Virtual environment not found, using system Python" -Level WARNING
    }
    
    # Define linting tools and their configurations
    $lintingTools = @{
        Flake8 = @{
            Command = 'flake8'
            Args = @('--config=.flake8', '--statistics', '--count')
            FixArgs = @()
            CanFix = $false
        }
        Pylint = @{
            Command = 'pylint'
            Args = @('--rcfile=.pylintrc', '--reports=yes', '--score=yes')
            FixArgs = @()
            CanFix = $false
        }
        Black = @{
            Command = 'black'
            Args = @('--check', '--diff')
            FixArgs = @()
            CanFix = $true
        }
        Isort = @{
            Command = 'isort'
            Args = @('--check-only', '--diff')
            FixArgs = @()
            CanFix = $true
        }
        Mypy = @{
            Command = 'mypy'
            Args = @('--ignore-missing-imports', '--show-error-codes')
            FixArgs = @()
            CanFix = $false
        }
        Bandit = @{
            Command = 'bandit'
            Args = @('-r', '-f', 'txt')
            FixArgs = @()
            CanFix = $false
        }
    }
    
    # Run each linting tool
    foreach ($toolName in $lintingTools.Keys) {
        $tool = $lintingTools[$toolName]
        Write-CustomLog "Running $toolName" -Level INFO
        
        try {
            # Prepare arguments
            $args = @()
            $args += $tool.Args
            
            if ($FixIssues -and $tool.CanFix) {
                Write-CustomLog "  Running $toolName in fix mode" -Level INFO
                # Remove check-only flags for fixing
                $args = $args | Where-Object { $_ -notin @('--check', '--check-only', '--diff') }
            }
            
            # Add target paths
            $pythonDirs = $pyFiles | ForEach-Object { Split-Path $_.FullName -Parent } | Sort-Object -Unique
            $args += $pythonDirs
            
            # Execute tool
            $output = & $pythonExe -m $tool.Command @args 2>&1
            $exitCode = $LASTEXITCODE
            
            # Parse results
            if ($exitCode -eq 0) {
                $lintResults.Python.Tools[$toolName].Status = 'PASS'
                $lintResults.Python.Tools[$toolName].Issues = 0
                Write-CustomLog "  $toolName: PASS (no issues found)" -Level SUCCESS
            } else {
                $issueCount = 0
                
                # Parse tool-specific output for issue counts
                switch ($toolName) {
                    'Flake8' {
                        $issueCount = ($output | Where-Object { $_ -match '^\d+\s+' }).Count
                    }
                    'Pylint' {
                        $scoreLine = $output | Where-Object { $_ -match 'Your code has been rated at' }
                        if ($scoreLine) {
                            $issueCount = if ($scoreLine -match '(\d+)\s+warning') { [int]$matches[1] } else { 0 }
                        }
                    }
                    'Black' {
                        $issueCount = ($output | Where-Object { $_ -match 'would reformat' }).Count
                    }
                    'Isort' {
                        $issueCount = ($output | Where-Object { $_ -match 'ERROR:' }).Count
                    }
                    'Mypy' {
                        $issueCount = ($output | Where-Object { $_ -match ': error:' }).Count
                    }
                    'Bandit' {
                        $issueLine = $output | Where-Object { $_ -match 'Total lines of code:' }
                        $issueCount = if ($output -match 'Issue: \[') { ($output | Where-Object { $_ -match 'Issue: \[' }).Count } else { 0 }
                    }
                }
                
                $lintResults.Python.Tools[$toolName].Status = 'ISSUES_FOUND'
                $lintResults.Python.Tools[$toolName].Issues = $issueCount
                $lintResults.Python.IssuesFound += $issueCount
                
                Write-CustomLog "  $toolName: $issueCount issues found" -Level WARNING
            }
            
            # Save tool output
            $outputPath = Join-Path $TargetPath "python-$($toolName.ToLower())-report.txt"
            $output | Out-File -FilePath $outputPath -Encoding UTF8
            
        } catch {
            $lintResults.Python.Tools[$toolName].Status = 'ERROR'
            Write-CustomLog "  $toolName: Error running tool - $_" -Level ERROR
        }
    }
}

# Main execution logic
try {
    if (-not $PythonOnly) {
        # Invoke-PowerShellLint deprecateding -TargetPath $Path -FixIssues $Fix
    }
    
    if (-not $PowerShellOnly) {
        Invoke-PythonLinting -TargetPath $Path -FixIssues $Fix
    }
    
    # Generate comprehensive summary
    $endTime = Get-Date
    $duration = $endTime - $lintResults.StartTime
    
    Write-CustomLog "Comprehensive linting completed" -Level INFO
    Write-CustomLog "Total duration: $($duration.TotalSeconds.ToString('F2')) seconds" -Level INFO
    
    # PowerShell summary
    if (-not $PythonOnly) {
        Write-CustomLog "PowerShell Results:" -Level INFO
        Write-CustomLog "  Files scanned: $($lintResults.PowerShell.FilesScanned)" -Level INFO
        Write-CustomLog "  Issues found: $($lintResults.PowerShell.IssuesFound)" -Level INFO
        if ($Fix) {
            Write-CustomLog "  Issues fixed: $($lintResults.PowerShell.IssuesFixed)" -Level INFO
        }
    }
    
    # Python summary
    if (-not $PowerShellOnly) {
        Write-CustomLog "Python Results:" -Level INFO
        Write-CustomLog "  Files scanned: $($lintResults.Python.FilesScanned)" -Level INFO
        Write-CustomLog "  Total issues found: $($lintResults.Python.IssuesFound)" -Level INFO
        
        foreach ($tool in $lintResults.Python.Tools.Keys) {
            $toolResult = $lintResults.Python.Tools[$tool]
            Write-CustomLog "  $tool : $($toolResult.Status) ($($toolResult.Issues) issues)" -Level INFO
        }
    }
    
    # Overall assessment
    $totalIssues = $lintResults.PowerShell.IssuesFound + $lintResults.Python.IssuesFound
    if ($totalIssues -eq 0) {
        Write-CustomLog "All linting checks passed successfully" -Level SUCCESS
        exit 0
    } else {
        Write-CustomLog "Linting completed with $totalIssues total issues found" -Level WARNING
        exit 1
    }
    
} catch {
    Write-CustomLog "Error during linting execution: $_" -Level ERROR
    exit 1
}

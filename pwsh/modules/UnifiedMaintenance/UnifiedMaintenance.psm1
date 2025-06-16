#Requires -Version 7.0

<#
.SYNOPSIS
    UnifiedMaintenance PowerShell module for OpenTofu Lab Automation project

.DESCRIPTION
    This module consolidates all project maintenance functionality into a single,
    coherent system that integrates with PatchManager for change control and
    includes comprehensive automated testing workflows.

.NOTES
    - Integrates with PatchManager for all changes
    - Includes automated Pester and pytest execution
    - Provides comprehensive health monitoring
    - Supports continuous integration workflows
#>

# Module functions that will be exported
$publicFunctions = @(
    'Invoke-UnifiedMaintenance',
    'Invoke-AutomatedTestWorkflow',
    'Invoke-InfrastructureHealth',
    'Invoke-RecurringIssueTracking',
    'Start-ContinuousMonitoring'
)

# Private functions (used internally)
# 'Write-MaintenanceLog', 'Invoke-MaintenanceStep', 'Get-ProjectRoot', 'Test-Prerequisites'

# Internal logging function
function Write-MaintenanceLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'MAINTENANCE')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'INFO' { 'Cyan' }
        'SUCCESS' { 'Green' }
        'WARNING' { 'Yellow' }
        'ERROR' { 'Red' }
        'MAINTENANCE' { 'Magenta' }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-ProjectRoot {
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        return "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
    } else {
        return "/workspaces/opentofu-lab-automation"
    }
}

function Test-Prerequisites {
    param([string]$ProjectRoot)
    
    $prerequisites = @{
        'PatchManager Module' = "$ProjectRoot\pwsh\modules\PatchManager\PatchManager.psd1"
        'LabRunner Module' = "$ProjectRoot\pwsh\modules\LabRunner\LabRunner.psm1"
        'Tests Directory' = "$ProjectRoot\tests"
        'Python labctl' = "$ProjectRoot\py\labctl"
    }
    
    $missing = @()
    foreach ($prereq in $prerequisites.GetEnumerator()) {
        if (-not (Test-Path $prereq.Value)) {
            $missing += $prereq.Key
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-MaintenanceLog "Missing prerequisites: $($missing -join ', ')" "ERROR"
        return $false
    }
    
    return $true
}

function Invoke-MaintenanceStep {
    param(
        [string]$StepName,
        [scriptblock]$StepAction,
        [bool]$CriticalStep = $true
    )
    
    Write-MaintenanceLog "Starting: $StepName" "MAINTENANCE"
    try {
        $result = & $StepAction
        Write-MaintenanceLog "Completed: $StepName" "SUCCESS"
        return $result
    }
    catch {
        Write-MaintenanceLog "Failed: $StepName - $($_.Exception.Message)" "ERROR"
        if ($CriticalStep) {
            throw
        }
        return $null
    }
}

function Invoke-AutomatedTestWorkflow {
    <#
    .SYNOPSIS
        Comprehensive automated testing workflow with Pester and pytest integration
    
    .DESCRIPTION
        Executes a full testing workflow including:
        - PowerShell Pester tests with tiered execution
        - Python pytest tests with coverage
        - Performance and integration tests
        - Report generation and analysis
    
    .PARAMETER TestCategory
        Category of tests to run: Unit, Integration, Performance, All
    
    .PARAMETER GenerateCoverage
        Generate code coverage reports
    
    .PARAMETER Parallel
        Run tests in parallel for faster execution
    
    .PARAMETER OutputPath
        Path for test results and reports
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Unit', 'Integration', 'Performance', 'All')]
        [string]$TestCategory = 'All',
        
        [switch]$GenerateCoverage,
        
        [switch]$Parallel,
        
        [string]$OutputPath = "TestResults"
    )
    
    $ProjectRoot = Get-ProjectRoot
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $testResults = @{
        Timestamp = Get-Date
        TotalTests = 0
        TotalPassed = 0
        TotalFailed = 0
        Categories = @{}
    }
    
    Write-MaintenanceLog "Starting Automated Test Workflow - Category: $TestCategory" "MAINTENANCE"
    
    # 1. PowerShell Pester Tests
    if ($TestCategory -in @('Unit', 'All')) {
        Invoke-MaintenanceStep "PowerShell Pester Tests" {
            Write-MaintenanceLog "Running Pester tests..." "INFO"
            
            # Use PatchManager's tiered testing if available
            if (Get-Command Invoke-TieredPesterTests -ErrorAction SilentlyContinue) {
                $pesterResults = Invoke-TieredPesterTests -Tier 'All' -OutputFormat 'NUnit' -OutputPath $OutputPath
            }
            else {
                # Fallback to standard Pester
                $config = New-PesterConfiguration
                $config.Run.Path = "$ProjectRoot\tests"
                $config.Output.Verbosity = 'Detailed'
                $config.TestResult.Enabled = $true
                $config.TestResult.OutputPath = "$OutputPath\PesterResults.xml"
                $config.TestResult.OutputFormat = 'NUnitXml'
                
                if ($GenerateCoverage) {
                    $config.CodeCoverage.Enabled = $true
                    $config.CodeCoverage.Path = @("$ProjectRoot\pwsh\modules", "$ProjectRoot\pwsh\core_app")
                    $config.CodeCoverage.OutputPath = "$OutputPath\PesterCoverage.xml"
                }
                
                $pesterResults = Invoke-Pester -Configuration $config
            }
            
            $testResults.Categories.Pester = @{
                Total = $pesterResults.TotalCount
                Passed = $pesterResults.PassedCount
                Failed = $pesterResults.FailedCount
                Skipped = $pesterResults.SkippedCount
            }
            
            Write-MaintenanceLog "Pester: $($pesterResults.PassedCount)/$($pesterResults.TotalCount) tests passed" "INFO"
            
            return $pesterResults
        } $false
    }
    
    # 2. Python pytest Tests
    if ($TestCategory -in @('Unit', 'Integration', 'All')) {
        Invoke-MaintenanceStep "Python pytest Tests" {
            Write-MaintenanceLog "Running pytest tests..." "INFO"
            
            $pythonTestPath = "$ProjectRoot\py\tests"
            if (Test-Path $pythonTestPath) {
                $pytestArgs = @(
                    $pythonTestPath,
                    "-v",
                    "--tb=short",
                    "--junit-xml=$OutputPath\pytestResults.xml"
                )
                
                if ($GenerateCoverage) {
                    $pytestArgs += @(
                        "--cov=py.labctl",
                        "--cov-report=xml:$OutputPath\pytestCoverage.xml",
                        "--cov-report=html:$OutputPath\htmlcov"
                    )
                }
                
                $pytestResult = python -m pytest @pytestArgs
                $pytestExitCode = $LASTEXITCODE
                
                $testResults.Categories.Pytest = @{
                    ExitCode = $pytestExitCode
                    Success = $pytestExitCode -eq 0
                }
                
                Write-MaintenanceLog "pytest exit code: $pytestExitCode" "INFO"
                
                return @{ ExitCode = $pytestExitCode; Output = $pytestResult }
            }
            else {
                Write-MaintenanceLog "Python tests directory not found: $pythonTestPath" "WARNING"
                return $null
            }
        } $false
    }
    
    # 3. Integration Tests
    if ($TestCategory -in @('Integration', 'All')) {
        Invoke-MaintenanceStep "Integration Tests" {
            Write-MaintenanceLog "Running integration tests..." "INFO"
            
            # Run core app integration tests
            $integrationScript = "$ProjectRoot\tests\Integration\Test-CoreAppIntegration.ps1"
            if (Test-Path $integrationScript) {
                $integrationResult = & $integrationScript -OutputPath $OutputPath
                
                $testResults.Categories.Integration = @{
                    Success = $integrationResult.Success
                    Details = $integrationResult.Details
                }
                
                return $integrationResult
            }
            else {
                Write-MaintenanceLog "Integration test script not found" "WARNING"
                return $null
            }
        } $false
    }
    
    # 4. Performance Tests
    if ($TestCategory -in @('Performance', 'All')) {
        Invoke-MaintenanceStep "Performance Tests" {
            Write-MaintenanceLog "Running performance benchmarks..." "INFO"
            
            # Simple performance test for module loading
            $performanceResults = @{}
            
            # Test module import performance
            $moduleImportTime = Measure-Command {
                Import-Module "$ProjectRoot\pwsh\modules\LabRunner" -Force
                Import-Module "$ProjectRoot\pwsh\modules\PatchManager" -Force
            }
            
            $performanceResults.ModuleImportTime = $moduleImportTime.TotalSeconds
            
            # Test runner script performance
            $runnerPerfTime = Measure-Command {
                & "$ProjectRoot\pwsh\runner.ps1" -Scripts "help" -ErrorAction SilentlyContinue
            }
            
            $performanceResults.RunnerPerformanceTime = $runnerPerfTime.TotalSeconds
            
            $testResults.Categories.Performance = $performanceResults
            
            Write-MaintenanceLog "Module import: $($moduleImportTime.TotalSeconds.ToString('F2'))s" "INFO"
            Write-MaintenanceLog "Runner performance: $($runnerPerfTime.TotalSeconds.ToString('F2'))s" "INFO"
            
            return $performanceResults
        } $false
    }
    
    # 5. Generate comprehensive report
    Invoke-MaintenanceStep "Generate Test Report" {
        $reportContent = @"
# Automated Test Workflow Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Test Category: $TestCategory
Coverage Enabled: $($GenerateCoverage.IsPresent)
Parallel Execution: $($Parallel.IsPresent)

## Summary
"@
        
        if ($testResults.Categories.Pester) {
            $reportContent += @"

### PowerShell Pester Tests
- Total: $($testResults.Categories.Pester.Total)
- Passed: $($testResults.Categories.Pester.Passed)
- Failed: $($testResults.Categories.Pester.Failed)
- Skipped: $($testResults.Categories.Pester.Skipped)
"@
        }
        
        if ($testResults.Categories.Pytest) {
            $reportContent += @"

### Python pytest Tests  
- Exit Code: $($testResults.Categories.Pytest.ExitCode)
- Success: $($testResults.Categories.Pytest.Success)
"@
        }
        
        if ($testResults.Categories.Performance) {
            $reportContent += @"

### Performance Benchmarks
- Module Import Time: $($testResults.Categories.Performance.ModuleImportTime.ToString('F2'))s
- Runner Performance: $($testResults.Categories.Performance.RunnerPerformanceTime.ToString('F2'))s
"@
        }
        
        $reportPath = "$OutputPath\TestWorkflowReport.md"
        Set-Content -Path $reportPath -Value $reportContent
        
        Write-MaintenanceLog "Test report generated: $reportPath" "SUCCESS"
        
        return $reportPath
    } $false
    
    Write-MaintenanceLog "Automated Test Workflow completed" "SUCCESS"
    return $testResults
}

function Invoke-InfrastructureHealth {
    <#
    .SYNOPSIS
        Comprehensive infrastructure health check
    #>
    [CmdletBinding()]
    param(
        [switch]$AutoFix,
        [string]$OutputPath = "HealthReport"
    )
    
    $ProjectRoot = Get-ProjectRoot
    $healthResults = @{
        Timestamp = Get-Date
        OverallHealth = 'Unknown'
        Checks = @{}
    }
    
    Write-MaintenanceLog "Starting Infrastructure Health Check" "MAINTENANCE"
    
    # 1. Module Health
    Invoke-MaintenanceStep "Module Health Check" {
        $moduleHealth = @{}
        
        $modules = @('LabRunner', 'PatchManager')
        foreach ($module in $modules) {
            $modulePath = "$ProjectRoot\pwsh\modules\$module"
            $moduleHealth[$module] = @{
                Exists = Test-Path $modulePath
                LoadsCorrectly = $false
                Functions = @()
            }
            
            if ($moduleHealth[$module].Exists) {
                try {
                    Import-Module $modulePath -Force
                    $moduleHealth[$module].LoadsCorrectly = $true
                    $moduleHealth[$module].Functions = (Get-Command -Module $module).Name
                }
                catch {
                    Write-MaintenanceLog "Module $module failed to load: $_" "WARNING"
                }
            }
        }
        
        $healthResults.Checks.Modules = $moduleHealth
        return $moduleHealth
    } $false
    
    # 2. Script Syntax Health
    Invoke-MaintenanceStep "Script Syntax Check" {
        $scriptErrors = @()
        $scriptFiles = Get-ChildItem -Path "$ProjectRoot\pwsh" -Filter "*.ps1" -Recurse
        
        foreach ($script in $scriptFiles) {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$null)
            }
            catch {
                $scriptErrors += @{
                    File = $script.FullName
                    Error = $_.Exception.Message
                }
            }
        }
        
        $healthResults.Checks.ScriptSyntax = @{
            TotalScripts = $scriptFiles.Count
            ErrorCount = $scriptErrors.Count
            Errors = $scriptErrors
        }
        
        Write-MaintenanceLog "Script syntax check: $($scriptErrors.Count) errors in $($scriptFiles.Count) files" "INFO"
        return $scriptErrors
    } $false
    
    # 3. Test Framework Health
    Invoke-MaintenanceStep "Test Framework Health" {
        $testHealth = @{
            PesterAvailable = $null -ne (Get-Module -ListAvailable Pester)
            PytestAvailable = $null -ne (Get-Command python -ErrorAction SilentlyContinue)
            TestFilesExist = Test-Path "$ProjectRoot\tests"
        }
        
        $healthResults.Checks.TestFramework = $testHealth
        return $testHealth
    } $false
    
    # 4. Determine overall health
    $criticalIssues = 0
    if (-not $healthResults.Checks.Modules.LabRunner.LoadsCorrectly) { $criticalIssues++ }
    if (-not $healthResults.Checks.Modules.PatchManager.LoadsCorrectly) { $criticalIssues++ }
    if ($healthResults.Checks.ScriptSyntax.ErrorCount -gt 0) { $criticalIssues++ }
    
    $healthResults.OverallHealth = if ($criticalIssues -eq 0) { 'Good' } 
                                  elseif ($criticalIssues -le 2) { 'Fair' } 
                                  else { 'Poor' }
    
    Write-MaintenanceLog "Infrastructure Health: $($healthResults.OverallHealth)" "INFO"
    
    # Generate health report
    if ($OutputPath) {
        $reportContent = $healthResults | ConvertTo-Json -Depth 10
        $reportFile = "$OutputPath\InfrastructureHealth.json"
        Set-Content -Path $reportFile -Value $reportContent
        Write-MaintenanceLog "Health report saved: $reportFile" "SUCCESS"
    }
    
    return $healthResults
}

function Invoke-RecurringIssueTracking {
    <#
    .SYNOPSIS
        Track and analyze recurring issues in the project
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludePreventionCheck,
        [string]$OutputPath = "IssueTracking"
    )
    
    Write-MaintenanceLog "Starting Recurring Issue Tracking" "MAINTENANCE"
    
    # This would integrate with existing track-recurring-issues.ps1 logic
    # For now, return a placeholder structure
    return @{
        Timestamp = Get-Date
        IssuesTracked = 0
        TopIssues = @()
        PreventionStatus = 'Good'
    }
}

function Start-ContinuousMonitoring {
    <#
    .SYNOPSIS
        Start continuous monitoring of project health and testing
    #>
    [CmdletBinding()]
    param(
        [int]$IntervalMinutes = 30,
        [switch]$RunTests,
        [string]$LogPath = "ContinuousMonitoring.log"
    )
    
    Write-MaintenanceLog "Starting Continuous Monitoring (Interval: $IntervalMinutes minutes)" "MAINTENANCE"
    
    while ($true) {
        try {
            # Run health check
            $health = Invoke-InfrastructureHealth -OutputPath "ContinuousHealth"
            
            # Run tests if requested
            if ($RunTests) {
                $tests = Invoke-AutomatedTestWorkflow -TestCategory 'Unit' -OutputPath "ContinuousTests"
            }
              # Log status
            $testsPassed = if ($tests.Categories.Pester.Passed) { $tests.Categories.Pester.Passed } else { 0 }
            $testsTotal = if ($tests.Categories.Pester.Total) { $tests.Categories.Pester.Total } else { 0 }
            $status = "Health: $($health.OverallHealth)"
            if ($RunTests) {
                $status += ", Tests: $testsPassed/$testsTotal passed"
            }
            
            Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $status"
            Write-MaintenanceLog $status "INFO"
            
        }
        catch {
            Write-MaintenanceLog "Continuous monitoring error: $_" "ERROR"
        }
        
        Start-Sleep -Seconds ($IntervalMinutes * 60)
    }
}

function Invoke-UnifiedMaintenance {
    <#
    .SYNOPSIS
        Main unified maintenance function that orchestrates all maintenance activities
    
    .DESCRIPTION
        This is the primary entry point for all project maintenance activities.
        It coordinates infrastructure health, testing, issue tracking, and reporting
        while integrating with PatchManager for change control.
    
    .PARAMETER Mode
        Maintenance mode: Quick, Full, Test, TestOnly, Continuous, Track, Report, All
    
    .PARAMETER AutoFix
        Automatically apply fixes where possible
    
    .PARAMETER UpdateChangelog
        Update CHANGELOG.md with maintenance results
    
    .PARAMETER UsePatchManager
        Use PatchManager for all changes (recommended)
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Quick', 'Full', 'Test', 'TestOnly', 'Continuous', 'Track', 'Report', 'All')]
        [string]$Mode = 'Quick',
        
        [switch]$AutoFix,
        
        [switch]$UpdateChangelog,
        
        [switch]$UsePatchManager = $true
    )
    
    $ProjectRoot = Get-ProjectRoot
    
    Write-MaintenanceLog "Starting Unified Maintenance - Mode: $Mode" "MAINTENANCE"
    
    # Check prerequisites
    if (-not (Test-Prerequisites -ProjectRoot $ProjectRoot)) {
        throw "Prerequisites check failed. Cannot continue."
    }
    
    $maintenanceResults = @{
        Mode = $Mode
        Timestamp = Get-Date
        Results = @{}
        OverallSuccess = $true
    }
    
    # If using PatchManager, wrap all changes in a patch operation
    if ($UsePatchManager -and (Get-Command Invoke-GitControlledPatch -ErrorAction SilentlyContinue)) {
        Write-MaintenanceLog "Using PatchManager for change control" "INFO"
        
        $patchResult = Invoke-GitControlledPatch -PatchDescription "Unified Maintenance: $Mode" -PatchOperation {
            # Execute maintenance operations within PatchManager
            $results = Invoke-MaintenanceOperations -Mode $Mode -AutoFix:$AutoFix -UpdateChangelog:$UpdateChangelog
            return $results
        } -AutoCommitUncommitted:$AutoFix -TestCommands @(
            "pwsh -NoProfile -Command 'Import-Module $ProjectRoot\pwsh\modules\LabRunner -Force; Write-Host OK'"
        )
        
        $maintenanceResults.Results = $patchResult
    }
    else {
        Write-MaintenanceLog "Running maintenance without PatchManager" "WARNING"
        $maintenanceResults.Results = Invoke-MaintenanceOperations -Mode $Mode -AutoFix:$AutoFix -UpdateChangelog:$UpdateChangelog
    }
    
    Write-MaintenanceLog "Unified Maintenance completed successfully" "SUCCESS"
    return $maintenanceResults
}

function Invoke-MaintenanceOperations {
    param(
        [string]$Mode,
        [bool]$AutoFix,
        [bool]$UpdateChangelog
    )
    
    $results = @{}
    
    switch ($Mode) {
        'Quick' {
            $results.Health = Invoke-InfrastructureHealth -AutoFix:$AutoFix
        }
        'Full' {
            $results.Health = Invoke-InfrastructureHealth -AutoFix:$AutoFix
            $results.Issues = Invoke-RecurringIssueTracking -IncludePreventionCheck
        }
        'Test' {
            $results.Health = Invoke-InfrastructureHealth -AutoFix:$AutoFix
            $results.Tests = Invoke-AutomatedTestWorkflow -TestCategory 'All' -GenerateCoverage
        }
        'TestOnly' {
            $results.Tests = Invoke-AutomatedTestWorkflow -TestCategory 'All' -GenerateCoverage
        }
        'Continuous' {
            Start-ContinuousMonitoring -RunTests
        }
        'Track' {
            $results.Issues = Invoke-RecurringIssueTracking -IncludePreventionCheck
        }
        'Report' {
            $results.Health = Invoke-InfrastructureHealth
            $results.Issues = Invoke-RecurringIssueTracking
        }
        'All' {
            $results.Health = Invoke-InfrastructureHealth -AutoFix:$AutoFix
            $results.Tests = Invoke-AutomatedTestWorkflow -TestCategory 'All' -GenerateCoverage
            $results.Issues = Invoke-RecurringIssueTracking -IncludePreventionCheck
        }
    }
    
    return $results
}

# Module initialization
Write-MaintenanceLog "UnifiedMaintenance module loaded successfully" "SUCCESS"

# Export public functions
foreach ($function in $publicFunctions) {
    Export-ModuleMember -Function $function
}

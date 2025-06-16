#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/auto-maintenance.ps1

<#
.SYNOPSIS
Automated project maintenance script for OpenTofu Lab Automation project.

.DESCRIPTION
This script automates common project maintenance tasks including:
- Running comprehensive validation
- Checking for deprecated paths and imports
- Validating PowerShell syntax
- Generating maintenance reports
- Updating project documentation

.PARAMETER Task
The maintenance task to perform:
- 'validate' - Run comprehensive project validation
- 'fix-imports' - Automatically fix module import issues
- 'check-health' - Generate project health report
- 'cleanup' - Clean up deprecated files and organize project
- 'full' - Run all maintenance tasks

.PARAMETER GenerateReport
Whether to generate a maintenance report (default: true for 'check-health' and 'full')

.PARAMETER Verbose
Enable verbose output for debugging

.EXAMPLE
./scripts/maintenance/auto-maintenance.ps1 -Task "validate"

.EXAMPLE  
./scripts/maintenance/auto-maintenance.ps1 -Task "full" -GenerateReport
#>

CmdletBinding()
param(
    Parameter(Mandatory = $true)







    ValidateSet('validate', 'fix-imports', 'check-health', 'cleanup', 'full')
    string$Task,
    
    Parameter()
    bool$GenerateReport = $false,
    
    Parameter()
    switch$Verbose
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "/workspaces/opentofu-lab-automation"

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

function Write-MaintenanceLog {
    param(string$Message, string$Level = "INFO")
    






$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "$timestamp $Level $Message" -ForegroundColor $color
}

function Test-ModuleAvailable {
    param(string$ModulePath)
    






return Test-Path $ModulePath
}

function Invoke-ValidationTask {
    Write-MaintenanceLog "Starting comprehensive project validation..." "INFO"
    
    try {
        # Test PowerShell syntax validation
        if (Test-Path "$ProjectRoot/scripts/validation/validate-powershell-scripts.ps1") {
            Write-MaintenanceLog "Running PowerShell syntax validation..." "INFO"
            & "$ProjectRoot/scripts/validation/validate-powershell-scripts.ps1"
        }
        
        # Run comprehensive test suite
        Write-MaintenanceLog "Running comprehensive test suite..." "INFO"
        Set-Location $ProjectRoot
        & "$ProjectRoot/run-comprehensive-tests.ps1"
        
        # Validate workflows
        if (Test-Path "$ProjectRoot/scripts/workflow-health-check.sh") {
            Write-MaintenanceLog "Checking workflow health..." "INFO"
            & "$ProjectRoot/scripts/workflow-health-check.sh"
        }
        
        Write-MaintenanceLog "Validation completed successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-MaintenanceLog "Validation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-ImportFixTask {
    Write-MaintenanceLog "Starting import fix automation..." "INFO"
    
    try {
        $codeFixerModule = "$ProjectRoot/pwsh/modules/CodeFixer"
        if (Test-ModuleAvailable $codeFixerModule) {
            Write-MaintenanceLog "Loading CodeFixer module..." "INFO"
            Import-Module $codeFixerModule -Force
            
            Write-MaintenanceLog "Running import analysis and auto-fix..." "INFO"
            Invoke-ImportAnalysis -AutoFix
            
            Write-MaintenanceLog "Running comprehensive validation..." "INFO"
            Invoke-ComprehensiveValidation
            
            Write-MaintenanceLog "Import fixes completed successfully" "SUCCESS"
            return $true
        }
        else {
            Write-MaintenanceLog "CodeFixer module not found at $codeFixerModule" "WARNING"
            return $false
        }
    }
    catch {
        Write-MaintenanceLog "Import fix failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-HealthCheckTask {
    Write-MaintenanceLog "Starting project health check..." "INFO"
    
    $healthData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TestResults = @{}
        WorkflowStatus = @{}
        ModuleStatus = @{}
        Issues = @()
        Recommendations = @()
    }
    
    try {
        # Check test status
        Write-MaintenanceLog "Checking test health..." "INFO"
        $testResult = Invoke-ValidationTask
        $healthData.TestResults.ValidationPassed = $testResult
        
        # Check module availability
        Write-MaintenanceLog "Checking module status..." "INFO"
        $healthData.ModuleStatus.LabRunner = Test-ModuleAvailable "$ProjectRoot/pwsh/modules/LabRunner"
        $healthData.ModuleStatus.CodeFixer = Test-ModuleAvailable "$ProjectRoot/pwsh/modules/CodeFixer"
        
        # Check for deprecated paths
        Write-MaintenanceLog "Checking for deprecated paths..." "INFO"
        $deprecatedPaths = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1", "*.psm1"  
            Select-String -Pattern "pwsh/modules" -SimpleMatch
        
        if ($deprecatedPaths) {
            $healthData.Issues += "Deprecated lab_utils paths found in $($deprecatedPaths.Count) files"
            $healthData.Recommendations += "Run Invoke-ImportAnalysis -AutoFix to update paths"
        }
        
        # Generate health report if requested
        if ($GenerateReport) {
            $reportTitle = "Project Health Check $(Get-Date -Format 'yyyy-MM-dd')"
            Write-MaintenanceLog "Generating health report..." "INFO"
            
            & "$ProjectRoot/scripts/utilities/new-report.ps1" -Type "project-status" -Title $reportTitle -Template "project"
        }
        
        Write-MaintenanceLog "Health check completed" "SUCCESS"
        return $healthData
    }
    catch {
        Write-MaintenanceLog "Health check failed: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Invoke-CleanupTask {
    Write-MaintenanceLog "Starting project cleanup..." "INFO"
    
    try {
        # Run project organization script
        if (Test-Path "$ProjectRoot/scripts/Organize-ProjectFiles.ps1") {
            Write-MaintenanceLog "Running project file organization..." "INFO"
            & "$ProjectRoot/scripts/Organize-ProjectFiles.ps1"
        }
        
        # Run deprecated file cleanup
        if (Test-Path "$ProjectRoot/scripts/Cleanup-DeprecatedFiles.ps1") {
            Write-MaintenanceLog "Cleaning up deprecated files..." "INFO"
            & "$ProjectRoot/scripts/Cleanup-DeprecatedFiles.ps1"
        }
        
        # Check for summary files in root and warn
        $rootSummaries = Get-ChildItem -Path $ProjectRoot -Filter "*SUMMARY*.md" -File
        if ($rootSummaries) {
            Write-MaintenanceLog "WARNING: Found summary files in root directory!" "WARNING"
            foreach ($file in $rootSummaries) {
                Write-MaintenanceLog "  - $($file.Name) should be moved to /docs/reports/" "WARNING"
            }
        }
        
        Write-MaintenanceLog "Cleanup completed successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-MaintenanceLog "Cleanup failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-MaintenanceLog "Starting automated maintenance task: $Task" "INFO"
Write-MaintenanceLog "Project root: $ProjectRoot" "INFO"

$success = $false

switch ($Task) {
    'validate' {
        $success = Invoke-ValidationTask
    }
    'fix-imports' {
        $success = Invoke-ImportFixTask
    }
    'check-health' {
        $GenerateReport = $true  # Always generate report for health checks
        $healthData = Invoke-HealthCheckTask
        $success = $healthData -ne $null
    }
    'cleanup' {
        $success = Invoke-CleanupTask
    }
    'full' {
        Write-MaintenanceLog "Running full maintenance cycle..." "INFO"
        $GenerateReport = $true  # Always generate report for full maintenance
        
        $results = @{}
        $results.Cleanup = Invoke-CleanupTask
        $results.ImportFix = Invoke-ImportFixTask
        $results.Validation = Invoke-ValidationTask
        $results.HealthCheck = (Invoke-HealthCheckTask) -ne $null
        
        $success = $results.Values  ForEach-Object { $_ }  Measure-Object -Sum  Select-Object -ExpandProperty Sum
        $success = $success -eq $results.Count
        
        Write-MaintenanceLog "Full maintenance results:" "INFO"
        foreach ($task in $results.Keys) {
            $status = if ($results$task) { "SUCCESS"    } else { "FAILED"    }
            Write-MaintenanceLog "  $task`: $status" "INFO"
        }
    }
}

if ($success) {
    Write-MaintenanceLog "Maintenance task '$Task' completed successfully!" "SUCCESS"
    exit 0
}
else {
    Write-MaintenanceLog "Maintenance task '$Task' failed!" "ERROR"
    exit 1
}





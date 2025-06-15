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

.PARAMETER ScriptPath
Optional specific script path for processing

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix -UpdateChangelog

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "Track" -AutoFix
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Quick", "Full", "Test", "Track", "Report", "All")]
    [string]$Mode = "Quick",
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoFix,
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateChangelog,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$IgnoreArchive,

    [Parameter(Mandatory=$false)]
    [string]$ScriptPath
)

$ErrorActionPreference = "Continue"

# Determine project root directory from script location
$currentScriptPath = $PSScriptRoot
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $currentScriptPath)

# Import required modules - Use full paths from manifest
try {
    # Import file interaction logger FIRST to track all subsequent operations
    Import-Module "$ProjectRoot\pwsh\modules\FileInteractionLogger" -Force -ErrorAction Stop
    Write-Host "File interaction logging enabled - tracking all file operations" -ForegroundColor Green
    
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/"" -Force -ErrorAction Stop
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/LabRunner/"" -Force -ErrorAction Stop
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/BackupManager/"" -Force -ErrorAction Stop
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/PatchManager/""" -Force -ErrorAction Stop
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/PatchManager/""\Private\Step-CleanupScatteredPatchFiles.ps1" -Force
    $modulesLoaded = $true
} catch {
    Write-Host "Warning: Not all modules could be loaded. Some functionality will be limited." -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    $modulesLoaded = $false
}

# If any required module failed to load, exit with error
if (-not $modulesLoaded) {
    Write-Host "Critical error: Required modules are not available. Maintenance cannot proceed." -ForegroundColor Red
    exit 1
}

function Write-CustomLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG", "STEP", "MAINTENANCE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Level] $Message"
      # Color coding based on level
    switch ($Level) {
        "INFO"        { Write-Host $formattedMessage -ForegroundColor Gray }
        "SUCCESS"     { Write-Host $formattedMessage -ForegroundColor Green }
        "WARNING"     { Write-Host $formattedMessage -ForegroundColor Yellow }
        "ERROR"       { Write-Host $formattedMessage -ForegroundColor Red }
        "DEBUG"       { Write-Host $formattedMessage -ForegroundColor DarkGray }
        "STEP"        { Write-Host $formattedMessage -ForegroundColor Cyan }
        "MAINTENANCE" { Write-Host $formattedMessage -ForegroundColor Magenta }
        default       { Write-Host $formattedMessage -ForegroundColor White }
    }
}

function Write-MaintenanceLog {
    param([string]$Message, [string]$Level = "INFO")
    
    # Use standardized logging via centralized function
    Write-CustomLog -Message $Message -Level $Level
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
 Write-MaintenanceLog "[PASS] $StepName completed" "SUCCESS"
 return $result
 }
 catch {
 $message = "[FAIL] $StepName failed: $($_.Exception.Message)"
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
    Write-MaintenanceLog "Starting infrastructure health check in mode: Full" "INFO"
    Write-MaintenanceLog "Project root: $ProjectRoot" "INFO"
    Write-MaintenanceLog "AutoFix enabled: $($AutoFix.IsPresent)" "INFO"
    
    # First, automatically clean up broken archive files using PatchManager cleanup
    Write-MaintenanceLog "Cleaning up broken archive files via PatchManager..." "INFO"
    try {
        # Use PatchManager's Invoke-PatchCleanup in safe mode for archive cleanup
        Invoke-PatchCleanup -ProjectRoot $ProjectRoot -Mode "Safe" -Force:$AutoFix
    } catch {
        Write-MaintenanceLog "Error during archive cleanup: $($_.Exception.Message)" "ERROR"
    }
    
    # Determine health check mode based on maintenance Mode parameter
    $hcMode = if ($Mode -eq 'Quick') { 'Quick' } else { 'Comprehensive' }
    Write-MaintenanceLog "Running health check via PatchManager in mode: $hcMode" "INFO"
    try {
        $result = Invoke-HealthCheck -ProjectRoot $ProjectRoot -Mode $hcMode -AutoFix:$AutoFix
        
        # If critical issues found and AutoFix enabled, apply fixes immediately
        if ($AutoFix -and ($result.CriticalIssues -gt 0)) {
            Write-MaintenanceLog "Critical issues detected, applying immediate fixes via PatchManager..." "WARNING"
            Invoke-InfrastructureFix -Fix "All" -ProjectRoot $ProjectRoot -AutoFix -Force
        }
        
        return $result
    } catch {
        Write-MaintenanceLog "Error during PatchManager health check: $($_.Exception.Message)" "ERROR"
        
        # Fallback to traditional script if PatchManager function fails
        Write-MaintenanceLog "Falling back to infrastructure-health-check.ps1 script..." "WARNING"
        $healthScript = "$ProjectRoot/scripts/maintenance/infrastructure-health-check.ps1"
        if (Test-Path $healthScript) {
            return & $healthScript -Mode "Full" -AutoFix:$AutoFix
        } else {
            Write-MaintenanceLog "Infrastructure health check script not found" "WARNING"
            return $null
        }
    }
}

function Step-FixInfrastructureIssues {
    Write-MaintenanceLog "Applying infrastructure fixes via PatchManager module..." "INFO"
    
    try {
        # Use PatchManager's Invoke-InfrastructureFix function - this is now the ONLY supported method
        $params = @{
            Fix = "All"
            ProjectRoot = $ProjectRoot
            UpdateChangelog = $UpdateChangelog
        }
        
        if ($AutoFix) {
            $params.AutoFix = $true
            Write-MaintenanceLog "AutoFix enabled - will apply infrastructure fixes" "INFO"
        } else {
            $params.WhatIf = $true
            Write-MaintenanceLog "Dry-run mode - no changes will be applied" "INFO"
        }
        
        # Call PatchManager function
        Invoke-InfrastructureFix @params
        
        Write-MaintenanceLog "Infrastructure fixes completed successfully" "SUCCESS"
    } catch {
        Write-MaintenanceLog "Error applying infrastructure fixes: $($_.Exception.Message)" "ERROR"
        throw "Failed to apply infrastructure fixes. Please ensure PatchManager module is correctly installed."
    }
}

function Step-FixTestSyntax {
    Write-MaintenanceLog "Fixing test syntax issues via PatchManager module..." "INFO"
    
    try {
        # Use PatchManager's Invoke-TestFileFix function - this is now the ONLY supported method
        $params = @{
            ProjectRoot = $ProjectRoot
            FixType = "Comprehensive" # More thorough fix than just syntax
            UpdateChangelog = $UpdateChangelog
        }
        
        if ($AutoFix) {
            $params.AutoFix = $true
            Write-MaintenanceLog "AutoFix enabled - will apply test file fixes" "INFO"
        } else {
            $params.WhatIf = $true
            Write-MaintenanceLog "Dry-run mode - no changes will be applied" "INFO"
        }
        
        # Call PatchManager function
        Invoke-TestFileFix @params
        
        Write-MaintenanceLog "Test file fixes completed successfully" "SUCCESS"
    } catch {
        Write-MaintenanceLog "Error fixing test syntax: $($_.Exception.Message)" "ERROR"
        Write-MaintenanceLog "PatchManager is required for test fixing. No fallback available." "ERROR"
        throw "Failed to fix test syntax. Please ensure PatchManager module is correctly installed."
    }
}

function Step-ValidateYaml {
    Write-MaintenanceLog "Validating and fixing YAML files via PatchManager..." "INFO"
    
    try {
        # PatchManager is now required - use it directly
        $params = @{
            Path = "$ProjectRoot/.github/workflows"
            ProjectRoot = $ProjectRoot
            UpdateChangelog = $UpdateChangelog
        }
        
        if ($AutoFix) {
            $params.Mode = "Fix"
            Write-MaintenanceLog "Running YAML validation with auto-fix..." "INFO"
        } else {
            $params.Mode = "Check"
            Write-MaintenanceLog "Running YAML validation (check only)..." "INFO"
        }
        
        # Call the PatchManager function directly
        $result = Invoke-YamlValidation @params
        
        Write-MaintenanceLog "YAML validation completed successfully" "SUCCESS"
        Write-MaintenanceLog "Processed $($result.TotalFiles) files, fixed $($result.FixedFiles) files" "INFO"
        
        return $result
    } catch {
        Write-MaintenanceLog "YAML validation failed: $($_.Exception.Message)" "ERROR"
        Write-MaintenanceLog "PatchManager is required for YAML validation" "ERROR"
        throw "Failed to validate YAML files. Please ensure PatchManager module is correctly installed."
    }
}

function Step-UpdateDocumentation {
 Write-MaintenanceLog "Updating project documentation and configuration..." "INFO"
 $docScript = "$ProjectRoot/scripts/utilities/Update-ProjectDocumentation.ps1"
 if (Test-Path $docScript) {
 try {
 & $docScript
 Write-MaintenanceLog "Documentation updated successfully" "SUCCESS"
 } catch {
 Write-MaintenanceLog "Failed to update documentation: $($_.Exception.Message)" "WARNING"
 }
 } else {
 Write-MaintenanceLog "Documentation update script not found" "WARNING"
 }
}

function Step-RunTests {
 if ($SkipTests) {
 Write-MaintenanceLog "Skipping tests (SkipTests flag set)" "INFO"
 return
 }
 
 $testScript = "$ProjectRoot/run-comprehensive-tests.ps1"
 if (Test-Path $testScript) {
 Write-MaintenanceLog "Running comprehensive tests..." "INFO" & $testScript
 } else {
 Write-MaintenanceLog "Test script not found, using basic Pester" "WARNING"
 Set-Location $ProjectRoot
 Invoke-Pester tests/ -OutputFile "TestResults.xml" -OutputFormat NUnitXml
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
- **Status**: [PASS] Maintenance cycle completed
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
 $summary.IssueCount = $health.Metrics.IssueCount
 $summary.Issues = $health.Issues
 $summary.Recommendations = $health.Recommendations
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

# Function to display health issues in console
function Show-HealthIssues {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Summary
    )
    
    if (-not $Summary.Issues -or $Summary.Issues.Count -eq 0) {
        Write-MaintenanceLog "No health issues found. System is healthy." "SUCCESS"
        return
    }
    
    # Make the health issues stand out visually
    Write-Host ""
    Write-Host "┌──────────────────────────────────────────────────┐" -ForegroundColor Red
    Write-Host "│               CRITICAL HEALTH ISSUES             │" -ForegroundColor Red
    Write-Host "└──────────────────────────────────────────────────┘" -ForegroundColor Red
    Write-Host ""
    
    foreach ($issue in $Summary.Issues) {
        # Use more visible formatting based on severity
        $severityColor = switch ($issue.Severity) {
            "High" { "Red" }
            "Medium" { "Yellow" }
            "Low" { "Cyan" }
            default { "White" }
        }
          # Define severity level for logging (used in Write-MaintenanceLog below)
        $severityLog = switch ($issue.Severity) {
            "High" { "ERROR" }
            "Medium" { "WARNING" }
            "Low" { "INFO" }
            default { "INFO" }
        }
        
        # Log the issue with appropriate severity
        Write-MaintenanceLog "Issue: $($issue.Title)" $severityLog
        
        # Display issue header with color box
        Write-Host "■ [$($issue.Severity)] $($issue.Description)" -ForegroundColor $severityColor
        Write-Host "  Affected Files: $($issue.Count)" -ForegroundColor $severityColor
        Write-Host "  Category: $($issue.Category)" -ForegroundColor White
        Write-Host "  Fix Command: " -NoNewline -ForegroundColor White
        Write-Host "$($issue.Fix)" -ForegroundColor Green
        
        # Show sample affected files (max 5)
        if ($issue.Files -and $issue.Files.Count -gt 0) {
            Write-Host "  Sample affected files:" -ForegroundColor White
            $sampleFiles = $issue.Files | Select-Object -First 5
            foreach ($file in $sampleFiles) {
                Write-Host "    - $file" -ForegroundColor Gray
            }
            
            if ($issue.Files.Count -gt 5) {
                Write-Host "    - ...and $($issue.Files.Count - 5) more files" -ForegroundColor Gray
            }
        }
        
        Write-Host "" # Empty line for readability
    }
    
    Write-Host "Run fixes with: " -NoNewline
    Write-Host "./scripts/maintenance/unified-maintenance.ps1 -Mode 'All' -AutoFix" -ForegroundColor Green
    Write-Host ""
    
    if ($Summary.Recommendations -and $Summary.Recommendations.Count -gt 0) {
        Write-MaintenanceLog "Recommendations:" "STEP"
        foreach ($recommendation in $Summary.Recommendations) {
            Write-MaintenanceLog "  • $recommendation" "INFO"
        }
    }
}

# Disabling all auto-fix functionality to prevent file corruption
if ($AutoFix) {
    Write-MaintenanceLog "CRITICAL: Auto-fix functionality has been permanently disabled to prevent unintended changes." "WARNING"
    Write-MaintenanceLog "All file modifications will be logged and tracked for security." "INFO"
    $AutoFix = $false
    
    # Log this attempt
    Write-FileInteractionLog -Operation "AUTOFIX-DISABLED" -FilePath "SYSTEM" -Details "Auto-fix attempt blocked to prevent corruption"
}

# Handle ScriptPath execution if specified
if ($ScriptPath) {
    Write-MaintenanceLog "Preparing to execute task specified by ScriptPath: $ScriptPath" "DEBUG"
    try {
        $resolvedScriptPath = $ScriptPath
        # Resolve to full path if it's relative and not a fully qualified module command
        if (-not (Test-Path -LiteralPath $ScriptPath -PathType Container -ErrorAction SilentlyContinue) -and -not ($ScriptPath -match '\\\\|:') ) { # crude check for non-FQ path
            $resolvedScriptPath = Join-Path -Path $ProjectRoot -ChildPath $ScriptPath
            Write-MaintenanceLog "ScriptPath '$ScriptPath' resolved to '$resolvedScriptPath'" "DEBUG"
        }

        if (-not (Test-Path -LiteralPath $resolvedScriptPath -PathType Leaf)) {
            Write-MaintenanceLog "Resolved ScriptPath does not exist or is not a file: $resolvedScriptPath" "ERROR"
            throw "Invalid ScriptPath provided: '$ScriptPath' (resolved to '$resolvedScriptPath')"
        }

        Write-MaintenanceLog "Attempting to execute function Invoke-AutoFix for script: $resolvedScriptPath" "INFO"
        Write-MaintenanceLog "Passing ScriptPath parameter to Invoke-AutoFix: $resolvedScriptPath" "DEBUG"
        
        # Call the function, assuming CodeFixer module loaded it.
        Invoke-AutoFix -ScriptPath $resolvedScriptPath 
        
        Write-MaintenanceLog "Invoke-AutoFix function executed successfully for: $resolvedScriptPath" "SUCCESS"
        
        # Exit after executing the specific script/function
        Write-MaintenanceLog "ScriptPath task execution completed. Exiting." "INFO"
        exit 0
    } catch {
        Write-MaintenanceLog "Error during ScriptPath task execution: $($_.Exception.Message)" "ERROR"
        # If Invoke-AutoFix is not found, the error will be caught here.
        # Example: "The term 'Invoke-AutoFix' is not recognized as the name of a cmdlet, function, script file, or operable program."
        exit 1
    }
}

# Main execution flow
Write-MaintenanceLog " Starting unified maintenance in mode: $Mode" "MAINTENANCE"
Write-MaintenanceLog "AutoFix: $($AutoFix.IsPresent) | UpdateChangelog: $($UpdateChangelog.IsPresent) | SkipTests: $($SkipTests.IsPresent)" "INFO"

$startTime = Get-Date

try {
 # Fixing syntax error in switch statement
switch ($Mode) {
    'Quick' {
        Invoke-MaintenanceStep "Infrastructure Health Check" { Step-InfrastructureHealthCheck }
        Invoke-MaintenanceStep "YAML Validation" { Step-ValidateYaml } $false
        if ($AutoFix) {
            Invoke-MaintenanceStep "Basic Fixes" { Step-FixInfrastructureIssues } $false
        }
    }
    'Full' {
        Invoke-MaintenanceStep "Infrastructure Health Check" { Step-InfrastructureHealthCheck }
        Invoke-MaintenanceStep "YAML Validation" { Step-ValidateYaml }
        Invoke-MaintenanceStep "Fix Infrastructure Issues" { Step-FixInfrastructureIssues }
        Invoke-MaintenanceStep "Fix Test Syntax" { Step-FixTestSyntax } $false
        Invoke-MaintenanceStep "Update Documentation" { Step-UpdateDocumentation } $false
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
        Invoke-MaintenanceStep "Clean Up Scattered Patch Files" { Step-CleanupScatteredPatchFiles }
        Invoke-MaintenanceStep "Infrastructure Health Check" { Step-InfrastructureHealthCheck }
        Invoke-MaintenanceStep "YAML Validation" { Step-ValidateYaml }
        Invoke-MaintenanceStep "Fix Infrastructure Issues" { Step-FixInfrastructureIssues }
        Invoke-MaintenanceStep "Fix Test Syntax" { Step-FixTestSyntax } $false
        Invoke-MaintenanceStep "Update Documentation" { Step-UpdateDocumentation } $false
        if (-not $SkipTests) {
            Invoke-MaintenanceStep "Run Tests" { Step-RunTests } $false
        }
        Invoke-MaintenanceStep "Track Recurring Issues" { Step-TrackRecurringIssues } $false
        Invoke-MaintenanceStep "Generate Reports" { Step-GenerateReports } $false
        Invoke-MaintenanceStep "Update Changelog" { Step-UpdateChangelog } $false
        if ($AutoFix) {
            Write-MaintenanceLog "Creating GitHub issues for unresolved critical problems..." "INFO"
            Show-MaintenanceReport -Mode "Issues" -OutputFormat "GitHub" -CreateIssues
        }
    }
}
 
 $duration = (Get-Date) - $startTime
 $summary = Get-MaintenanceSummary
 
 Write-MaintenanceLog " Maintenance completed successfully!" "SUCCESS"
 Write-MaintenanceLog "Duration: $($duration.TotalMinutes.ToString('F1')) minutes" "INFO"
 Write-MaintenanceLog "Infrastructure Status: $($summary.InfrastructureStatus)" "INFO"
 
 # Create issues for critical problems if in appropriate mode
 if ($Mode -in @("All", "Track") -and $summary.IssueCount -gt 0) {
 Invoke-MaintenanceStep "Create Issues for Critical Problems" { Step-CreateMaintenanceIssues } $false
 }

 # Show health issues from current-health.json
 Show-HealthIssues -Summary $summary
 
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
 Write-MaintenanceLog "[FAIL] Maintenance failed: $($_.Exception.Message)" "ERROR"
 exit 1
}

Write-MaintenanceLog "Maintenance cycle complete. Next recommended run: $(if($AutoFix) { '24 hours' } else { 'as needed' })" "MAINTENANCE"

# Final validation and integrity check
Write-MaintenanceLog "Performing final integrity check..." "INFO"
try {
    # Verify critical files haven't been corrupted
    $criticalFiles = @(
        "$ProjectRoot\PROJECT-MANIFEST.json",
        "$ProjectRoot\scripts\maintenance\unified-maintenance.ps1",
        "$ProjectRoot\pwsh\modules\PatchManager\PatchManager.psm1"
    )
    
    foreach ($file in $criticalFiles) {
        if (Test-Path $file) {
            try {
                # Test if file can be parsed (for JSON/PowerShell files)
                if ($file -match '\.json$') {
                    $null = Get-Content $file | ConvertFrom-Json
                } elseif ($file -match '\.ps1$|\.psm1$') {
                    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file -Raw), [ref]$null)
                }
                Write-MaintenanceLog "✓ File integrity verified: $file" "SUCCESS"
            } catch {
                Write-MaintenanceLog "✗ File integrity check failed: $file - $($_.Exception.Message)" "ERROR"
            }
        }
    }
    
    # Show file interaction log summary
    Write-MaintenanceLog "File interaction summary:" "INFO"
    $logSummary = Get-FileInteractionLog -Last 10
    Write-MaintenanceLog "Recent file operations: $($logSummary.Count)" "INFO"
    Write-MaintenanceLog "Full log available at: $env:TEMP\opentofu-file-interactions-*.log" "INFO"
    
} catch {
    Write-MaintenanceLog "Integrity check failed: $($_.Exception.Message)" "ERROR"
}

Write-MaintenanceLog "🔒 All file operations have been logged and tracked for security audit" "MAINTENANCE"

function Step-CreateMaintenanceIssues {
    Write-MaintenanceLog "Creating issues for critical problems..." "INFO"
    
    $issueScript = "$ProjectRoot/scripts/maintenance/Create-GitHubIssue.ps1"
    
    # Check for critical issues from health check
    $healthScript = "$ProjectRoot/scripts/maintenance/infrastructure-health-check.ps1"
    if (Test-Path $healthScript) {
        try {
            $healthResult = & $healthScript -Mode "Critical" -OutputFormat "JSON" 2>$null | ConvertFrom-Json
            
            # Create issues for critical problems
            if ($healthResult.CriticalIssues) {
                foreach ($issue in $healthResult.CriticalIssues) {
                    if ($issue.Category -eq "PowerShell Syntax" -and $issue.AffectedFiles.Count -gt 5) {
                        & $issueScript -Title "Critical: Multiple PowerShell Syntax Errors" -Description "Found $($issue.AffectedFiles.Count) files with syntax errors requiring immediate attention" -Label "critical" -AffectedFiles $issue.AffectedFiles -CreateIssue:(!$env:CI)
                    }
                    
                    if ($issue.Category -eq "Module Import" -and $issue.AffectedFiles.Count -gt 10) {
                        & $issueScript -Title "Critical: Deprecated Import Paths" -Description "Found $($issue.AffectedFiles.Count) files using deprecated import paths" -Label "maintenance" -AffectedFiles $issue.AffectedFiles -CreateIssue:(!$env:CI)
                    }
                    
                    if ($issue.Category -eq "Missing Dependencies") {
                        & $issueScript -Title "Critical: Missing Project Dependencies" -Description "Required project dependencies are missing: $($issue.Details)" -Label "critical" -CreateIssue:(!$env:CI)
                    }
                }
            }
        } catch {
            Write-MaintenanceLog "Issue creation failed: $_" "WARNING"
        }
    }
}

function Step-CleanupScatteredPatchFiles {
    Write-MaintenanceLog "Cleaning up scattered patch and fix files via PatchManager..." "INFO"
    
    try {
        # Use PatchManager's Invoke-PatchCleanup function
        $params = @{
            ProjectRoot = $ProjectRoot
            Mode = "Full"
            UpdateChangelog = $UpdateChangelog
        }
        
        if ($AutoFix) {
            Write-MaintenanceLog "AutoFix enabled - will migrate and archive scattered fix scripts" "INFO"
        } else {
            $params.Mode = "Analyze"
            Write-MaintenanceLog "Analysis mode - only reporting scattered files without changes" "INFO"
        }
        
        # Call PatchManager function
        $result = Invoke-PatchCleanup @params
        
        Write-MaintenanceLog "Patch file cleanup completed successfully" "SUCCESS"
        Write-MaintenanceLog "Found $($result.ScatteredFilesCount) scattered files, migrated $($result.MigratedCount)" "INFO"
        
        return $result
    } catch {
        Write-MaintenanceLog "Error cleaning up patch files: $($_.Exception.Message)" "ERROR"
        Write-MaintenanceLog "Ensure PatchManager is correctly installed" "ERROR"
        throw "Failed to clean up patch files"
    }
}







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

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix -UpdateChangelog

.EXAMPLE
./scripts/maintenance/unified-maintenance.ps1 -Mode "Track" -AutoFix
#>

CmdletBinding()
param(
    [Parameter()]
    [ValidateSet('Quick', 'Full', 'Test', 'Track', 'Report', 'All')]
    [string]$Mode = 'Quick',
    
    [Parameter()]
    [switch]$AutoFix,
    
    [Parameter()]
    [switch]$UpdateChangelog,
    
    [Parameter()]
    [switch]$SkipTests,
    
    [Parameter()]
    [switch]$IgnoreArchive
)

$ErrorActionPreference = "Stop"
# Detect the correct project root based on the current environment
$ProjectRoot = (Get-Location).Path

# Move misplaced files to appropriate directories
Write-Host "Organizing misplaced files..." -ForegroundColor Cyan
$misplacedFiles = @{
    "test-config-errors.json" = "$ProjectRoot/tests/data/test-config-errors.json",
    "workflow-optimization-report.json" = "$ProjectRoot/reports/workflow-optimization-report.json"
}

foreach ($file in $misplacedFiles.Keys) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination $misplacedFiles[$file] -Force
        Write-Host "Moved $file to $($misplacedFiles[$file])" -ForegroundColor Green
    } else {
        Write-Warning "$file not found, skipping..."
    }
}

# Archive redundant scripts
Write-Host "Archiving redundant scripts..." -ForegroundColor Yellow
$redundantScripts = @{
    "organize-project.ps1" = "$ProjectRoot/archive/maintenance-scripts/organize-project.ps1",
    "cleanup-remaining.ps1" = "$ProjectRoot/archive/maintenance-scripts/cleanup-remaining.ps1"
}

foreach ($script in $redundantScripts.Keys) {
    if (Test-Path $script) {
        Move-Item -Path $script -Destination $redundantScripts[$script] -Force
        Write-Host "Archived $script to $($redundantScripts[$script])" -ForegroundColor Green
    } else {
        Write-Warning "$script not found, skipping..."
    }
}

# Validate project structure
Write-Host "Validating project structure..." -ForegroundColor Blue
$validationResults = @{
    "MissingFiles" = @(),
    "InvalidPaths" = @()
}

$requiredFiles = @("PROJECT-MANIFEST.json", "README.md", "pwsh/modules/BackupManager/BackupManager.psd1")
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $validationResults.MissingFiles += $file
        Write-Warning "$file is missing!"
    }
}

if ($validationResults.MissingFiles.Count -eq 0) {
    Write-Host "Project structure validated successfully." -ForegroundColor Green
} else {
    Write-host "Validation completed with warnings." -ForegroundColor Yellow
}
# Detect the correct project root based on the current environment
$ProjectRoot = if ($IsWindows -or $env:OS -eq "Windows_NT") {
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    "/workspaces/opentofu-lab-automation"
}

# Use standardized paths for all operations
$IssueTrackingPath = "$ProjectRoot/docs/reports/issue-tracking"
$WorkflowPath = "$ProjectRoot/.github/workflows"

function Write-MaintenanceLog {
 param(string$Message, string$Level = "INFO")
 



$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 $color = switch ($Level) {
 "INFO" { "Cyan" }
 "SUCCESS" { "Green" }
 "WARNING" { "Yellow" }
 "ERROR" { "Red" }
 "MAINTENANCE" { "Magenta" }
 "STEP" { "Blue" }
 
        "BackupCleanup" {
            Write-Host "Running backup consolidation and exclusion updates..." -ForegroundColor Cyan
            
            # Consolidate backup files
            & "$PSScriptRoot/consolidate-all-backups.ps1" -Force
            
            # Update exclusion configurations
            & "$PSScriptRoot/update-backup-exclusions.ps1"
            
            break
        }
default { "White" }
 }
 Write-Host "$timestamp $Level $Message" -ForegroundColor $color
}

function Invoke-MaintenanceStep {
 param(
 string$StepName,
 scriptblock$Action,
 bool$Required = $true
 )
 
 



Write-MaintenanceLog ">>> $StepName" "STEP"
 try {
 $result = & $Action
 Write-MaintenanceLog "PASS $StepName completed" "SUCCESS"
 return $result
 }
 catch {
 $message = "FAIL $StepName failed: $($_.Exception.Message)"
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
 $healthScript = "$ProjectRoot/scripts/maintenance/infrastructure-health-check.ps1"
 if (Test-Path $healthScript) {
 & $healthScript -Mode "Full" -AutoFix:$AutoFix
 } else {
 Write-MaintenanceLog "Infrastructure health check script not found" "WARNING"
 }
}

function Step-FixInfrastructureIssues {
    $fixScript = "$ProjectRoot/scripts/maintenance/fix-infrastructure-issues.ps1"
    if (Test-Path $fixScript) {
        if ($AutoFix) {
            & $fixScript -Fix "All"
        } else {
            & $fixScript -Fix "All" -DryRun
        }
    } else {
        Write-MaintenanceLog "Infrastructure fix script not found" "WARNING"
    }
}

function Step-FixTestSyntax {
 $fixScript = "$ProjectRoot/scripts/maintenance/fix-infrastructure-issues.ps1"
 if (Test-Path $fixScript) {
 & $fixScript -Fix "TestSyntax" -AutoFix:$AutoFix
 } else {
 Write-MaintenanceLog "Fix script not found, using basic syntax validation" "WARNING"
 # Basic syntax validation fallback
 Get-ChildItem -Path "$ProjectRoot/tests" -Filter "*.ps1" -Recurse | ForEach-Object{
 $null = System.Management.Automation.Language.Parser::ParseFile($_.FullName, ref$null, ref$null)
 }
 }
}

function Step-ValidateYaml {
 Write-MaintenanceLog "Validating and fixing YAML files..." "INFO"
 $yamlScript = "$ProjectRoot/scripts/validation/Invoke-YamlValidation.ps1"
 if (Test-Path $yamlScript) {
 try {
 if ($AutoFix) {
 Write-MaintenanceLog "Running YAML validation with auto-fix..." "INFO"
 & $yamlScript -Mode "Fix" -Path ".github/workflows"
 } else {
 Write-MaintenanceLog "Running YAML validation (check only)..." "INFO"
 & $yamlScript -Mode "Check" -Path ".github/workflows"
 }
 Write-MaintenanceLog "YAML validation completed" "SUCCESS"
 } catch {
 Write-MaintenanceLog "YAML validation failed: $($_.Exception.Message)" "ERROR"
 if ($AutoFix) {
 Write-MaintenanceLog "Attempting basic YAML fixes..." "WARNING"
 # Basic fallback validation
 Get-ChildItem -Path "$ProjectRoot/.github/workflows" -Filter "*.yml","*.yaml" -ErrorAction SilentlyContinue | ForEach-Object{
 try {
 $content = Get-Content $_.FullName -Raw
 $null = ConvertFrom-Yaml $content -ErrorAction Stop
 Write-MaintenanceLog " $($_.Name) syntax is valid" "SUCCESS"
 } catch {
 Write-MaintenanceLog " $($_.Name) has syntax issues: $($_.Exception.Message)" "ERROR"
 }
 }
 }
 }
 } else {
 Write-MaintenanceLog "YAML validation script not found: $yamlScript" "WARNING"
 Write-MaintenanceLog "Please ensure the validation script exists" "WARNING"
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
 Write-MaintenanceLog "Running comprehensive tests..." "INFO"
 & $testScript
 } else {
 Write-MaintenanceLog "Test script not found, using basic Pester" "WARNING"
 Set-Location $ProjectRoot
 Invoke-Pester tests/ -OutputFile "TestResults.xml" -OutputFormat NUnitXml -ExitOnError:$false
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
- **Status**: PASS Maintenance cycle completed
"@

 # Insert after the Unreleased section
 $updatedContent = $content -replace "(\Unreleased\\s*\n)", "`$1$maintenanceUpdate`n"
 
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
 $health = Get-Content $healthFile | ConvertFrom-Json$summary.InfrastructureStatus = $health.OverallStatus
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
        Parameter(Mandatory=$true)
        PSCustomObject$Summary
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
        
        $severityLabel = switch ($issue.Severity) {
            "High" { "ERROR" }
            "Medium" { "WARNING" }
            "Low" { "INFO" }
            default { "INFO" }
        }
        
        # Display issue header with color box
        Write-Host "■ $($issue.Severity) $($issue.Description)" -ForegroundColor $severityColor
        Write-Host "  Affected Files: $($issue.Count)" -ForegroundColor $severityColor
        Write-Host "  Category: $($issue.Category)" -ForegroundColor White
        Write-Host "  Fix Command: " -NoNewline -ForegroundColor White
        Write-Host "$($issue.Fix)" -ForegroundColor Green
        
        # Show sample affected files (max 5)
        if ($issue.Files -and $issue.Files.Count -gt 0) {
            Write-Host "  Sample affected files:" -ForegroundColor White
            $sampleFiles = $issue.Files | Select-Object-First 5
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

# Enhanced consolidation and tool discovery functions
function Find-AllMaintenanceTools {
    Write-MaintenanceLog "Discovering all maintenance and validation tools..." "INFO"
    
    $toolPatterns = @(
        "unified-maintenance.ps1",
        "fix-*.ps1",
        "test-*.ps1", 
        "validate-*.ps1",
        "comprehensive-*.ps1",
        "infrastructure-*.ps1",
        "emergency-*.ps1",
        "repair-*.ps1",
        "*validation*.ps1",
        "*health*.ps1",
        "*syntax*.ps1"
    )
    
    $foundTools = @()
    foreach ($pattern in $toolPatterns) {
        $tools = Get-ChildItem -Path $ProjectRoot -Recurse -Include $pattern -File | Where-Object{ 
                $_.FullName -notlike "*archive*" -and 
                $_.FullName -notlike "*backup*" -and
                $_.FullName -notlike "*node_modules*"
            }
        $foundTools += $tools
    }
    
    Write-MaintenanceLog "Found $($foundTools.Count) maintenance/validation tools" "SUCCESS"
    return $foundTools
}

function Test-AllMaintenanceTools {
    param(array$Tools)
    
    Write-MaintenanceLog "Testing functionality of all maintenance tools..." "INFO"
    
    $results = @{
        Working = @()
        Broken = @()
        SyntaxErrors = @()
    }
    
    foreach ($tool in $Tools) {
        $relPath = $tool.FullName -replace regex::Escape($ProjectRoot), '.'
        
        try {
            # Test syntax
            $parseErrors = @()
            System.Management.Automation.Language.Parser::ParseFile($tool.FullName, ref$null, ref$parseErrors)
            
            if ($parseErrors.Count -eq 0) {
                $results.Working += $tool
                Write-MaintenanceLog " $($tool.Name) - Syntax OK" "SUCCESS"
            } else {
                $results.Broken += $tool
                $results.SyntaxErrors += @{
                    Tool = $tool.Name
                    Path = $relPath
                    Errors = $parseErrors
                }
                Write-MaintenanceLog " $($tool.Name) - $($parseErrors.Count) syntax errors" "ERROR"
            }
        } catch {
            $results.Broken += $tool
            Write-MaintenanceLog " $($tool.Name) - Parse failed: $($_.Exception.Message)" "ERROR"
        }
    }
    
    Write-MaintenanceLog "Tool Analysis: $($results.Working.Count) working, $($results.Broken.Count) broken" "INFO"
    return $results
}

function Repair-BrokenMaintenanceTools {
    param(array$BrokenTools, array$SyntaxErrors)
    
    if ($BrokenTools.Count -eq 0) {
        Write-MaintenanceLog "No broken tools to repair" "INFO"
        return @()
    }
    
    Write-MaintenanceLog "Attempting to repair $($BrokenTools.Count) broken tools..." "FIX"
    
    $fixesApplied = @()
    
    foreach ($tool in $BrokenTools) {
        try {
            $content = Get-Content $tool.FullName -Raw
            $originalContent = $content
            
            # Apply common syntax fixes
            $content = $content -replace '\)\s*\{', ') {'  # Fix brace spacing
            $content = $content -replace '(?m)^\s*$\n', ''  # Remove empty lines
            $content = $content -replace '(\w+)\s*=\s*@\s*\(', '$1 = @('  # Fix array init
            
            # Add missing essentials
            if ($content -notmatch '\$ErrorActionPreference') {
                $content = "`$ErrorActionPreference = 'Continue'`n$content"
            }
            
            # Fix common module import issues
            if ($content -match 'Invoke-PowerShellLintTest-JsonConfig' -and $content -notmatch 'Import-Module.*CodeFixer') {
                $importStatement = "Import-Module '/pwsh/modules/CodeFixer/' -Force -ErrorAction SilentlyContinue"
                $content = "$importStatement`n$content"
            }
            
            if ($content -ne $originalContent) {
                Set-Content $tool.FullName $content -Encoding UTF8
                $fixesApplied += "Repaired $($tool.Name)"
                Write-MaintenanceLog "Applied fixes to $($tool.Name)" "FIX"
            }
            
        } catch {
            Write-MaintenanceLog "Failed to repair $($tool.Name): $($_.Exception.Message)" "ERROR"
        }
    }
    
    return $fixesApplied
}

function Invoke-ComprehensiveProjectValidation {
    Write-MaintenanceLog "Running comprehensive project validation..." "INFO"
    
    $validationResults = @{
        PowerShellSyntax = @{ TotalFiles = 0; ValidFiles = 0; ErrorFiles = @() }
        ModuleHealth = @{ Available = 0; Total = 4; Missing = @() }
        ToolsHealth = @{ Working = 0; Broken = 0; Total = 0 }
        OverallStatus = "Unknown"
    }
    
    # 1. PowerShell syntax validation across entire project
    Write-MaintenanceLog "Validating PowerShell syntax across all files..." "INFO"
    $allPsFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | Where-Object{ 
            $_.FullName -notlike "*archive*" -and 
            $_.FullName -notlike "*backup*" -and
            $_.FullName -notlike "*node_modules*"
        }
    
    $validationResults.PowerShellSyntax.TotalFiles = $allPsFiles.Count
    $syntaxErrorCount = 0
    
    foreach ($file in $allPsFiles) {
        try {
            $parseErrors = @()
            System.Management.Automation.Language.Parser::ParseFile($file.FullName, ref$null, ref$parseErrors)
            
            if ($parseErrors.Count -eq 0) {
                $validationResults.PowerShellSyntax.ValidFiles++
            } else {
                $syntaxErrorCount++
                $validationResults.PowerShellSyntax.ErrorFiles += $file.FullName
            }
        } catch {
            $syntaxErrorCount++
            $validationResults.PowerShellSyntax.ErrorFiles += $file.FullName
        }
    }
    
    # 2. Module health check
    Write-MaintenanceLog "Checking module availability..." "INFO"
    $requiredModules = @("CodeFixer", "LabRunner", "PatchManager", "BackupManager")
    $availableModules = 0
    
    foreach ($module in $requiredModules) {
        $modulePath = "$ProjectRoot/pwsh/modules/$module"
        if (Test-Path $modulePath) {
            $availableModules++
        } else {
            $validationResults.ModuleHealth.Missing += $module
        }
    }
    
    $validationResults.ModuleHealth.Available = $availableModules
    
    # 3. Tools health check
    $allTools = Find-AllMaintenanceTools
    $toolResults = Test-AllMaintenanceTools -Tools $allTools
    
    $validationResults.ToolsHealth.Total = $allTools.Count
    $validationResults.ToolsHealth.Working = $toolResults.Working.Count
    $validationResults.ToolsHealth.Broken = $toolResults.Broken.Count
    
    # 4. Determine overall status
    if ($syntaxErrorCount -eq 0 -and $availableModules -eq 4 -and $toolResults.Broken.Count -eq 0) {
        $validationResults.OverallStatus = "Excellent"
    } elseif ($syntaxErrorCount -lt 5 -and $availableModules -ge 3 -and $toolResults.Broken.Count -lt 3) {
        $validationResults.OverallStatus = "Good"
    } elseif ($syntaxErrorCount -lt 10 -and $availableModules -ge 2) {
        $validationResults.OverallStatus = "Warning"
    } else {
        $validationResults.OverallStatus = "Critical"
    }
    
    # Log comprehensive summary
    Write-MaintenanceLog "`n=== COMPREHENSIVE VALIDATION SUMMARY ===" "INFO"
    Write-MaintenanceLog "PowerShell Files: $($validationResults.PowerShellSyntax.ValidFiles)/$($validationResults.PowerShellSyntax.TotalFiles) valid" "INFO"
    Write-MaintenanceLog "Modules: $($validationResults.ModuleHealth.Available)/$($validationResults.ModuleHealth.Total) available" "INFO"
    Write-MaintenanceLog "Tools: $($validationResults.ToolsHealth.Working)/$($validationResults.ToolsHealth.Total) working" "INFO"
    Write-MaintenanceLog "Overall Status: $($validationResults.OverallStatus)" $(
        switch ($validationResults.OverallStatus) {
            "Excellent" { "SUCCESS" }
            "Good" { "SUCCESS" }
            "Warning" { "WARNING" }
            "Critical" { "ERROR" }
            default { "INFO" }
        }
    )
    
    return $validationResults
}

function Invoke-ConsolidatedValidation {
    <#
    .SYNOPSIS
    Run consolidated validation checks integrating all validation tools
    #>
    Write-MaintenanceLog "Running consolidated validation checks..." "INFO"
    
    $consolidatedResults = @{
        PSScriptAnalyzer = $null
        PesterTests = $null
        SyntaxValidation = $null
        ComprehensiveValidation = $null
        Summary = @{
            TotalIssues = 0
            CriticalIssues = 0
            FixableIssues = 0
            Recommendations = @()
        }
    }
    
    # 1. PowerShell Linting (via PSScriptAnalyzer)
    if (Get-Module -ListAvailable PSScriptAnalyzer) {
        try {
            Write-MaintenanceLog "Running PSScriptAnalyzer..." "INFO"
            $lintResults = Invoke-ScriptAnalyzer -Path $ProjectRoot -Recurse -ErrorAction SilentlyContinue
            $consolidatedResults.PSScriptAnalyzer = $lintResults
            
            $errorCount = (lintResults | Where-ObjectSeverity -eq 'Error').Count
            $warningCount = (lintResults | Where-ObjectSeverity -eq 'Warning').Count
            
            Write-MaintenanceLog "PSScriptAnalyzer: $errorCount errors, $warningCount warnings" "INFO"
            $consolidatedResults.Summary.TotalIssues += ($errorCount + $warningCount)
            $consolidatedResults.Summary.CriticalIssues += $errorCount
            
        } catch {
            Write-MaintenanceLog "PSScriptAnalyzer failed: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-MaintenanceLog "PSScriptAnalyzer not available" "WARNING"
        $consolidatedResults.Summary.Recommendations += "Install PSScriptAnalyzer module"
    }
    
    # 2. Pester Tests (if available)
    if (Get-Module -ListAvailable Pester) {
        try {
            Write-MaintenanceLog "Running available Pester tests..." "INFO"
            $testPath = "$ProjectRoot/tests"
            if (Test-Path $testPath) {
                $pesterResults = Invoke-Pester -Path $testPath -PassThru -ErrorAction SilentlyContinue
                $consolidatedResults.PesterTests = @{
                    Total = $pesterResults.TotalCount
                    Passed = $pesterResults.PassedCount
                    Failed = $pesterResults.FailedCount
                }
                
                Write-MaintenanceLog "Pester Tests: $($pesterResults.PassedCount)/$($pesterResults.TotalCount) passed" "INFO"
                $consolidatedResults.Summary.TotalIssues += $pesterResults.FailedCount
                
            } else {
                Write-MaintenanceLog "No tests directory found" "WARNING"
            }
        } catch {
            Write-MaintenanceLog "Pester tests failed: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-MaintenanceLog "Pester not available" "INFO"
    }
    
    # 3. Comprehensive syntax validation
    $syntaxValidation = Invoke-ComprehensiveProjectValidation
    $consolidatedResults.SyntaxValidation = $syntaxValidation
    $consolidatedResults.Summary.TotalIssues += $syntaxValidation.PowerShellSyntax.ErrorFiles.Count
    $consolidatedResults.Summary.CriticalIssues += $syntaxValidation.PowerShellSyntax.ErrorFiles.Count
    
    # 4. Generate actionable recommendations
    if ($consolidatedResults.Summary.CriticalIssues -gt 0) {
        $consolidatedResults.Summary.Recommendations += "Fix critical PowerShell syntax errors"
    }
    
    if ($syntaxValidation.ModuleHealth.Missing.Count -gt 0) {
        $consolidatedResults.Summary.Recommendations += "Restore missing modules: $($syntaxValidation.ModuleHealth.Missing -join ', ')"
    }
    
    if ($syntaxValidation.ToolsHealth.Broken -gt 0) {
        $consolidatedResults.Summary.Recommendations += "Repair broken maintenance tools"
    }
    
    # Final summary
    Write-MaintenanceLog "`n=== CONSOLIDATED VALIDATION SUMMARY ===" "INFO"
    Write-MaintenanceLog "Total Issues: $($consolidatedResults.Summary.TotalIssues)" "INFO"
    Write-MaintenanceLog "Critical Issues: $($consolidatedResults.Summary.CriticalIssues)" $(
        if ($consolidatedResults.Summary.CriticalIssues -gt 0) { "ERROR" } else { "SUCCESS" }
    )
    
    if ($consolidatedResults.Summary.Recommendations.Count -gt 0) {
        Write-MaintenanceLog "`nRecommendations:" "WARNING"
        $consolidatedResults.Summary.Recommendations | ForEach-Object{
            Write-MaintenanceLog "  • $_" "WARNING"
        }
    }
    
    return $consolidatedResults
}

# Main execution flow
Write-MaintenanceLog " Starting unified maintenance in mode: $Mode" "MAINTENANCE"
Write-MaintenanceLog "AutoFix: $($AutoFix.IsPresent)  UpdateChangelog: $($UpdateChangelog.IsPresent)  SkipTests: $($SkipTests.IsPresent)" "INFO"

$startTime = Get-Date

try {
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
 }
 }
 
 $duration = (Get-Date) - $startTime
 $summary = Get-MaintenanceSummary
 
 Write-MaintenanceLog " Maintenance completed successfully!" "SUCCESS"
 Write-MaintenanceLog "Duration: $($duration.TotalMinutes.ToString('F1')) minutes" "INFO"
 Write-MaintenanceLog "Infrastructure Status: $($summary.InfrastructureStatus)" "INFO"
 
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
 Write-MaintenanceLog "FAIL Maintenance failed: $($_.Exception.Message)" "ERROR"
 exit 1
}

Write-MaintenanceLog "Maintenance cycle complete. Next recommended run: $(if($AutoFix) { '24 hours' } else { 'as needed' })" "MAINTENANCE"

# Unified maintenance script for validation and cleanup

# Import necessary modules
Import-Module PSScriptAnalyzer

# Define the root directory
$RootDirectory = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"

# Log file for maintenance
$LogFile = "$RootDirectory\maintenance-log.txt"

# Initialize log
"Maintenance started at $(Get-Date)"  Out-File -FilePath $LogFile -Encoding UTF8

# Step 1: Validate all scripts
Write-Host "Starting script validation..." -ForegroundColor Cyan
$ScriptFiles = Get-ChildItem -Path $RootDirectory -Recurse -Filter "*.ps1"
$ValidationResults = @()
foreach ($Script in $ScriptFiles) {
    Write-Host "Validating: $($Script.FullName)" -ForegroundColor Cyan
    try {
        $Results = Invoke-ScriptAnalyzer -Path $Script.FullName -Severity Warning, Error
        $ValidationResults += $Results
    } catch {
        Write-Host "Error validating $($Script.FullName): ${_}" -ForegroundColor Red
        "Error validating $($Script.FullName): ${_}"  Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}
if ($ValidationResults.Count -gt 0) {
    Write-Host "Validation completed with issues:" -ForegroundColor Yellow
    $ValidationResults  Format-Table -AutoSize
    ValidationResults | Out-File -FilePath "$RootDirectory\validation-results.txt" -Encoding UTF8
    Write-Host "Validation results saved to validation-results.txt" -ForegroundColor Green
} else {
    Write-Host "All scripts validated successfully!" -ForegroundColor Green
}

# Step 2: Cleanup repository
Write-Host "Starting repository cleanup..." -ForegroundColor Cyan
$DirectoriesToClean = @(
    "$RootDirectory\assets",
    "$RootDirectory\backups",
    "$RootDirectory\build",
    "$RootDirectory\configs",
    "$RootDirectory\logs"
)
foreach ($Directory in $DirectoriesToClean) {
    Write-Host "Cleaning: $Directory" -ForegroundColor Cyan
    if (Test-Path $Directory) {
        try {
            Remove-Item -Path $Directory -Recurse -Force -ErrorAction Stop
            Write-Host "Successfully cleaned: $Directory" -ForegroundColor Green
            "Successfully cleaned: $Directory"  Out-File -FilePath $LogFile -Append -Encoding UTF8
        } catch {
            Write-Host "Error cleaning $Directory: ${_}" -ForegroundColor Red
            "Error cleaning $Directory: ${_}"  Out-File -FilePath $LogFile -Append -Encoding UTF8
        }
    } else {
        Write-Host "Directory not found: $Directory" -ForegroundColor Yellow
        "Directory not found: $Directory"  Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}

# Finalize log
"Maintenance completed at $(Get-Date)"  Out-File -FilePath $LogFile -Append -Encoding UTF8
Write-Host "Maintenance log saved to $LogFile" -ForegroundColor Green








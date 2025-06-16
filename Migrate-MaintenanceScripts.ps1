#Requires -Version 7.0

<#
.SYNOPSIS
    Migrates scattered maintenance scripts to the new UnifiedMaintenance module

.DESCRIPTION
    This script consolidates the 16+ scattered maintenance scripts into the new
    UnifiedMaintenance module, archives obsolete scripts, and sets up proper
    integration with PatchManager workflows.

.PARAMETER Execute
    Actually perform the migration (default is dry-run)

.PARAMETER ArchiveObsolete
    Archive obsolete scripts instead of deleting them
#>

param(
    [switch]$Execute,
    [switch]$ArchiveObsolete = $true
)

$ProjectRoot = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
$MaintenanceDir = "$ProjectRoot\scripts\maintenance"
$ArchiveDir = "$ProjectRoot\archive\maintenance-migration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

function Write-MigrationLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "ARCHIVE" { "Magenta" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

Write-MigrationLog "=== Maintenance Scripts Migration to UnifiedMaintenance Module ===" "INFO"

if (-not $Execute) {
    Write-MigrationLog "DRY RUN MODE - Use -Execute to perform actual migration" "WARNING"
}

# Step 1: Analyze existing maintenance scripts
Write-MigrationLog "Analyzing existing maintenance scripts..." "INFO"

$maintenanceScripts = Get-ChildItem -Path $MaintenanceDir -Filter "*.ps1" | Where-Object {
    $_.Name -ne "unified-maintenance.ps1"  # Keep the original for reference
}

$scriptAnalysis = @{
    "ObsoleteScripts" = @(
        # Scripts that are fully replaced by UnifiedMaintenance module
        "quick-issue-check.ps1",
        "simple-runtime-fix.ps1", 
        "track-recurring-issues.ps1",
        "infrastructure-health-check.ps1"
    )
    "UtilityScripts" = @(
        # Scripts that provide specific utility functions
        "Fix-MissingPipeSyntax.ps1",
        "emergency-yaml-cleanup.ps1"
    )
    "OrganizationScripts" = @(
        # Scripts that were used for one-time organization
        "cleanup-duplicate-directories.ps1",
        "cleanup-root-scripts.ps1", 
        "consolidate-lab-utils.ps1",
        "organize-project.ps1",
        "update-imports.ps1"
    )
    "WorkflowScripts" = @(
        # Scripts for workflow management
        "clean-workflows.ps1"
    )
}

Write-MigrationLog "Found $($maintenanceScripts.Count) maintenance scripts to analyze" "INFO"

foreach ($category in $scriptAnalysis.Keys) {
    Write-MigrationLog "  $category`: $($scriptAnalysis[$category].Count) scripts" "INFO"
}

# Step 2: Create archive directory
if ($ArchiveObsolete -and $Execute) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    Write-MigrationLog "Created archive directory: $ArchiveDir" "SUCCESS"
}

# Step 3: Process each category of scripts
foreach ($category in $scriptAnalysis.Keys) {
    Write-MigrationLog "Processing $category..." "INFO"
    
    foreach ($scriptName in $scriptAnalysis[$category]) {
        $scriptPath = "$MaintenanceDir\$scriptName"
        
        if (Test-Path $scriptPath) {
            switch ($category) {
                "ObsoleteScripts" {
                    Write-MigrationLog "  OBSOLETE: $scriptName -> Functionality moved to UnifiedMaintenance module" "ARCHIVE"
                    if ($Execute -and $ArchiveObsolete) {
                        Move-Item -Path $scriptPath -Destination "$ArchiveDir\$scriptName"
                        Write-MigrationLog "    Archived: $scriptName" "SUCCESS"
                    }
                }
                "UtilityScripts" {
                    Write-MigrationLog "  UTILITY: $scriptName -> Keep for specific use cases" "INFO"
                    # Keep these scripts as they provide specific utility functions
                }
                "OrganizationScripts" {
                    Write-MigrationLog "  ORGANIZATION: $scriptName -> Archive (one-time use)" "ARCHIVE"
                    if ($Execute -and $ArchiveObsolete) {
                        Move-Item -Path $scriptPath -Destination "$ArchiveDir\$scriptName"
                        Write-MigrationLog "    Archived: $scriptName" "SUCCESS"
                    }
                }
                "WorkflowScripts" {
                    Write-MigrationLog "  WORKFLOW: $scriptName -> Keep for workflow management" "INFO"
                    # Keep workflow management scripts
                }
            }
        }
        else {
            Write-MigrationLog "  NOT FOUND: $scriptName" "WARNING"
        }
    }
}

# Step 4: Create migration summary
$migrationSummary = @"
# Maintenance Scripts Migration Summary

## Migration Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## New Architecture

### UnifiedMaintenance Module
- **Location**: ``pwsh/modules/UnifiedMaintenance/``
- **Functions**: 
  - ``Invoke-UnifiedMaintenance`` - Main orchestrator
  - ``Invoke-AutomatedTestWorkflow`` - Comprehensive testing
  - ``Invoke-InfrastructureHealth`` - Health monitoring
  - ``Invoke-RecurringIssueTracking`` - Issue analysis
  - ``Start-ContinuousMonitoring`` - Continuous monitoring

### Integration Points
- **PatchManager**: All changes go through ``Invoke-GitControlledPatch``
- **VS Code Tasks**: Updated to use module functions
- **Automated Testing**: Pester and pytest integration
- **Health Monitoring**: Comprehensive infrastructure checks

## Replaced Scripts

### Obsolete (Archived)
$(foreach ($script in $scriptAnalysis.ObsoleteScripts) { "- $script - Functionality moved to UnifiedMaintenance module" })

### Organization (Archived) 
$(foreach ($script in $scriptAnalysis.OrganizationScripts) { "- $script - One-time organization complete" })

### Retained Scripts
$(foreach ($script in $scriptAnalysis.UtilityScripts) { "- $script - Specific utility functions" })
$(foreach ($script in $scriptAnalysis.WorkflowScripts) { "- $script - Workflow management" })

## Usage Examples

### Quick Health Check
``````powershell
Import-Module './pwsh/modules/UnifiedMaintenance' -Force
Invoke-UnifiedMaintenance -Mode Quick
``````

### Full Testing Workflow
``````powershell
Import-Module './pwsh/modules/UnifiedMaintenance' -Force
Invoke-UnifiedMaintenance -Mode TestOnly -UsePatchManager
``````

### Complete Maintenance with PatchManager
``````powershell
Import-Module './pwsh/modules/UnifiedMaintenance' -Force
Invoke-UnifiedMaintenance -Mode All -AutoFix -UpdateChangelog -UsePatchManager
``````

### Direct Testing Function
``````powershell
Import-Module './pwsh/modules/UnifiedMaintenance' -Force
Invoke-AutomatedTestWorkflow -TestCategory All -GenerateCoverage
``````

## Benefits

1. **Consolidated**: All maintenance in one module
2. **PatchManager Integration**: Proper change control 
3. **Automated Testing**: Pester and pytest workflows
4. **VS Code Integration**: Updated tasks and snippets
5. **Reduced Complexity**: From 16+ scripts to 1 module
6. **Better Documentation**: Clear function definitions
7. **Standardized Logging**: Consistent output format

## Next Steps

1. Test the new module functions
2. Update any remaining references to old scripts
3. Train team on new unified interface
4. Monitor and refine based on usage

---
Generated by: Maintenance Scripts Migration Tool
"@

$summaryPath = "$ProjectRoot\MAINTENANCE-MIGRATION-SUMMARY.md"
if ($Execute) {
    Set-Content -Path $summaryPath -Value $migrationSummary
    Write-MigrationLog "Migration summary created: $summaryPath" "SUCCESS"
}

# Step 5: Test the new module
Write-MigrationLog "Testing UnifiedMaintenance module..." "INFO"

try {
    Import-Module "$ProjectRoot\pwsh\modules\UnifiedMaintenance" -Force
    Write-MigrationLog "  Module import: SUCCESS" "SUCCESS"
    
    # Test that functions are available
    $functions = Get-Command -Module UnifiedMaintenance
    Write-MigrationLog "  Available functions: $($functions.Count)" "INFO"
    foreach ($func in $functions) {
        Write-MigrationLog "    - $($func.Name)" "INFO"
    }
    
    if ($Execute) {
        # Run a quick test
        Write-MigrationLog "Running quick test..." "INFO"
        $testResult = Invoke-InfrastructureHealth -OutputPath "MigrationTest"
        Write-MigrationLog "  Test health check: $($testResult.OverallHealth)" "SUCCESS"
    }
}
catch {
    Write-MigrationLog "  Module test failed: $_" "ERROR"
}

# Final summary
Write-MigrationLog "" "INFO"
Write-MigrationLog "=== Migration Summary ===" "INFO"
Write-MigrationLog "Total scripts analyzed: $($maintenanceScripts.Count)" "INFO"
Write-MigrationLog "Scripts to archive: $($scriptAnalysis.ObsoleteScripts.Count + $scriptAnalysis.OrganizationScripts.Count)" "INFO"
Write-MigrationLog "Scripts to retain: $($scriptAnalysis.UtilityScripts.Count + $scriptAnalysis.WorkflowScripts.Count)" "INFO"

if ($Execute) {
    Write-MigrationLog "Migration COMPLETED successfully!" "SUCCESS"
    Write-MigrationLog "New UnifiedMaintenance module is ready to use" "SUCCESS"
    Write-MigrationLog "Run: Import-Module './pwsh/modules/UnifiedMaintenance' -Force" "INFO"
} else {
    Write-MigrationLog "DRY RUN completed. Use -Execute to perform migration" "WARNING"
}

Write-MigrationLog "See: $summaryPath for detailed migration information" "INFO"

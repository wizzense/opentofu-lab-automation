#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/utilities/update-project-manifest.ps1

<#
.SYNOPSIS
Automatically updates the PROJECT-MANIFEST.json with current project state

.DESCRIPTION
This script scans the project structure and updates the manifest file with:
- Current module versions and dependencies
- Function inventories from modules
- Performance metrics from recent test runs
- File counts and project statistics
- Dependency mappings

.PARAMETER Force
Force update even if manifest is recent

.EXAMPLE
./scripts/utilities/update-project-manifest.ps1 -Force
#>

CmdletBinding()
param(
    switch$Force
)

$ErrorActionPreference = "Stop"
# Detect the correct project root based on the current environment
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $ProjectRoot = "/workspaces/opentofu-lab-automation"
}
$ManifestPath = "$ProjectRoot/PROJECT-MANIFEST.json"

function Write-ManifestLog {
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

function Get-ModuleInfo {
    param(string$ModulePath)
    
    $info = @{
        functions = @()
        version = "Unknown"
        dependencies = @()
    }
    
    # Get module manifest info
    $manifestFile = Get-ChildItem "$ModulePath/*.psd1" -ErrorAction SilentlyContinue | Select-Object-First 1
    if ($manifestFile) {
        try {
            $manifestData = Import-PowerShellDataFile $manifestFile.FullName
            $info.version = $manifestData.ModuleVersion
            $info.dependencies = $manifestData.RequiredModules
        } catch {
            Write-ManifestLog "Could not read manifest for $ModulePath" "WARNING"
        }
    }
    
    # Get public functions
    $publicPath = "$ModulePath/Public"
    if (Test-Path $publicPath) {
        $functionFiles = Get-ChildItem "$publicPath/*.ps1" -ErrorAction SilentlyContinue
        $info.functions = functionFiles | ForEach-Object{
            $_.BaseName
        }
    }
    
    return $info
}

function Get-ProjectMetrics {
    $metrics = @{
        powerShellFiles = 0
        testFiles = 0
        activeModules = 0
        maintenanceScripts = 0
        validationScripts = 0
    }
    
    # Count PowerShell files
    $psFiles = Get-ChildItem "$ProjectRoot" -Recurse -Include "*.ps1", "*.psm1", "*.psd1" -File | Where-Object{ $_.FullName -notlike "*backup*" -and $_.FullName -notlike "*archive*" }
    $metrics.powerShellFiles = $psFiles.Count
    
    # Count test files
    $testFiles = Get-ChildItem "$ProjectRoot/tests" -Recurse -Include "*.ps1" -File -ErrorAction SilentlyContinue
    $metrics.testFiles = $testFiles.Count
    
    # Count modules
    $moduleDirectories = Get-ChildItem "$ProjectRoot/pwsh/modules" -Directory -ErrorAction SilentlyContinue
    $metrics.activeModules = $moduleDirectories.Count
    
    # Count maintenance scripts
    $maintenanceScripts = Get-ChildItem "$ProjectRoot/scripts/maintenance" -Include "*.ps1" -File -ErrorAction SilentlyContinue
    $metrics.maintenanceScripts = $maintenanceScripts.Count
    
    # Count validation scripts
    $validationScripts = Get-ChildItem "$ProjectRoot/scripts/validation" -Include "*.ps1" -File -ErrorAction SilentlyContinue
    $metrics.validationScripts = $validationScripts.Count
    
    return $metrics
}

function Get-PerformanceMetrics {
    $performance = @{
        healthCheckTime = "< 1 minute"
        fullMaintenanceTime = "2-5 minutes"
        batchProcessingOptimization = "Dynamic CPU scaling"
    }
    
    # Try to get actual performance data from recent runs
    $healthFile = "$ProjectRoot/docs/reports/project-status/current-health.json"
    if (Test-Path $healthFile) {
        try {
            $healthData = Get-Content $healthFile | ConvertFrom-Jsonif ($healthData.Timestamp) {
                $healthTime = DateTime::Parse($healthData.Timestamp)
                if ((Get-Date) - $healthTime -lt TimeSpan::FromHours(24)) {
                    $performance.lastHealthCheck = $healthData.Timestamp
                }
            }
        } catch {
            # Ignore parsing errors
        }
    }
    
    return $performance
}

function Update-ProjectManifest {
    Write-ManifestLog "Updating project manifest..." "INFO"
    
    # Load existing manifest or create new one
    $manifest = @{}
    if (Test-Path $ManifestPath) {
        try {
            $manifest = Get-Content $ManifestPath | ConvertFrom-Json-AsHashtable
        } catch {
            Write-ManifestLog "Could not parse existing manifest, creating new" "WARNING"
        }
    }
    
    # Update timestamp
    $manifest.project = @{
        name = "OpenTofu Lab Automation"
        version = "1.0.0"
        lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        description = "Comprehensive automation framework for OpenTofu lab environments with unified maintenance and validation systems"
    }
    
    # Update core modules
    if (-not $manifest.core) { $manifest.core = @{} }
    if (-not $manifest.core.modules) { $manifest.core.modules = @{} }
    
    # CodeFixer module
    $codeFixerPath = "$ProjectRoot/pwsh/modules/CodeFixer"
    if (Test-Path $codeFixerPath) {
        $codeFixerInfo = Get-ModuleInfo $codeFixerPath
        $manifest.core.modules.CodeFixer = @{
            path = "/pwsh/modules/CodeFixer/"
            type = "PowerShell Module"
            purpose = "Automated code analysis, fixing, and validation"
            entryPoint = "CodeFixer.psd1"
            version = $codeFixerInfo.version
            dependencies = @("PSScriptAnalyzer")
            keyFunctions = $codeFixerInfo.functions
            lastUpdated = (Get-Item $codeFixerPath).LastWriteTime.ToString("yyyy-MM-dd")
        }
    }
    
    # LabRunner module
    $labRunnerPath = "$ProjectRoot/pwsh/modules/LabRunner"
    if (Test-Path $labRunnerPath) {
        $labRunnerInfo = Get-ModuleInfo $labRunnerPath
        $manifest.core.modules.LabRunner = @{
            path = "/pwsh/modules/LabRunner/"
            type = "PowerShell Module"
            purpose = "Lab environment automation and management"
            entryPoint = "LabRunner.psd1"
            version = $labRunnerInfo.version
            dependencies = @()
            keyFunctions = $labRunnerInfo.functions
            lastUpdated = (Get-Item $labRunnerPath).LastWriteTime.ToString("yyyy-MM-dd")
        }
    }
    
    # Update metrics
    if (-not $manifest.metrics) { $manifest.metrics = @{} }
    $manifest.metrics.codebase = Get-ProjectMetrics
    $manifest.metrics.performance = Get-PerformanceMetrics
    $manifest.metrics.lastCalculated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Update maintenance system info
    if (-not $manifest.core.maintenanceSystem) { 
        $manifest.core.maintenanceSystem = @{
            unifiedMaintenance = @{
                path = "/scripts/maintenance/unified-maintenance.ps1"
                purpose = "Single entry point for all maintenance operations"
                modes = @("Quick", "Full", "Test", "Track", "Report", "All")
                lastUpdated = if (Test-Path "$ProjectRoot/scripts/maintenance/unified-maintenance.ps1") {
                    (Get-Item "$ProjectRoot/scripts/maintenance/unified-maintenance.ps1").LastWriteTime.ToString("yyyy-MM-dd")
                } else { "Unknown" }
            }
            healthCheck = @{
                path = "/scripts/maintenance/infrastructure-health-check.ps1"
                purpose = "Real-time infrastructure analysis without test dependency"
                modes = @("Quick", "Full", "Report", "All")
                lastUpdated = if (Test-Path "$ProjectRoot/scripts/maintenance/infrastructure-health-check.ps1") {
                    (Get-Item "$ProjectRoot/scripts/maintenance/infrastructure-health-check.ps1").LastWriteTime.ToString("yyyy-MM-dd")
                } else { "Unknown" }
            }
        }
    }
    
    # Save updated manifest
    manifest | ConvertTo-Json-Depth 10  Set-Content $ManifestPath
    Write-ManifestLog "Updated manifest at $ManifestPath" "SUCCESS"
    
    # Update AGENTS.md reference if needed
    $agentsPath = "$ProjectRoot/AGENTS.md"
    if (Test-Path $agentsPath) {
        $agentsContent = Get-Content $agentsPath -Raw
        if ($agentsContent -notmatch "last updated.*$(Get-Date -Format 'yyyy-MM-dd')") {
            Write-ManifestLog "Consider updating AGENTS.md with new manifest information" "INFO"
        }
    }
}

# Main execution
Write-ManifestLog "Starting project manifest update..." "INFO"

# Check if update is needed
if (-not $Force -and (Test-Path $ManifestPath)) {
    $lastModified = (Get-Item $ManifestPath).LastWriteTime
    if ((Get-Date) - $lastModified -lt TimeSpan::FromHours(1)) {
        Write-ManifestLog "Manifest is recent (updated within 1 hour), use -Force to update anyway" "INFO"
        exit 0
    }
}

try {
    Update-ProjectManifest
    Write-ManifestLog "Project manifest update completed successfully" "SUCCESS"
} catch {
    Write-ManifestLog "Failed to update manifest: $($_.Exception.Message)" "ERROR"
    exit 1
}



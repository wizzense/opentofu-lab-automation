# Invoke-UnifiedHealthCheck.ps1
# Unified entry point for all health checks and maintenance tasks

CmdletBinding()
param(
    Parameter()
    ValidateSet("Quick", "Full", "Infrastructure", "Workflow", "All")
    string$Mode = "Quick",
    
    Parameter()
    switch$AutoFix,
    
    Parameter()
    ValidateSet("Markdown", "JSON", "Host")
    string$OutputFormat = "Markdown",
    
    Parameter()
    string$OutputPath = "./reports/unified-health"
)

# Ensure modules are loaded
$ErrorActionPreference = 'Stop'

if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module "/$ProjectRoot\pwsh\modules\CodeFixer" -Force -ErrorAction Stop
    Import-Module "/$ProjectRoot\pwsh\modules\LabRunner" -Force -ErrorAction Stop
} else {
    $ProjectRoot = "/workspaces/opentofu-lab-automation"
    Import-Module "/pwsh/modules/CodeFixer" -Force -ErrorAction Stop
    Import-Module "/pwsh/modules/LabRunner" -Force -ErrorAction Stop
}

# Initialize report structure
$unifiedReport = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Mode = $Mode
    AutoFix = $AutoFix.IsPresent
    Summary = @{
        InfrastructureHealth = $null
        WorkflowHealth = $null
        ValidationResults = @()
        AutoFixResults = @()
    }
}

function Write-HealthReport {
    param($Report, $OutputPath)
    
    $reportContent = @"
# Unified Health Check Report
Generated: $($Report.GeneratedAt)
Mode: $($Report.Mode)
Auto-Fix: $($Report.AutoFix)

## Infrastructure Health
$($Report.Summary.InfrastructureHealth  ConvertTo-Json -Depth 10)

## Workflow Health
$($Report.Summary.WorkflowHealth  ConvertTo-Json -Depth 10)

## Validation Results
$($Report.Summary.ValidationResults  ConvertTo-Json -Depth 10)

## Auto-Fix Results
$($Report.Summary.AutoFixResults  ConvertTo-Json -Depth 10)
"@

    # Ensure output directory exists
    New-Item -ItemType Directory -Path $OutputPath -Force  Out-Null
    
    # Write report
    $reportFile = Join-Path $OutputPath "unified-health-report.md"
    Set-Content -Path $reportFile -Value $reportContent -Force
    
    Write-Host "Report generated at: $reportFile" -ForegroundColor Green
}

Write-Host "Starting unified health check in $Mode mode..." -ForegroundColor Cyan

try {
    # Run infrastructure health check
    if ($Mode -in "Infrastructure", "Full", "All") {
        Write-Host "Running infrastructure health check..." -ForegroundColor Yellow
        $infraParams = @{
            OutputFormat = $OutputFormat
            AutoFix = $AutoFix
        }
        $unifiedReport.Summary.InfrastructureHealth = & "$PSScriptRoot\Analyze-InfrastructureHealth.ps1" @infraParams
    }

    # Run workflow health check
    if ($Mode -in "Workflow", "Full", "All") {
        Write-Host "Running workflow health check..." -ForegroundColor Yellow
        $workflowParams = @{
            OutputFormat = $OutputFormat
            AutoFix = $AutoFix
        }
        $unifiedReport.Summary.WorkflowHealth = & "$PSScriptRoot\Analyze-WorkflowHealth.ps1" @workflowParams
    }

    # Run quick validation
    if ($Mode -eq "Quick") {
        Write-Host "Running quick validation..." -ForegroundColor Yellow
        $quickResults = & "$PSScriptRoot\unified-maintenance.ps1" -Mode "Quick"
        $unifiedReport.Summary.ValidationResults += @{
            Type = "Quick"
            Results = $quickResults
        }
    }

    # Generate report
    Write-HealthReport -Report $unifiedReport -OutputPath $OutputPath

    # Update project manifest
    Write-Host "Updating project manifest..." -ForegroundColor Yellow
    & "$ProjectRoot\scripts\utilities\update-project-manifest.ps1" -LastHealthCheck (Get-Date) -HealthStatus ($unifiedReport.Summary.ValidationResults.Count -eq 0)

} catch {
    Write-Error "Error during unified health check: $_"
    throw
}



# Invoke-UnifiedHealthCheck.ps1
# Unified entry point for all health checks and maintenance tasks

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Quick", "Full", "Infrastructure", "Workflow", "All")]
    [string]$Mode = "Quick",
    
    [Parameter()]
    [switch]$AutoFix,
    
    [Parameter()]
    [ValidateSet("Markdown", "JSON", "Host")]
    [string]$OutputFormat = "Markdown",
    
    [Parameter()]
    [string]$OutputPath = "./reports/unified-health"
)

# Ensure modules are loaded
$ErrorActionPreference = 'Stop'

if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = "C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
    if (-not (Test-Path "$ProjectRoot\pwsh\modules\CodeFixer")) {
        Write-Error "CodeFixer module path does not exist: $ProjectRoot\pwsh\modules\CodeFixer"
        throw
    }
    if (-not (Test-Path "$ProjectRoot\pwsh\modules\LabRunner")) {
        Write-Error "LabRunner module path does not exist: $ProjectRoot\pwsh\modules\LabRunner"
        throw
    }
    $ResolvedCodeFixerPath = Resolve-Path "$ProjectRoot\pwsh\modules\CodeFixer"
    $ResolvedLabRunnerPath = Resolve-Path "$ProjectRoot\pwsh\modules\LabRunner"
    Write-Host "Resolved CodeFixer Path: $ResolvedCodeFixerPath" -ForegroundColor Cyan
    Write-Host "Resolved LabRunner Path: $ResolvedLabRunnerPath" -ForegroundColor Cyan
    try {
        Import-Module $ResolvedCodeFixerPath -Force -ErrorAction Stop
        Write-Host "CodeFixer module imported successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to import CodeFixer module: $($_.Exception.Message)"
        throw
    }
    try {
        Import-Module $ResolvedLabRunnerPath -Force -ErrorAction Stop
        Write-Host "LabRunner module imported successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to import LabRunner module: $($_.Exception.Message)"
        throw
    }
} else {
    # For non-Windows platforms or when current directory detection fails
    $ProjectRoot = (Get-Location).Path
    $CodeFixerPath = Join-Path $ProjectRoot "pwsh\modules\CodeFixer"
    $LabRunnerPath = Join-Path $ProjectRoot "pwsh\modules\LabRunner"
    
    if (-not (Test-Path $CodeFixerPath)) {
        Write-Error "CodeFixer module path does not exist: $CodeFixerPath"
        throw
    }
    if (-not (Test-Path $LabRunnerPath)) {
        Write-Error "LabRunner module path does not exist: $LabRunnerPath"
        throw
    }
    Import-Module $CodeFixerPath -Force -ErrorAction Stop
    Import-Module $LabRunnerPath -Force -ErrorAction Stop
}

Write-Host "ProjectRoot: $ProjectRoot" -ForegroundColor Cyan
Write-Host "CodeFixer Path: $(Join-Path $ProjectRoot 'pwsh\modules\CodeFixer')" -ForegroundColor Cyan
Write-Host "LabRunner Path: $(Join-Path $ProjectRoot 'pwsh\modules\LabRunner')" -ForegroundColor Cyan

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
$($Report.Summary.InfrastructureHealth | ConvertTo-Json -Depth 10)

## Workflow Health
$($Report.Summary.WorkflowHealth | ConvertTo-Json -Depth 10)

## Validation Results
$($Report.Summary.ValidationResults | ConvertTo-Json -Depth 10)

## Auto-Fix Results
$($Report.Summary.AutoFixResults | ConvertTo-Json -Depth 10)
"@

    # Ensure output directory exists
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    
    # Write report
    $reportFile = Join-Path $OutputPath "unified-health-report.md"
    Set-Content -Path $reportFile -Value $reportContent -Force
    
    Write-Host "Report generated at: $reportFile" -ForegroundColor Green
}

Write-Host "Starting unified health check in $Mode mode..." -ForegroundColor Cyan

try {
    # Run basic health checks using imported modules
    Write-Host "Running health checks using imported modules..." -ForegroundColor Yellow
    
    # Test module availability
    $moduleTests = @{
        CodeFixer = (Get-Module CodeFixer) -ne $null
        LabRunner = (Get-Module LabRunner) -ne $null
    }
    
    # Run basic validation using available functions
    if ($moduleTests.CodeFixer) {
        Write-Host "Running CodeFixer validation..." -ForegroundColor Green
        try {
            # Use basic PowerShell linting if available
            if (Get-Command Invoke-PowerShellLint -ErrorAction SilentlyContinue) {
                $lintResults = Invoke-PowerShellLint -Path $ProjectRoot -Quick
                $unifiedReport.Summary.ValidationResults += @{
                    Type = "PowerShellLint"
                    Results = $lintResults
                    Status = if ($lintResults.TotalErrors -eq 0) { "PASS" } else { "FAIL" }
                }
            }
        } catch {
            Write-Warning "PowerShell linting failed: $($_.Exception.Message)"
        }
    }
    
    # Run infrastructure health check if available
    if ($Mode -in "Infrastructure", "Full", "All") {
        Write-Host "Running infrastructure health check..." -ForegroundColor Yellow
        $infraHealthScript = Join-Path $PSScriptRoot "Analyze-InfrastructureHealth.ps1"
        if (Test-Path $infraHealthScript) {
            try {
                $unifiedReport.Summary.InfrastructureHealth = & $infraHealthScript -OutputFormat $OutputFormat -AutoFix:$AutoFix
            } catch {
                Write-Warning "Infrastructure health check failed: $($_.Exception.Message)"
                $unifiedReport.Summary.InfrastructureHealth = @{ Status = "ERROR"; Message = $_.Exception.Message }
            }
        } else {
            Write-Warning "Infrastructure health script not found: $infraHealthScript"
            $unifiedReport.Summary.InfrastructureHealth = @{ Status = "SKIPPED"; Message = "Script not found" }
        }
    }

    # Run quick validation for Quick mode
    if ($Mode -eq "Quick") {
        Write-Host "Running quick validation..." -ForegroundColor Yellow
        $quickResults = @{
            ModulesLoaded = $moduleTests
            ProjectRootExists = Test-Path $ProjectRoot
            ScriptPathExists = Test-Path $PSScriptRoot
            Timestamp = Get-Date
        }
        $unifiedReport.Summary.ValidationResults += @{
            Type = "Quick"
            Results = $quickResults
            Status = "PASS"
        }
    }

    # Generate report
    Write-Host "Generating health report..." -ForegroundColor Yellow
    Write-HealthReport -Report $unifiedReport -OutputPath $OutputPath

    Write-Host "Health check completed successfully!" -ForegroundColor Green
    return $unifiedReport

} catch {
    Write-Error "Error during unified health check: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    throw
}




# comprehensive-health-check.ps1
# This script is a wrapper around the CodeFixer module's health check capabilities
[CmdletBinding()]
param(
    [switch]$CI,
    [switch]$Detailed,
    [ValidateSet('JSON','Text')






]
    [string]$OutputFormat = 'Text',
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

# Import the CodeFixer module
try {
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $modulePath = Join-Path $repoRoot "pwsh/modules/CodeFixer/CodeFixer.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "CodeFixer module not found at path: $modulePath"
        exit 1
    }
} catch {
    Write-Error "Failed to import CodeFixer module: $_"
    exit 1
}

# Run YAML validation first
try {
    Write-Host "Running YAML validation..." -ForegroundColor Cyan
    $yamlScript = Join-Path $repoRoot "scripts/validation/Invoke-YamlValidation.ps1"
    if (Test-Path $yamlScript) {
        & $yamlScript -Mode "Check" -Path ".github/workflows"
        Write-Host "YAML validation completed" -ForegroundColor Green
    } else {
        Write-Warning "YAML validation script not found at: $yamlScript"
    }
} catch {
    Write-Warning "YAML validation failed: $($_.Exception.Message)"
}

# Run comprehensive validation using the module
try {
    $params = @{
        OutputFormat = $OutputFormat
    }
    
    if ($CI) {
        $params.CI = $true
    }
    
    if ($Detailed) {
        $params.Detailed = $true
    }
    
    if ($OutputPath) {
        $params.OutputPath = $OutputPath
    }
    
    Invoke-ComprehensiveValidation @params
} catch {
    Write-Host "Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}




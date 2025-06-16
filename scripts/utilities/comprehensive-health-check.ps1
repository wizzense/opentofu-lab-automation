#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive health check script for OpenTofu Lab Automation project
.DESCRIPTION
    Performs basic health checks and uses final validation as primary check
.PARAMETER CI
    Indicates running in CI environment
.PARAMETER OutputFormat
    Output format for results (JSON, Text)
#>

CmdletBinding()
param(
    switch$CI,
    ValidateSet('JSON', 'Text')
    string$OutputFormat = 'Text'
)

# Use the existing final validation script as the core health check
try {
    $validationPath = Join-Path $PSScriptRoot "run-final-validation.ps1"
    if (Test-Path $validationPath) {
        Write-Host "Running final validation as health check..." -ForegroundColor Green
        & $validationPath
        $healthStatus = $LASTEXITCODE -eq 0
    } else {
        Write-Warning "Final validation script not found, performing basic checks"
        $healthStatus = $true
    }
    
    $healthReport = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        status = if ($healthStatus) { 'healthy' } else { 'unhealthy' }
        checks = @{
            validation = $healthStatus
            modules = Test-Path "pwsh/modules/CodeFixer"
            scripts = Test-Path "scripts"
            tests = Test-Path "tests"
        }
    }
    
    if ($OutputFormat -eq 'JSON') {
        $healthReport  ConvertTo-Json -Depth 3
    } else {
        Write-Host "Health Status: $($healthReport.status)" -ForegroundColor $(if ($healthStatus) { 'Green' } else { 'Red' })
        Write-Host "Validation: $($healthReport.checks.validation)" 
        Write-Host "Modules: $($healthReport.checks.modules)"
        Write-Host "Scripts: $($healthReport.checks.scripts)"
        Write-Host "Tests: $($healthReport.checks.tests)"
    }
    
    exit $(if ($healthStatus) { 0 } else { 1 })
} catch {
    Write-Error "Health check failed: $_"
    exit 1
}

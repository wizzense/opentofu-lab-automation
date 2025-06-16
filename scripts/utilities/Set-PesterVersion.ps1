#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ensure Pester 5.7.1 is used consistently across the project
.DESCRIPTION
    This script validates that only Pester 5.7.1 is loaded and available,
    preventing conflicts with older versions like 3.4.0
.PARAMETER Force
    Force import of Pester 5.7.1 even if another version is loaded
#>

param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "PESTER VERSION VALIDATOR" -ForegroundColor Cyan
Write-Host "Ensuring consistent Pester 5.7.1 usage" -ForegroundColor Yellow

# Check what's currently loaded
$loadedPester = Get-Module Pester
if ($loadedPester) {
    Write-Host "Currently loaded Pester: $($loadedPester.Version)" -ForegroundColor Yellow
    if ($loadedPester.Version -ne "5.7.1") {
        Write-Warning "Wrong Pester version loaded: $($loadedPester.Version)"
        if ($Force) {
            Remove-Module Pester -Force
            Write-Host "Removed incorrect Pester version" -ForegroundColor Green
        } else {
            Write-Host "Use -Force to remove incorrect version" -ForegroundColor Red
            return
        }
    }
}

# Check available versions
$availablePester = Get-Module -ListAvailable Pester
Write-Host "`nAvailable Pester versions:" -ForegroundColor Cyan
foreach ($version in $availablePester) {
    $status = if ($version.Version -eq "5.7.1") { "[PREFERRED]" } else { "[OLD]" }
    Write-Host "  $($version.Version) - $($version.Path) $status" -ForegroundColor $(if ($version.Version -eq "5.7.1") { "Green" } else { "Yellow" })
}

# Import the correct version
try {
    Import-Module Pester -RequiredVersion 5.7.1 -Force
    $importedVersion = (Get-Module Pester).Version
    Write-Host "`nSuccessfully imported Pester $importedVersion" -ForegroundColor Green
    
    # Verify critical functions are available
    $testFunctions = @('Invoke-Pester', 'Describe', 'It', 'Should')
    foreach ($func in $testFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            Write-Host "   $func available" -ForegroundColor Green
        } else {
            Write-Warning "   $func not available"
        }
    }
    
} catch {
    Write-Error "Failed to import Pester 5.7.1: $($_.Exception.Message)"
}

# Create module preference for future sessions
$profilePath = $PROFILE.CurrentUserAllHosts
if ($profilePath -and (Test-Path (Split-Path $profilePath))) {
    $pesterPreference = @"

# Ensure Pester 5.7.1 is used consistently
if (Get-Module -ListAvailable Pester) {
    Import-Module Pester -RequiredVersion 5.7.1 -Force -WarningAction SilentlyContinue
}
"@
    
    if (Test-Path $profilePath) {
        $currentProfile = Get-Content $profilePath -Raw
        if ($currentProfile -notlike "*Pester -RequiredVersion 5.7.1*") {
            Add-Content -Path $profilePath -Value $pesterPreference
            Write-Host "Added Pester 5.7.1 preference to PowerShell profile" -ForegroundColor Green
        }
    } else {
        Set-Content -Path $profilePath -Value $pesterPreference
        Write-Host "Created PowerShell profile with Pester 5.7.1 preference" -ForegroundColor Green
    }
}

Write-Host "`nPester validation complete!" -ForegroundColor Cyan

# auto-fix.ps1 
# A simple wrapper around the CodeFixer module's Invoke-AutoFix function
[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Quiet,
    [switch]$Force,
    [string[]]$ScriptPaths,
    [ValidateSet('All', 'Syntax', 'Ternary', 'ScriptOrder', 'ImportModule')






]
    [string[]]$FixTypes = 'All'
)

$ErrorActionPreference = 'Stop'

# Import the CodeFixer module
try {
    $modulePath = Join-Path $PSScriptRoot "pwsh/modules/CodeFixer/CodeFixer.psd1"
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

# Run the auto-fix process using the module
try {
    $params = @{
        FixTypes = $FixTypes
    }
    
    if ($Apply) {
        $params.ApplyFixes = $true
    }
    
    if ($Quiet) {
        $params.Quiet = $true
    }
    
    if ($Force) {
        $params.Force = $true
    }
    
    if ($ScriptPaths -and $ScriptPaths.Count -gt 0) {
        $params.ScriptPaths = $ScriptPaths
    }
    
    Invoke-AutoFix @params
} catch {
    Write-Host "Auto-fix process failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}




# comprehensive-lint.ps1
# This script is a wrapper around the CodeFixer module's Invoke-PowerShellLint function
CmdletBinding()
param(
    switch$FixErrors,
    ValidateSet('Default', 'CI', 'JSON', 'Detailed')







    string$OutputFormat = 'Default',
    string$OutputPath,
    switch$IncludeArchive
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

# Run the linting using the module
try {
    $params = @{
        OutputFormat = $OutputFormat
    }
    
    if ($FixErrors) {
        $params.FixErrors = $true
    }
    
    if ($OutputPath) {
        $params.OutputPath = $OutputPath
    }
    
    if ($IncludeArchive) {
        $params.IncludeArchive = $true
    }
    
    Invoke-PowerShellLint @params
} catch {
    Write-Host "Linting failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}




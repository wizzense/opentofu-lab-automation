# Test script to verify PSScriptAnalyzer works
$ErrorActionPreference = 'Stop'
try {
    Import-Module PSScriptAnalyzer -Force
    $settings = Join-Path $PWD 'pwsh/PSScriptAnalyzerSettings.psd1'
    Write-Host "Settings file: $settings"
    Write-Host "Settings content:"
    Get-Content $settings
    
    # Test with a simple file first
    $testFile = 'pwsh/kicker-bootstrap.ps1'
    if (Test-Path $testFile) {
        Write-Host "Testing with file: $testFile"
        $results = Invoke-ScriptAnalyzer -Path $testFile -Severity Error,Warning -Settings $settings
        Write-Host "Results count: $($results.Count)"
        $results | Format-Table
    } else {
        Write-Host "Test file not found: $testFile"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Full error: $_"
}

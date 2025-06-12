# Comprehensive lint test
$ErrorActionPreference = 'Stop'
try {
    Import-Module PSScriptAnalyzer -Force
    $settings = Join-Path $PWD 'pwsh/PSScriptAnalyzerSettings.psd1'
    
    Write-Host "Running comprehensive PowerShell analysis..." -ForegroundColor Yellow
    
    $files = Get-ChildItem -Path . -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
        Where-Object { 
            $_.FullName -ne $settings -and 
            $_.FullName -notlike "*cleanup-backup*" -and
            $_.FullName -notlike "*archive*" 
        } |
        Select-Object -ExpandProperty FullName
    
    Write-Host "Found $($files.Count) PowerShell files to analyze"
    
    $allResults = @()
    foreach ($file in $files) {
        try {
            $results = Invoke-ScriptAnalyzer -Path $file -Severity Error,Warning -Settings $settings
            if ($results) {
                $allResults += $results
                Write-Host "Issues found in: $file" -ForegroundColor Red
                $results | Format-Table -Property Severity, RuleName, Message, Line
            }
        } catch {
            Write-Warning "Could not analyze $file`: $_"
        }
    }
    
    if ($allResults) {
        Write-Host "`nSummary: Found $($allResults.Count) total issues" -ForegroundColor Red
        $errors = $allResults | Where-Object Severity -eq 'Error'
        $warnings = $allResults | Where-Object Severity -eq 'Warning'
        Write-Host "Errors: $($errors.Count), Warnings: $($warnings.Count)" -ForegroundColor Red
        
        if ($errors) {
            Write-Host "`nERRORS DETECTED - Workflow would fail" -ForegroundColor Red
            exit 1
        } else {
            Write-Host "`nOnly warnings found - Workflow would succeed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nNo issues found - All clean!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}

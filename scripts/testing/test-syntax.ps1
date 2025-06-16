






# Test all runner scripts for valid PowerShell syntax
$ErrorActionPreference = 'Continue'

Write-Host "=== Testing PowerShell Syntax for All Runner Scripts ===" -ForegroundColor Cyan

$scriptsDir = "pwsh/runner_scripts"
$scripts = Get-ChildItem -Path $scriptsDir -Filter "*.ps1"

$validCount = 0
$errorCount = 0

foreach ($script in $scripts) {
 try {
 $content = Get-Content $script.FullName -Raw
 System.Management.Automation.PSParser::Tokenize($content, ref$null) | Out-NullWrite-Host "PASS $($script.Name) - VALID SYNTAX" -ForegroundColor Green
 $validCount++
 } catch {
 Write-Host "FAIL $($script.Name) - ERROR: $($_.Exception.Message)" -ForegroundColor Red
 $errorCount++
 }
}

Write-Host "`n=== Syntax Check Complete ===" -ForegroundColor Cyan
Write-Host "PASS Valid: $validCount scripts" -ForegroundColor Green
Write-Host "FAIL Errors: $errorCount scripts" -ForegroundColor Red

if ($errorCount -eq 0) {
 Write-Host " ALL SCRIPTS HAVE VALID POWERSHELL SYNTAX!" -ForegroundColor Green -BackgroundColor Black
} else {
 Write-Host "WARN Some scripts still have syntax errors" -ForegroundColor Yellow
}
Import-Module (Join-Path $PSScriptRoot "/pwsh/modules/CodeFixer/CodeFixer.psd1") -Force






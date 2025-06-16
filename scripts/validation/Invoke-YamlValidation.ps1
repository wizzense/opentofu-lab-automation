#!/usr/bin/env pwsh
<#
.SYNOPSIS
 Comprehensive YAML validation and auto-fix for GitHub workflows

.DESCRIPTION
 This script validates and automatically fixes YAML issues in GitHub workflow files.
 It integrates with our maintenance automation to ensure workflow files are always valid.

.PARAMETER Mode
 Validation mode: Check, Fix, Report

.PARAMETER Path
 Path to check for YAML files (default: .github/workflows)

.EXAMPLE
 ./Invoke-YamlValidation.ps1 -Mode Fix
#>

param(
 ValidateSet("Check", "Fix", "Report")
 string$Mode = "Check",
 
 string$Path = ".github/workflows",
 
 switch$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host " YAML Validation and Auto-Fix" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Mode: $Mode" -ForegroundColor Yellow
Write-Host "Path: $Path" -ForegroundColor Yellow
Write-Host ""

# Load configuration from external file
$scriptPath = $PSScriptRoot
$configPath = Join-Path (Split-Path (Split-Path $scriptPath -Parent) -Parent) "configs\yamllint.yaml"

function Get-PythonCommand {
 $pythonCommands = @(
 'python3',
 'python',
 'py -3'
 )
 
 # Add potential Windows Python paths
 if ($IsWindows) {
 $programFiles = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LocalAppData)
 foreach ($pf in $programFiles) {
 if ($pf) {
 Get-ChildItem -Path $pf -Filter "Python*" -Directory -ErrorAction SilentlyContinue | ForEach-Object{
 $pythonExe = Join-Path $_.FullName "python.exe"
 if (Test-Path $pythonExe) {
 $pythonCommands += $pythonExe
 }
 }
 }
 }
 }
 
 foreach ($cmd in $pythonCommands) {
 try {
 $version = & $cmd --version 2>&1
 if ($version -match "Python 3") {
 return $cmd
 }
 }
 catch {
 continue
 }
 }
 
 throw "No Python 3 installation found"
}

function Test-YamlLintAvailable {
 try {
 $result = yamllint --version 2>$null
 return $true
 }
 catch {
 Write-Host "WARN yamllint not available, installing..." -ForegroundColor Yellow
 try {
 $pythonCmd = Get-PythonCommand
 Write-Host "Using Python: $pythonCmd" -ForegroundColor Cyan
 & $pythonCmd -m pip install --user yamllint
 
 # Add pip user directory to PATH if on Windows
 if ($IsWindows) {
 $pipUserPath = & $pythonCmd -m site --user-site
 $binPath = Join-Path (Split-Path $pipUserPath) "Scripts"
 if (Test-Path $binPath) {
 $env:PATH = "$binPath;$env:PATH"
 }
 }
 
 return $true
 }
 catch {
 Write-Host "FAIL Failed to install yamllint: $_" -ForegroundColor Red
 return $false
 }
 }
}

function Get-YamlFiles {
 param(string$SearchPath)
 
 $yamlFiles = @()
 if (Test-Path $SearchPath) {
 $yamlFiles = Get-ChildItem -Path $SearchPath -Recurse -Include "*.yml", "*.yaml" | Where-Object{ 
     !$_.PSIsContainer -and 
     $_.Name -notlike "*.backup*" -and 
     $_.Name -notlike "*archive*" -and
     $_.Name -notlike "*deprecated*"
 }
 }
 
 return $yamlFiles
}

function Test-YamlSyntax {
 param(
 Parameter(Mandatory=$true)
 string$FilePath,
 int$MaxRetries = 3
 )
 
 $retryCount = 0
 $success = $false
 $lastError = $null
 
 do {
 try {
 # Get Python command dynamically
 $pythonCmd = Get-PythonCommand # More comprehensive YAML validation script
 $pythonCode = @"
import sys
import yaml
try:
    with open(r'$($FilePath.Replace('\', '\\'))', 'r', encoding='utf-8') as f:
        content = f.read()
    yaml.safe_load(content)
    print('OK')
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
 
 # Save the validation script to a temporary file
 $tempScript = System.IO.Path::GetTempFileName() + ".py"
 pythonCode | Out-File -FilePath $tempScript -Encoding UTF8
 
 try {
 $pythonTest = & $pythonCmd $tempScript 2>&1
 if ($pythonTest -contains "OK") {
 return @{
 Valid = $true
 Errors = @()
 }
 }
 else {
 return @{
 Valid = $false
 Errors = @($pythonTest)
 }
 }
 }
 finally {
 Remove-Item $tempScript -ErrorAction SilentlyContinue
 }
 
 $success = $true
 }
 catch {
 $lastError = $_
 $retryCount++
 
 if ($retryCount -lt $MaxRetries) {
 Write-Host "WARN YAML syntax check attempt $retryCount failed, retrying..." -ForegroundColor Yellow
 Start-Sleep -Seconds 1
 }
 }
 } while (-not $success -and $retryCount -lt $MaxRetries)
 
 return @{
 Valid = $false
 Errors = @("YAML syntax check failed after $MaxRetries attempts: $lastError")
 }
}

function Invoke-YamlLint {
 param(
 Parameter(Mandatory=$true)
 string$FilePath,
 
 int$MaxRetries = 3
 )
 
 # Ensure the config file exists
 if (-not (Test-Path $configPath)) {
 throw "YAML lint config file not found at: $configPath"
 }
 
 $retryCount = 0
 $success = $false
 $lastError = $null
 
 do {
 try {
 $lintResult = yamllint -c $configPath -f parsable $FilePath 2>&1
 $errors = @()
 $warnings = @()
 
 foreach ($line in $lintResult) {
 if ($line -match "error") {
 $errors += $line
 }
 elseif ($line -match "warning") {
 $warnings += $line
 }
 }
 
 $success = $true
 
 return @{
 Errors = $errors
 Warnings = $warnings
 ExitCode = $LASTEXITCODE
 }
 }
 catch {
 $lastError = $_
 $retryCount++
 
 if ($retryCount -lt $MaxRetries) {
 Write-Host "WARN YAML lint attempt $retryCount failed, retrying..." -ForegroundColor Yellow
 Start-Sleep -Seconds 1
 }
 }
 } while (-not $success -and $retryCount -lt $MaxRetries)
 
 if (-not $success) {
 Write-Host "FAIL YAML lint failed after $MaxRetries attempts: $lastError" -ForegroundColor Red
 throw $lastError
 }
}

function Repair-YamlFile {
 param(string$FilePath)
 
 Write-Host " Auto-fixing YAML file: $FilePath" -ForegroundColor Yellow
 
 $content = Get-Content $FilePath -Raw
 $originalContent = $content
 $fixesApplied = @()
 
 # Fix 1: Remove trailing whitespace
 if ($content -match '\s+$') {
 $content = $content -replace '\s+$', ''
 $fixesApplied += "Removed trailing whitespace"
 } # Fix 2: Fix truthy values while preserving GitHub Actions keywords
 # Skip this fix for GitHub workflow files
 $isWorkflow = $FilePath -match '\.github/\\workflows/\\.*\.ya?ml$'
 
 if (-not $isWorkflow) {
 # Define truthy value replacements as an array of replacement pairs
 $truthyReplacements = @(
 @{ Pattern = 'off:'; Replace = 'false:' }
 @{ Pattern = 'yes:'; Replace = 'true:' }
 @{ Pattern = 'no:'; Replace = 'false:' }
 @{ Pattern = 'Off:'; Replace = 'false:' }
 @{ Pattern = 'Yes:'; Replace = 'true:' }
 @{ Pattern = 'No:'; Replace = 'false:' }
 @{ Pattern = 'OFF:'; Replace = 'false:' }
 @{ Pattern = 'YES:'; Replace = 'true:' }
 @{ Pattern = 'NO:'; Replace = 'false:' }
 # Removed 'on:' -> 'true:' conversion as it's a valid GitHub Actions keyword
 )
 
 foreach ($replacement in $truthyReplacements) {
 if ($content -match regex::Escape($replacement.Pattern)) {
 $content = $content -replace regex::Escape($replacement.Pattern), $replacement.Replace
 $fixesApplied += "Fixed truthy value: $($replacement.Pattern) -> $($replacement.Replace)"
 }
 }
 }
 
 # Fix 3: Normalize indentation (2 spaces)
 $lines = $content -split "`n"
 $fixedLines = @()
 
 foreach ($line in $lines) {
 # Replace tabs with spaces
 if ($line -match '\t') {
 $line = $line -replace '\t', ' '
 if ($fixesApplied -notcontains "Fixed tab indentation") {
 $fixesApplied += "Fixed tab indentation"
 }
 }
  # DISABLED: Fix inconsistent spacing - CAUSES YAML CORRUPTION
 # This logic was destroying valid YAML indentation by incorrectly
 # calculating spaces and breaking GitHub Actions workflow structure
 # if ($line -match '^( {3,})' -and $line -notmatch '^( {2})*') {
 #     $leadingSpaces = ($Matches1.Length)
 #     $correctSpaces = Math::Floor($leadingSpaces / 2) * 2
 #     $line = (' ' * $correctSpaces) + $line.TrimStart()
 #     if ($fixesApplied -notcontains "Fixed indentation spacing") {
 #         $fixesApplied += "Fixed indentation spacing"
 #     }
 # }
 
 $fixedLines += $line
 }
 
 $content = $fixedLines -join "`n"
 
 # Fix 4: Ensure proper line endings
 if ($content -notmatch "`n$") {
 $content += "`n"
 $fixesApplied += "Added final newline"
 }
 
 # Fix 5: Remove excessive blank lines
 $content = $content -replace "`n{3,}", "`n`n"
 if ($content -ne $originalContent -and $fixesApplied -notcontains "Removed excessive blank lines") {
 $fixesApplied += "Removed excessive blank lines"
 }
 
 # Apply fixes if any were made
 if ($content -ne $originalContent) {
 Set-Content $FilePath $content -NoNewline -Encoding UTF8
 Write-Host " PASS Applied $($fixesApplied.Count) fixes:" -ForegroundColor Green
 foreach ($fix in $fixesApplied) {
 Write-Host " - $fix" -ForegroundColor White
 }
 return $true
 }
 else {
 Write-Host " PASS No fixes needed" -ForegroundColor Green
 return $false
 }
}

function Invoke-YamlValidation {
 param(string$Mode, string$Path)
 
 $results = @{
 TotalFiles = 0
 ValidFiles = 0
 InvalidFiles = 0
 FixedFiles = 0
 Errors = @()
 Warnings = @()
 }
 
 # Check if yamllint is available
 if (-not (Test-YamlLintAvailable)) {
 Write-Host "FAIL yamllint is required but not available" -ForegroundColor Red
 return $results
 }
 
 # Get all YAML files
 $yamlFiles = Get-YamlFiles -SearchPath $Path
 $results.TotalFiles = $yamlFiles.Count
 
 if ($yamlFiles.Count -eq 0) {
 Write-Host "WARN No YAML files found in $Path" -ForegroundColor Yellow
 return $results
 }
 
 Write-Host "� Found $($yamlFiles.Count) YAML files" -ForegroundColor Cyan
 Write-Host ""
 
 foreach ($file in $yamlFiles) {
 $relativePath = Resolve-Path $file.FullName -Relative
 Write-Host " Checking: $relativePath" -ForegroundColor White
 
 # Test basic syntax first
 $syntaxTest = Test-YamlSyntax -FilePath $file.FullName
 
 if (-not $syntaxTest.Valid) {
 Write-Host " FAIL Syntax errors found:" -ForegroundColor Red
 foreach ($error in $syntaxTest.Errors) {
 Write-Host " $error" -ForegroundColor Red
 $results.Errors += "$relativePath`: $error"
 }
 $results.InvalidFiles++
 
 if ($Mode -eq "Fix") {
 Write-Host " Attempting basic fixes..." -ForegroundColor Yellow
 $fixed = Repair-YamlFile -FilePath $file.FullName
 if ($fixed) {
 $results.FixedFiles++
 # Re-test after fixes
 $retestSyntax = Test-YamlSyntax -FilePath $file.FullName
 if ($retestSyntax.Valid) {
 Write-Host " PASS Fixed and now valid" -ForegroundColor Green
 $results.ValidFiles++
 $results.InvalidFiles--
 }
 }
 }
 continue
 }
 # Run detailed linting
 $lintResult = Invoke-YamlLint -FilePath $file.FullName
 
 if ($lintResult.Errors.Count -gt 0) {
 Write-Host " FAIL Linting errors:" -ForegroundColor Red
 foreach ($error in $lintResult.Errors) {
 Write-Host " $error" -ForegroundColor Red
 $results.Errors += $error
 }
 $results.InvalidFiles++
 
 if ($Mode -eq "Fix") {
 $fixed = Repair-YamlFile -FilePath $file.FullName
 if ($fixed) {
 $results.FixedFiles++
 }
 }
 }
 elseif ($lintResult.Warnings.Count -gt 0) {
 Write-Host " WARN Warnings:" -ForegroundColor Yellow
 foreach ($warning in $lintResult.Warnings) {
 Write-Host " $warning" -ForegroundColor Yellow
 $results.Warnings += $warning
 }
 $results.ValidFiles++
 
 if ($Mode -eq "Fix") {
 $fixed = Repair-YamlFile -FilePath $file.FullName
 if ($fixed) {
 $results.FixedFiles++
 }
 }
 }
 else {
 Write-Host " PASS Valid" -ForegroundColor Green
 $results.ValidFiles++
 
 if ($Mode -eq "Fix") {
 $fixed = Repair-YamlFile -FilePath $file.FullName
 if ($fixed) {
 $results.FixedFiles++
 }
 }
 }
 }
 
 return $results
}

# Main execution
$results = Invoke-YamlValidation -Mode $Mode -Path $Path

# Summary report
Write-Host ""
Write-Host " YAML Validation Summary" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Total files: $($results.TotalFiles)" -ForegroundColor White
Write-Host "Valid files: $($results.ValidFiles)" -ForegroundColor Green
Write-Host "Invalid files: $($results.InvalidFiles)" -ForegroundColor Red

if ($Mode -eq "Fix") {
 Write-Host "Fixed files: $($results.FixedFiles)" -ForegroundColor Yellow
}

Write-Host "Errors: $($results.Errors.Count)" -ForegroundColor Red
Write-Host "Warnings: $($results.Warnings.Count)" -ForegroundColor Yellow

# Exit with appropriate code
if ($results.InvalidFiles -gt 0) {
 Write-Host ""
 Write-Host "FAIL YAML validation failed" -ForegroundColor Red
 exit 1
}
else {
 Write-Host ""
 Write-Host "PASS All YAML files are valid" -ForegroundColor Green
 exit 0
}


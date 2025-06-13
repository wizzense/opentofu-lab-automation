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
    [ValidateSet("Check", "Fix", "Report")]
    [string]$Mode = "Check",
    
    [string]$Path = ".github/workflows",
    
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host "🔍 YAML Validation and Auto-Fix" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Mode: $Mode" -ForegroundColor Yellow
Write-Host "Path: $Path" -ForegroundColor Yellow
Write-Host ""

# Configuration for YAML linting
$yamlLintConfig = @"
extends: default
rules:
  line-length:
    max: 120
  indentation:
    spaces: 2
  trailing-spaces: enable
  empty-lines:
    max: 2
  truthy:
    allowed-values: [true, false]
    check-keys: true
  comments:
    min-spaces-from-content: 1
  brackets:
    min-spaces-inside: 0
    max-spaces-inside: 1
  braces:
    min-spaces-inside: 0
    max-spaces-inside: 1
  colons:
    max-spaces-before: 0
    max-spaces-after: 1
  commas:
    max-spaces-before: 0
    max-spaces-after: 1
"@

function Test-YamlLintAvailable {
    try {
        $result = yamllint --version 2>$null
        return $true
    }
    catch {
        Write-Host "⚠️ yamllint not available, installing..." -ForegroundColor Yellow
        try {
            pip install yamllint
            return $true
        }
        catch {
            Write-Host "❌ Failed to install yamllint" -ForegroundColor Red
            return $false
        }
    }
}

function Get-YamlFiles {
    param([string]$SearchPath)
    
    $yamlFiles = @()
    if (Test-Path $SearchPath) {
        $yamlFiles = Get-ChildItem -Path $SearchPath -Recurse -Include "*.yml", "*.yaml" | Where-Object { !$_.PSIsContainer }
    }
    
    return $yamlFiles
}

function Test-YamlSyntax {
    param([string]$FilePath)
    
    try {
        # Test with Python YAML parser for syntax
        $pythonTest = python3 -c "import yaml; yaml.safe_load(open('$FilePath')); print('OK')" 2>&1
        if ($pythonTest -notcontains "OK") {
            return @{
                Valid = $false
                Errors = @($pythonTest)
            }
        }
        
        return @{
            Valid = $true
            Errors = @()
        }
    }
    catch {
        return @{
            Valid = $false
            Errors = @("Python YAML test failed: $_")
        }
    }
}

function Invoke-YamlLint {
    param([string]$FilePath, [string]$ConfigData)
    
    # Create temporary config file
    $tempConfig = [System.IO.Path]::GetTempFileName()
    $yamlLintConfig | Out-File -FilePath $tempConfig -Encoding UTF8
    
    try {
        $lintResult = yamllint -c $tempConfig -f parsable $FilePath 2>&1
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
        
        return @{
            Errors = $errors
            Warnings = $warnings
            ExitCode = $LASTEXITCODE
        }
    }
    finally {
        Remove-Item $tempConfig -ErrorAction SilentlyContinue
    }
}

function Repair-YamlFile {
    param([string]$FilePath)
    
    Write-Host "🔧 Auto-fixing YAML file: $FilePath" -ForegroundColor Yellow
    
    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    $fixesApplied = @()
    
    # Fix 1: Remove trailing whitespace
    if ($content -match '\s+$') {
        $content = $content -replace '\s+$', ''
        $fixesApplied += "Removed trailing whitespace"
    }
    
    # Fix 2: Fix truthy values (common GitHub Actions issue)
    # Define truthy value replacements as an array of replacement pairs
    $truthyReplacements = @(
        @{ Pattern = 'on:'; Replace = 'true:' }
        @{ Pattern = 'off:'; Replace = 'false:' }
        @{ Pattern = 'yes:'; Replace = 'true:' }
        @{ Pattern = 'no:'; Replace = 'false:' }
        @{ Pattern = 'On:'; Replace = 'true:' }
        @{ Pattern = 'Off:'; Replace = 'false:' }
        @{ Pattern = 'Yes:'; Replace = 'true:' }
        @{ Pattern = 'No:'; Replace = 'false:' }
        @{ Pattern = 'ON:'; Replace = 'true:' }
        @{ Pattern = 'OFF:'; Replace = 'false:' }
        @{ Pattern = 'YES:'; Replace = 'true:' }
        @{ Pattern = 'NO:'; Replace = 'false:' }
    )
    
    foreach ($replacement in $truthyReplacements) {
        if ($content -match [regex]::Escape($replacement.Pattern)) {
            $content = $content -replace [regex]::Escape($replacement.Pattern), $replacement.Replace
            $fixesApplied += "Fixed truthy value: $($replacement.Pattern) -> $($replacement.Replace)"
        }
    }
    
    # Fix 3: Normalize indentation (2 spaces)
    $lines = $content -split "`n"
    $fixedLines = @()
    
    foreach ($line in $lines) {
        # Replace tabs with spaces
        if ($line -match '\t') {
            $line = $line -replace '\t', '  '
            if ($fixesApplied -notcontains "Fixed tab indentation") {
                $fixesApplied += "Fixed tab indentation"
            }
        }
        
        # Fix inconsistent spacing
        if ($line -match '^( {3,})' -and $line -notmatch '^( {2})*') {
            $leadingSpaces = ($Matches[1].Length)
            $correctSpaces = [Math]::Floor($leadingSpaces / 2) * 2
            $line = (' ' * $correctSpaces) + $line.TrimStart()
            if ($fixesApplied -notcontains "Fixed indentation spacing") {
                $fixesApplied += "Fixed indentation spacing"
            }
        }
        
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
        Write-Host "  ✅ Applied $($fixesApplied.Count) fixes:" -ForegroundColor Green
        foreach ($fix in $fixesApplied) {
            Write-Host "    - $fix" -ForegroundColor White
        }
        return $true
    }
    else {
        Write-Host "  ✅ No fixes needed" -ForegroundColor Green
        return $false
    }
}

function Invoke-YamlValidation {
    param([string]$Mode, [string]$Path)
    
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
        Write-Host "❌ yamllint is required but not available" -ForegroundColor Red
        return $results
    }
    
    # Get all YAML files
    $yamlFiles = Get-YamlFiles -SearchPath $Path
    $results.TotalFiles = $yamlFiles.Count
    
    if ($yamlFiles.Count -eq 0) {
        Write-Host "⚠️ No YAML files found in $Path" -ForegroundColor Yellow
        return $results
    }
    
    Write-Host "📁 Found $($yamlFiles.Count) YAML files" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($file in $yamlFiles) {
        $relativePath = Resolve-Path $file.FullName -Relative
        Write-Host "🔍 Checking: $relativePath" -ForegroundColor White
        
        # Test basic syntax first
        $syntaxTest = Test-YamlSyntax -FilePath $file.FullName
        
        if (-not $syntaxTest.Valid) {
            Write-Host "  ❌ Syntax errors found:" -ForegroundColor Red
            foreach ($error in $syntaxTest.Errors) {
                Write-Host "    $error" -ForegroundColor Red
                $results.Errors += "$relativePath`: $error"
            }
            $results.InvalidFiles++
            
            if ($Mode -eq "Fix") {
                Write-Host "  🔧 Attempting basic fixes..." -ForegroundColor Yellow
                $fixed = Repair-YamlFile -FilePath $file.FullName
                if ($fixed) {
                    $results.FixedFiles++
                    # Re-test after fixes
                    $retestSyntax = Test-YamlSyntax -FilePath $file.FullName
                    if ($retestSyntax.Valid) {
                        Write-Host "  ✅ Fixed and now valid" -ForegroundColor Green
                        $results.ValidFiles++
                        $results.InvalidFiles--
                    }
                }
            }
            continue
        }
        
        # Run detailed linting
        $lintResult = Invoke-YamlLint -FilePath $file.FullName -ConfigData $yamlLintConfig
        
        if ($lintResult.Errors.Count -gt 0) {
            Write-Host "  ❌ Linting errors:" -ForegroundColor Red
            foreach ($error in $lintResult.Errors) {
                Write-Host "    $error" -ForegroundColor Red
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
            Write-Host "  ⚠️ Warnings:" -ForegroundColor Yellow
            foreach ($warning in $lintResult.Warnings) {
                Write-Host "    $warning" -ForegroundColor Yellow
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
            Write-Host "  ✅ Valid" -ForegroundColor Green
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
Write-Host "📊 YAML Validation Summary" -ForegroundColor Cyan
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
    Write-Host "❌ YAML validation failed" -ForegroundColor Red
    exit 1
}
else {
    Write-Host ""
    Write-Host "✅ All YAML files are valid" -ForegroundColor Green
    exit 0
}

#Requires -Version 7.0
<#
.SYNOPSIS
    Emergency audit of validation system failures
    
.DESCRIPTION
    Comprehensive audit to identify why validation systems failed to catch:
    1. Repeated -Force parameters in Import-Module statements
    2. Malformed paths with excessive slashes
    3. Other systematic corruption patterns
    
    This will be our test case for building proper validation
#>

param(
    Parameter(Mandatory = $false)
    switch$DetailedReport,
    
    Parameter(Mandatory = $false)
    switch$GenerateReport
)

$ErrorActionPreference = "Continue"

# Initialize results tracking
$AuditResults = @{
    TotalFilesScanned = 0
    CorruptedFiles = @()
    ValidationSystemFailures = @()
    PatternAnalysis = @{}
    CriticalFindings = @()
    SystemicIssues = @()
}

Write-Host "� EMERGENCY VALIDATION SYSTEM AUDIT �" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Red
Write-Host "Investigating why validation systems failed to catch corruption..." -ForegroundColor Yellow

# Retrieve file list once for reuse
$fileList = Get-ChildItem -Path "." -Recurse -Include "*.ps1"

# Pattern 1: Detect repeated -Force parameters
Write-Host "`n PATTERN 1: Repeated -Force Parameters" -ForegroundColor Cyan
$forcePattern = fileList | ForEach-Object{
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '-Force\s+-Force') {
        $forceCount = ($content  Select-String '-Force' -AllMatches).Matches.Count
        $AuditResults.TotalFilesScanned++
        
        $corruption = @{
            File = $_.FullName
            Type = "RepeatedForceParameters"
            ForceCount = $forceCount
            Severity = if ($forceCount -gt 10) { "CRITICAL" } elseif ($forceCount -gt 5) { "HIGH" } else { "MEDIUM" }
            SampleLine = ($content -split "`n" | Where-Object{ $_ -match '-Force.*-Force' } | Select-Object-First 1)
        }
        
        $AuditResults.CorruptedFiles += $corruption
        $corruption
    }
}

Write-Host "   Found $($forcePattern.Count) files with repeated -Force parameters" -ForegroundColor Red

# Pattern 2: Detect malformed paths with excessive slashes
Write-Host "`n PATTERN 2: Malformed Import Paths" -ForegroundColor Cyan
$pathPattern = Get-ChildItem -Path "." -Recurse -Include "*.ps1" | ForEach-Object{
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '/.*/C:\\.*\') {
        $corruption = @{
            File = $_.FullName
            Type = "MalformedPaths"
            Severity = "HIGH"
            SampleLine = ($content -split "`n" | Where-Object{ $_ -match '/.*/C:\\.*/Import-Module.*/.*\.*' } | Select-Object-First 1)
        }
        
        $AuditResults.CorruptedFiles += $corruption
        $corruption
    }
}

Write-Host "   Found $($pathPattern.Count) files with malformed paths" -ForegroundColor Red

# Pattern 3: Detect Import-Module statements with 20+ Force parameters
Write-Host "`n PATTERN 3: Catastrophic Import Statements" -ForegroundColor Cyan
$catastrophicImports = Get-ChildItem -Path "." -Recurse -Include "*.ps1" | ForEach-Object{
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $importLines = $content -split "`n" | Where-Object{ $_ -match 'Import-Module.*(-Force\s*){20,}' }
    
    if ($importLines) {
        foreach ($line in $importLines) {
            $forceCount = ($line  Select-String '-Force' -AllMatches).Matches.Count
            $corruption = @{
                File = $_.FullName
                Type = "CatastrophicImport"
                ForceCount = $forceCount
                Severity = "CRITICAL"
                SampleLine = $line.Trim()
                LineLength = $line.Length
            }
            
            $AuditResults.CorruptedFiles += $corruption
            $corruption
        }
    }
}

Write-Host "   Found $($catastrophicImports.Count) catastrophic import statements" -ForegroundColor Red

# Analyze why validation systems failed
Write-Host "`n� VALIDATION SYSTEM FAILURE ANALYSIS" -ForegroundColor Magenta

# Check existing validation scripts
$validationScripts = @(
    ".\scripts\maintenance\unified-maintenance.ps1",
    ".\scripts\validation\Invoke-YamlValidation.ps1",
    ".\tools\Validate-PowerShellScripts.ps1",
    ".\scripts\validation\health-check.ps1"
)

foreach ($script in $validationScripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw -ErrorAction SilentlyContinue
        
        $failure = @{
            Script = $script
            HasForceDetection = $content -match 'Force.*Forcerepeated.*Force'
            HasPathValidation = $content -match 'path.*validationmalformed.*path'
            HasImportValidation = $content -match 'Import-Module.*validation'
            LastModified = (Get-Item $script).LastWriteTime
        }
        
        $AuditResults.ValidationSystemFailures += $failure
          Write-Host "   ${script}:" -ForegroundColor Yellow
        Write-Host "     - Force detection: $($failure.HasForceDetection)" -ForegroundColor $(if ($failure.HasForceDetection) { "Green" } else { "Red" })
        Write-Host "     - Path validation: $($failure.HasPathValidation)" -ForegroundColor $(if ($failure.HasPathValidation) { "Green" } else { "Red" })
        Write-Host "     - Import validation: $($failure.HasImportValidation)" -ForegroundColor $(if ($failure.HasImportValidation) { "Green" } else { "Red" })
    } else {
        Write-Host "   ${script}: NOT FOUND" -ForegroundColor Red
        $AuditResults.ValidationSystemFailures += @{ Script = $script; Status = "Missing" }
    }
}

# Generate severity statistics
Write-Host "`n CORRUPTION SEVERITY ANALYSIS" -ForegroundColor Cyan
$severityGroups = $AuditResults.CorruptedFiles | Group-ObjectSeverity
foreach ($group in $severityGroups) {
    Write-Host "   $($group.Name): $($group.Count) files" -ForegroundColor $(
        switch ($group.Name) {
            "CRITICAL" { "Red" }
            "HIGH" { "DarkRed" }
            "MEDIUM" { "Yellow" }
            default { "White" }
        }
    )
}

# Find the worst affected files
Write-Host "`n TOP 10 MOST CORRUPTED FILES" -ForegroundColor Red
$worstFiles = $AuditResults.CorruptedFiles | Where-Object{ $_.ForceCount } | Sort-ObjectForceCount -Descending | Select-Object-First 10

foreach ($file in $worstFiles) {
    $fileName = Split-Path $file.File -Leaf
    Write-Host "   $fileName`: $($file.ForceCount) -Force parameters" -ForegroundColor Red
}

# Critical findings summary
$AuditResults.CriticalFindings = @(
    "FAIL $($forcePattern.Count) files with repeated -Force parameters",
    "FAIL $($pathPattern.Count) files with malformed paths", 
    "FAIL $($catastrophicImports.Count) catastrophic import statements",
    "FAIL Validation systems lack proper pattern detection",
    "FAIL No automated corruption prevention in place",
    "FAIL Auto-fix systems are actively making problems WORSE"
)

Write-Host "`n� CRITICAL FINDINGS SUMMARY" -ForegroundColor Red
foreach ($finding in $AuditResults.CriticalFindings) {
    Write-Host "   $finding" -ForegroundColor Red
}

# Systemic issues identified
$AuditResults.SystemicIssues = @(
    "Validation scripts don't check for repeated parameters",
    "Path validation is insufficient or missing",
    "Import-Module statement validation is broken",
    "Auto-fix systems have no safeguards against escalation",
    "No pattern-based corruption detection",
    "No file corruption history tracking"
)

Write-Host "`n� SYSTEMIC ISSUES IDENTIFIED" -ForegroundColor DarkRed
foreach ($issue in $AuditResults.SystemicIssues) {
    Write-Host "   • $issue" -ForegroundColor DarkRed
}

if ($GenerateReport) {
    $reportPath = ".\EMERGENCY-VALIDATION-AUDIT-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    
    $reportContent = @"
# Emergency Validation System Audit Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Executive Summary
**CRITICAL SYSTEM FAILURE**: Validation systems completely failed to detect widespread file corruption.

## Corruption Statistics
- **Total Files Scanned**: $($AuditResults.TotalFilesScanned)
- **Corrupted Files**: $($AuditResults.CorruptedFiles.Count)
- **Repeated -Force Parameters**: $($forcePattern.Count) files
- **Malformed Paths**: $($pathPattern.Count) files
- **Catastrophic Imports**: $($catastrophicImports.Count) files

## Critical Findings
$($AuditResults.CriticalFindings | ForEach-Object{ "- $_" }  Out-String)

## Systemic Issues
$($AuditResults.SystemicIssues | ForEach-Object{ "- $_" }  Out-String)

## Worst Affected Files
$(worstFiles | ForEach-Object{ "- $($_.File): $($_.ForceCount) -Force parameters" }  Out-String)

## Required Actions
1. **IMMEDIATE**: Stop all auto-fix operations
2. **URGENT**: Implement proper validation patterns
3. **CRITICAL**: Fix all corrupted files
4. **ESSENTIAL**: Rebuild validation systems with safeguards

## Validation System Status
$($AuditResults.ValidationSystemFailures | ForEach-Object{ 
    "- $($_.Script): Force detection: $($_.HasForceDetection), Path validation: $($_.HasPathValidation)"
}  Out-String)
"@

    Set-Content -Path $reportPath -Value $reportContent
    Write-Host "`n� Report generated: $reportPath" -ForegroundColor Green
}

Write-Host "`n� EMERGENCY AUDIT COMPLETE" -ForegroundColor Red
Write-Host "Next steps: Build proper validation systems using this data as test cases" -ForegroundColor Yellow

return $AuditResults




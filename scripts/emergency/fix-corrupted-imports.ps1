#!/usr/bin/env pwsh
<#
.SYNOPSIS
Emergency fix for corrupted import statements caused by faulty PatchManager regex patterns

.DESCRIPTION
This script fixes the massive corruption caused by PatchManager's Invoke-InfrastructureFix function
which has been systematically corrupting import statements by:
1. Adding malformed Linux-style absolute paths on Windows
2. Accumulating duplicate "-Force" flags on every execution
3. Creating double slashes and mixed path separators

.PARAMETER DryRun
Show what would be fixed without making changes

.PARAMETER Verbose
Show detailed information about each fix

.EXAMPLE
./scripts/emergency/fix-corrupted-imports.ps1 -DryRun -Verbose

.EXAMPLE
./scripts/emergency/fix-corrupted-imports.ps1
#>

CmdletBinding()
param(
    Parameter(Mandatory = $false)
    switch$DryRun,
    
    Parameter(Mandatory = $false)
    string$ProjectRoot = $PWD
)

$ErrorActionPreference = "Stop"

function Write-EmergencyLog {
    param(
        string$Message,
        ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL")
        string$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "$timestamp EMERGENCY-FIX $Level $Message"
    
    switch ($Level) {
        "INFO"     { Write-Host $formattedMessage -ForegroundColor Cyan }
        "SUCCESS"  { Write-Host $formattedMessage -ForegroundColor Green }
        "WARNING"  { Write-Host $formattedMessage -ForegroundColor Yellow }
        "ERROR"    { Write-Host $formattedMessage -ForegroundColor Red }
        "CRITICAL" { Write-Host $formattedMessage -ForegroundColor Magenta }
    }
}

Write-EmergencyLog "Starting emergency fix for corrupted import statements..." "CRITICAL"

# Load the manifest to get correct paths
$manifest = $null
try {
    $manifestPath = Join-Path $ProjectRoot "PROJECT-MANIFEST.json"
    $manifest = Get-Content $manifestPath -Raw  ConvertFrom-Json
    Write-EmergencyLog "Loaded project manifest successfully" "SUCCESS"
} catch {
    Write-EmergencyLog "Failed to load manifest: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Define correct import paths from manifest
$correctPaths = @{}
if ($manifest -and $manifest.core -and $manifest.core.modules) {
    $manifest.core.modules.PSObject.Properties  ForEach-Object {
        $moduleName = $_.Name
        $modulePath = $_.Value.path
        $correctPaths$moduleName = $modulePath
    }
}

Write-EmergencyLog "Correct paths from manifest:" "INFO"
foreach ($module in $correctPaths.Keys) {
    Write-EmergencyLog "  $module = $($correctPaths$module)" "INFO"
}

# Find all affected test files
$testFiles = Get-ChildItem -Path "$ProjectRoot/tests" -Filter "*.Tests.ps1" -Recurse -ErrorAction SilentlyContinue

Write-EmergencyLog "Found $($testFiles.Count) test files to check" "INFO"

$corruptedFiles = @()
$fixedFiles = @()
$stats = @{
    FilesChecked = 0
    FilesCorrupted = 0
    FilesFixed = 0
    ForceTagsRemoved = 0
    PathsFixed = 0
}

foreach ($file in $testFiles) {
    $stats.FilesChecked++
    $content = Get-Content -Path $file.FullName -Raw
    $isCorrupted = $false
    $fixes = @()
    
    # Check for corruption patterns
    if ($content -match 'Import-Module\s+"^"*/^"*".*(-Force\s+){3,}') {
        $isCorrupted = $true
        Write-EmergencyLog "Found corrupted import in $($file.Name)" "WARNING"
        $corruptedFiles += $file.FullName
    }
    
    if ($isCorrupted) {
        $stats.FilesCorrupted++
        
        # Fix 1: Remove excessive duplicate -Force flags
        $forceBefore = ($content  Select-String '-Force' -AllMatches).Matches.Count
        $content = $content -replace '(-Force\s+){2,}', '-Force '
        $forceAfter = ($content  Select-String '-Force' -AllMatches).Matches.Count
        $forceRemoved = $forceBefore - $forceAfter
        if ($forceRemoved -gt 0) {
            $stats.ForceTagsRemoved += $forceRemoved
            $fixes += "Removed $forceRemoved duplicate -Force flags"
        }
        
        # Fix 2: Fix malformed paths for each module
        foreach ($moduleName in $correctPaths.Keys) {
            $correctPath = $correctPaths$moduleName
            
            # Pattern to match corrupted imports for this module
            $corruptedPattern = "Import-Module\s+`"^`"*?//^`"*?$moduleName^`"*`""
            
            if ($content -match $corruptedPattern) {
                # Replace with correct relative path
                $content = $content -replace $corruptedPattern, "Import-Module `"$correctPath`""
                $stats.PathsFixed++
                $fixes += "Fixed $moduleName import path"
            }
        }
        
        # Fix 3: Clean up any remaining malformed Windows absolute paths
        $content = $content -replace 'Import-Module\s+"C-Z:^"*?/^"*?"', '

Import-Module "$correctPath"'
        
        # Fix 4: Clean up Linux-style absolute paths that shouldn't be there
        $content = $content -replace 'Import-Module\s+"/^"*?/^"*?"', '

Import-Module "$correctPath"'
        
        # Show what would be fixed
        if ($fixes.Count -gt 0) {
            Write-EmergencyLog "Fixes for $($file.Name):" "INFO"
            foreach ($fix in $fixes) {
                Write-EmergencyLog "  - $fix" "INFO"
            }
            
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $content -NoNewline
                $stats.FilesFixed++
                $fixedFiles += $file.FullName
                Write-EmergencyLog "Fixed $($file.Name)" "SUCCESS"
            } else {
                Write-EmergencyLog "Would fix $($file.Name) (DryRun mode)" "WARNING"
            }
        }
    }
}

# Summary
Write-EmergencyLog "Emergency fix completed!" "CRITICAL"
Write-EmergencyLog "Statistics:" "INFO"
Write-EmergencyLog "  Files checked: $($stats.FilesChecked)" "INFO"
Write-EmergencyLog "  Files corrupted: $($stats.FilesCorrupted)" "INFO"
Write-EmergencyLog "  Files fixed: $($stats.FilesFixed)" "INFO"
Write-EmergencyLog "  Duplicate -Force flags removed: $($stats.ForceTagsRemoved)" "INFO"
Write-EmergencyLog "  Import paths fixed: $($stats.PathsFixed)" "INFO"

if ($DryRun) {
    Write-EmergencyLog "DRY RUN MODE - No changes were applied" "WARNING"
    Write-EmergencyLog "Run without -DryRun to apply fixes" "WARNING"
} else {
    Write-EmergencyLog "Real fixes applied successfully" "SUCCESS"
}

# Now disable the problematic PatchManager function
$patchManagerFix = Join-Path $ProjectRoot "pwsh/modules/PatchManager/Public/Invoke-InfrastructureFix.ps1"
if (Test-Path $patchManagerFix) {
    Write-EmergencyLog "CRITICAL: Disabling problematic PatchManager function..." "CRITICAL"
    
    if (-not $DryRun) {
        $backupPath = "$patchManagerFix.CORRUPTED.backup"
        Copy-Item $patchManagerFix $backupPath
        
        $disabledContent = @"
function Invoke-InfrastructureFix {
    CmdletBinding()
    param (
        Parameter(Mandatory=`$false)
        string`$ProjectRoot = `$PWD,
        
        Parameter(Mandatory=`$false)
        ValidateSet("All", "ImportPaths", "TestSyntax", "ModuleStructure")
        string`$Fix = "All",
        
        Parameter(Mandatory=`$false)
        switch`$AutoFix,
        
        Parameter(Mandatory=`$false)
        switch`$WhatIf
    )
    
    Write-Error "EMERGENCY DISABLED: This function was corrupting import statements. Use './scripts/emergency/fix-corrupted-imports.ps1' instead."
    Write-Error "Original function backed up to: `$PSScriptRoot/Invoke-InfrastructureFix.ps1.CORRUPTED.backup"
    
    return @{
        FixesApplied = 0
        FixesNeeded = 0
        ImportPaths = 0
        TestSyntax = 0
        ModuleStructure = 0
        Errors = 1
        Message = "Function disabled due to corruption bug"
    }
}
"@
        
        Set-Content -Path $patchManagerFix -Value $disabledContent
        Write-EmergencyLog "Disabled Invoke-InfrastructureFix and created backup" "SUCCESS"
    } else {
        Write-EmergencyLog "Would disable Invoke-InfrastructureFix (DryRun mode)" "WARNING"
    }
}

Write-EmergencyLog "Emergency fix script completed!" "SUCCESS"

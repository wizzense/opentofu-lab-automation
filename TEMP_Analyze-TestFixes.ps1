#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Analysis script to show what Fix-TestFailures.ps1 will change

.DESCRIPTION
    This script provides a detailed preview of what changes will be made
    without actually applying them, answering specific questions about:
    - Empty/unused variables that will be removed
    - Module paths being updated (from/to)
    - Missing variables and parameters
#>

# Set up environment
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path $PSScriptRoot "pwsh/modules"
}

if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = $PSScriptRoot
}

# Import logging if available
try {
    Import-Module "$env:PWSH_MODULES_PATH/Logging/" -Force -ErrorAction Stop
} catch {
    function Write-CustomLog {
        param($Message, $Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "INFO" { "Cyan" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

function Analyze-UnusedVariables {
    Write-CustomLog "=== ANALYZING UNUSED VARIABLES ===" -Level INFO
    
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-CustomLog "PSScriptAnalyzer not available - cannot analyze unused variables" -Level WARN
        return
    }
    
    $files = Get-ChildItem -Path "$env:PROJECT_ROOT/pwsh" -Recurse -Filter "*.ps1" | 
        Where-Object { $_.Name -notlike "*.Tests.ps1" -and $_.Name -ne "Fix-TestFailures.ps1" }
    
    Write-CustomLog "Checking $($files.Count) PowerShell files for unused variables..." -Level INFO
    
    $unusedVarReport = @()
    
    foreach ($file in $files) {
        try {
            $issues = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule PSUseDeclaredVarsMoreThanAssignments
            
            if ($issues.Count -gt 0) {
                foreach ($issue in $issues) {
                    $unusedVarReport += [PSCustomObject]@{
                        File = $file.Name
                        Variable = $issue.Extent.Text
                        Line = $issue.Line
                        Severity = $issue.Severity
                        Message = $issue.Message
                    }
                }
            }
        } catch {
            Write-CustomLog "Error analyzing $($file.Name): $($_.Exception.Message)" -Level ERROR
        }
    }
    
    if ($unusedVarReport.Count -gt 0) {
        Write-CustomLog "Found $($unusedVarReport.Count) unused variables:" -Level WARN
        $unusedVarReport | Sort-Object File, Line | ForEach-Object {
            Write-CustomLog "  $($_.File):$($_.Line) - $($_.Variable)" -Level WARN
        }
        Write-CustomLog "ACTION: These will get diagnostic comments added" -Level INFO
    } else {
        Write-CustomLog "No unused variables found" -Level SUCCESS
    }
    
    return $unusedVarReport
}

function Analyze-UnusedParameters {
    Write-CustomLog "`n=== ANALYZING UNUSED PARAMETERS ===" -Level INFO
    
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-CustomLog "PSScriptAnalyzer not available - cannot analyze unused parameters" -Level WARN
        return
    }
    
    $files = Get-ChildItem -Path "$env:PROJECT_ROOT/pwsh" -Recurse -Filter "*.ps1" | 
        Where-Object { $_.Name -notlike "*.Tests.ps1" -and $_.Name -ne "Fix-TestFailures.ps1" }
    
    $unusedParamReport = @()
    
    foreach ($file in $files) {
        try {
            $issues = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule PSReviewUnusedParameter
            
            if ($issues.Count -gt 0) {
                foreach ($issue in $issues) {
                    $unusedParamReport += [PSCustomObject]@{
                        File = $file.Name
                        Parameter = $issue.Extent.Text
                        Line = $issue.Line
                        Function = ($issue.Message -split "'")[1]
                    }
                }
            }
        } catch {
            Write-CustomLog "Error analyzing $($file.Name): $($_.Exception.Message)" -Level ERROR
        }
    }
    
    if ($unusedParamReport.Count -gt 0) {
        Write-CustomLog "Found $($unusedParamReport.Count) unused parameters:" -Level WARN
        $unusedParamReport | Sort-Object File, Line | ForEach-Object {
            Write-CustomLog "  $($_.File):$($_.Line) - $($_.Parameter) in function $($_.Function)" -Level WARN
        }
        Write-CustomLog "ACTION: These will get SuppressMessage attributes added" -Level INFO
    } else {
        Write-CustomLog "No unused parameters found" -Level SUCCESS
    }
    
    return $unusedParamReport
}

function Analyze-ModuleStructureConflicts {
    Write-CustomLog "`n=== ANALYZING MODULE STRUCTURE CONFLICTS ===" -Level INFO
    
    $srcModulesPath = "$env:PROJECT_ROOT/src/pwsh/modules"
    $mainModulesPath = "$env:PROJECT_ROOT/pwsh/modules"
    
    if (Test-Path $srcModulesPath) {
        Write-CustomLog "CONFLICT FOUND: src/pwsh/modules directory exists" -Level WARN
        Write-CustomLog "FROM: $srcModulesPath" -Level WARN
        Write-CustomLog "TO: Will be removed (conflicts with $mainModulesPath)" -Level WARN
        
        # Check what's in the conflicting directory
        $srcModules = Get-ChildItem $srcModulesPath -Directory -ErrorAction SilentlyContinue
        if ($srcModules) {
            Write-CustomLog "Modules in conflicting directory:" -Level INFO
            foreach ($module in $srcModules) {
                $mainModulePath = Join-Path $mainModulesPath $module.Name
                if (Test-Path $mainModulePath) {
                    Write-CustomLog "  $($module.Name) - EXISTS in main (will be skipped)" -Level INFO
                } else {
                    Write-CustomLog "  $($module.Name) - UNIQUE (will be moved to main)" -Level WARN
                }
            }
        }
        Write-CustomLog "ACTION: Remove src/pwsh/modules directory after moving unique modules" -Level INFO
    } else {
        Write-CustomLog "No module structure conflicts found" -Level SUCCESS
    }
}

function Analyze-MissingModuleManifests {
    Write-CustomLog "`n=== ANALYZING MISSING MODULE MANIFESTS ===" -Level INFO
    
    if (-not (Test-Path "$env:PROJECT_ROOT/pwsh/modules")) {
        Write-CustomLog "pwsh/modules directory not found" -Level ERROR
        return
    }
    
    $moduleDirectories = Get-ChildItem -Path "$env:PROJECT_ROOT/pwsh/modules" -Directory
    $missingManifests = @()
    
    foreach ($moduleDir in $moduleDirectories) {
        $manifestPath = Join-Path $moduleDir.FullName "$($moduleDir.Name).psd1"
        
        if (-not (Test-Path $manifestPath)) {
            $missingManifests += [PSCustomObject]@{
                ModuleName = $moduleDir.Name
                ModulePath = $moduleDir.FullName
                ManifestPath = $manifestPath
            }
        }
    }
    
    if ($missingManifests.Count -gt 0) {
        Write-CustomLog "Found $($missingManifests.Count) modules missing manifests:" -Level WARN
        $missingManifests | ForEach-Object {
            Write-CustomLog "  $($_.ModuleName) - $($_.ManifestPath)" -Level WARN
        }
        Write-CustomLog "ACTION: Auto-generate manifests with detected functions" -Level INFO
    } else {
        Write-CustomLog "All modules have manifests" -Level SUCCESS
    }
    
    return $missingManifests
}

function Analyze-ModulePathUpdates {
    Write-CustomLog "`n=== ANALYZING MODULE PATH UPDATES ===" -Level INFO
    
    $testConfigFiles = @(
        "$env:PROJECT_ROOT/tests/config/TestConfiguration.psd1",
        "$env:PROJECT_ROOT/TestConfiguration.psd1"
    )
    
    $pathUpdates = @()
    
    foreach ($configFile in $testConfigFiles) {
        if (Test-Path $configFile) {
            $content = Get-Content $configFile -Raw
            if ($content -match 'src/pwsh/modules') {
                $pathUpdates += [PSCustomObject]@{
                    File = $configFile
                    CurrentPath = "src/pwsh/modules"
                    NewPath = "pwsh/modules"
                    Action = "Replace all instances"
                }
            }
        }
    }
    
    if ($pathUpdates.Count -gt 0) {
        Write-CustomLog "Found $($pathUpdates.Count) configuration files needing path updates:" -Level WARN
        $pathUpdates | ForEach-Object {
            Write-CustomLog "  File: $($_.File)" -Level WARN
            Write-CustomLog "    FROM: $($_.CurrentPath)" -Level WARN
            Write-CustomLog "    TO:   $($_.NewPath)" -Level WARN
        }
        Write-CustomLog "ACTION: Update all module path references" -Level INFO
    } else {
        Write-CustomLog "No module path updates needed in configuration files" -Level SUCCESS
    }
    
    return $pathUpdates
}

function Analyze-TestHelpers {
    Write-CustomLog "`n=== ANALYZING TEST HELPERS ===" -Level INFO
    
    $testHelpersPath = "$env:PROJECT_ROOT/tests/helpers/TestHelpers.ps1"
    
    if (-not (Test-Path $testHelpersPath)) {
        Write-CustomLog "TestHelpers.ps1 is MISSING" -Level WARN
        Write-CustomLog "ACTION: Create comprehensive TestHelpers.ps1 with utility functions" -Level INFO
    } elseif ((Get-Item $testHelpersPath).Length -eq 0) {
        Write-CustomLog "TestHelpers.ps1 is EMPTY" -Level WARN
        Write-CustomLog "ACTION: Populate with comprehensive test utility functions" -Level INFO
    } else {
        $content = Get-Content $testHelpersPath -Raw
        Write-CustomLog "TestHelpers.ps1 exists and has content ($($content.Length) characters)" -Level SUCCESS
        Write-CustomLog "ACTION: Will be preserved (no changes needed)" -Level INFO
    }
}

function Generate-Summary {
    param($UnusedVars, $UnusedParams, $MissingManifests, $PathUpdates)
    
    Write-CustomLog "`n=== COMPREHENSIVE SUMMARY ===" -Level INFO
    Write-CustomLog "Changes that will be made:" -Level INFO
    Write-CustomLog "" -Level INFO
    
    Write-CustomLog "1. UNUSED VARIABLES:" -Level INFO
    if ($UnusedVars.Count -gt 0) {
        Write-CustomLog "   - $($UnusedVars.Count) unused variables will get diagnostic comments" -Level WARN
        Write-CustomLog "   - This helps with PSScriptAnalyzer compliance" -Level INFO
    } else {
        Write-CustomLog "   - No unused variables to fix" -Level SUCCESS
    }
    
    Write-CustomLog "" -Level INFO
    Write-CustomLog "2. UNUSED PARAMETERS:" -Level INFO
    if ($UnusedParams.Count -gt 0) {
        Write-CustomLog "   - $($UnusedParams.Count) unused parameters will get SuppressMessage attributes" -Level WARN
        Write-CustomLog "   - This prevents PSScriptAnalyzer warnings for legitimate cases" -Level INFO
    } else {
        Write-CustomLog "   - No unused parameters to fix" -Level SUCCESS
    }
    
    Write-CustomLog "" -Level INFO
    Write-CustomLog "3. MODULE STRUCTURE:" -Level INFO
    Write-CustomLog "   - Remove conflicting src/pwsh/modules directory" -Level WARN
    Write-CustomLog "   - Keep main pwsh/modules as the authoritative location" -Level INFO
    
    Write-CustomLog "" -Level INFO
    Write-CustomLog "4. MISSING MODULE MANIFESTS:" -Level INFO
    if ($MissingManifests.Count -gt 0) {
        Write-CustomLog "   - $($MissingManifests.Count) modules will get auto-generated manifests" -Level WARN
        Write-CustomLog "   - Functions will be auto-detected and exported" -Level INFO
    } else {
        Write-CustomLog "   - All modules already have manifests" -Level SUCCESS
    }
    
    Write-CustomLog "" -Level INFO
    Write-CustomLog "5. CONFIGURATION PATH UPDATES:" -Level INFO
    if ($PathUpdates.Count -gt 0) {
        Write-CustomLog "   - $($PathUpdates.Count) config files will have paths updated" -Level WARN
        Write-CustomLog "   - 'src/pwsh/modules' → 'pwsh/modules'" -Level INFO
    } else {
        Write-CustomLog "   - No configuration files need path updates" -Level SUCCESS
    }
    
    Write-CustomLog "" -Level INFO
    Write-CustomLog "6. TEST HELPERS:" -Level INFO
    Write-CustomLog "   - TestHelpers.ps1 will be created/updated with utility functions" -Level INFO
    
    Write-CustomLog "" -Level INFO
    Write-CustomLog "SAFETY NOTES:" -Level INFO
    Write-CustomLog "- All changes are designed to preserve functionality" -Level SUCCESS
    Write-CustomLog "- Unused variables get comments, not removal" -Level SUCCESS
    Write-CustomLog "- Unused parameters get suppressions, not removal" -Level SUCCESS
    Write-CustomLog "- Module structure is standardized to pwsh/modules" -Level SUCCESS
    Write-CustomLog "- Missing manifests are auto-generated with detected functions" -Level SUCCESS
}

# Main execution
Write-CustomLog "Fix-TestFailures.ps1 Analysis Report" -Level INFO
Write-CustomLog "Generated: $(Get-Date)" -Level INFO
Write-CustomLog "=" * 60 -Level INFO

$unusedVars = Analyze-UnusedVariables
$unusedParams = Analyze-UnusedParameters
Analyze-ModuleStructureConflicts
$missingManifests = Analyze-MissingModuleManifests
$pathUpdates = Analyze-ModulePathUpdates
Analyze-TestHelpers

Generate-Summary -UnusedVars $unusedVars -UnusedParams $unusedParams -MissingManifests $missingManifests -PathUpdates $pathUpdates

Write-CustomLog "" -Level INFO
Write-CustomLog "To proceed with these changes, run:" -Level INFO
Write-CustomLog "  ./Fix-TestFailures.ps1 -Force" -Level INFO
Write-CustomLog "" -Level INFO

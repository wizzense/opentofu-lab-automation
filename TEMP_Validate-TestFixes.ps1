#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Validates what the Fix-TestFailures script will do before running it

.DESCRIPTION
    This script analyzes the current state and shows exactly what changes
    the Fix-TestFailures script would make, including:
    - Which unused variables will be addressed
    - Which module paths will be updated (from/to)
    - Which missing manifests will be created
    - Which missing parameters will be handled
#>

[CmdletBinding()]
param()

# Set up environment
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path $PSScriptRoot "pwsh/modules"
}

if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = $PSScriptRoot
}

function Write-ValidationLog {
    param($Message, $Level = "INFO")
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" } 
        "SUCCESS" { "Green" }
        "HEADER" { "Cyan" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-UnusedVariables {
    Write-ValidationLog "`n=== UNUSED VARIABLES ANALYSIS ===" -Level HEADER
    
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-ValidationLog "PSScriptAnalyzer not available - cannot analyze unused variables" -Level WARN
        return
    }
    
    $files = Get-ChildItem -Path "$env:PROJECT_ROOT/pwsh" -Recurse -Filter "*.ps1" | 
        Where-Object { $_.Name -notlike "*.Tests.ps1" -and $_.Name -ne "Fix-TestFailures.ps1" }
    
    $totalUnusedVars = 0
    $affectedFiles = @()
    
    foreach ($file in $files) {
        try {
            $issues = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule PSUseDeclaredVarsMoreThanAssignments
            
            if ($issues.Count -gt 0) {
                $affectedFiles += [PSCustomObject]@{
                    File = $file.Name
                    Path = $file.FullName
                    UnusedVariables = $issues | ForEach-Object { $_.Extent.Text }
                    Count = $issues.Count
                }
                $totalUnusedVars += $issues.Count
            }
        } catch {
            Write-ValidationLog "Error analyzing $($file.Name): $($_.Exception.Message)" -Level ERROR
        }
    }
    
    Write-ValidationLog "Found $totalUnusedVars unused variables in $($affectedFiles.Count) files"
    foreach ($fileInfo in $affectedFiles) {
        Write-ValidationLog "  $($fileInfo.File): $($fileInfo.Count) unused variables" -Level WARN
        foreach ($var in $fileInfo.UnusedVariables) {
            Write-ValidationLog "    - $var" 
        }
    }
}

function Test-UnusedParameters {
    Write-ValidationLog "`n=== UNUSED PARAMETERS ANALYSIS ===" -Level HEADER
    
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-ValidationLog "PSScriptAnalyzer not available - cannot analyze unused parameters" -Level WARN
        return
    }
    
    $files = Get-ChildItem -Path "$env:PROJECT_ROOT/pwsh" -Recurse -Filter "*.ps1" | 
        Where-Object { $_.Name -notlike "*.Tests.ps1" -and $_.Name -ne "Fix-TestFailures.ps1" }
    
    $totalUnusedParams = 0
    $affectedFiles = @()
    
    foreach ($file in $files) {
        try {
            $issues = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule PSReviewUnusedParameter
            
            if ($issues.Count -gt 0) {
                $affectedFiles += [PSCustomObject]@{
                    File = $file.Name
                    Path = $file.FullName
                    UnusedParameters = $issues | ForEach-Object { $_.Extent.Text }
                    Count = $issues.Count
                }
                $totalUnusedParams += $issues.Count
            }
        } catch {
            Write-ValidationLog "Error analyzing $($file.Name): $($_.Exception.Message)" -Level ERROR
        }
    }
    
    Write-ValidationLog "Found $totalUnusedParams unused parameters in $($affectedFiles.Count) files"
    foreach ($fileInfo in $affectedFiles) {
        Write-ValidationLog "  $($fileInfo.File): $($fileInfo.Count) unused parameters" -Level WARN
        foreach ($param in $fileInfo.UnusedParameters) {
            Write-ValidationLog "    - $param"
        }
    }
}

function Test-ModuleStructureConflicts {
    Write-ValidationLog "`n=== MODULE STRUCTURE CONFLICTS ===" -Level HEADER
    
    $srcModulesPath = "$env:PROJECT_ROOT/src/pwsh/modules"
    $mainModulesPath = "$env:PROJECT_ROOT/pwsh/modules"
    
    if (Test-Path $srcModulesPath) {
        Write-ValidationLog "CONFLICT FOUND: src/pwsh/modules directory exists" -Level WARN
        Write-ValidationLog "  From: $srcModulesPath" -Level WARN
        Write-ValidationLog "  Will be: REMOVED (after moving unique modules to main location)" -Level WARN
        
        # Check for unique modules
        $srcModules = Get-ChildItem $srcModulesPath -Directory -ErrorAction SilentlyContinue
        $uniqueModules = @()
        
        foreach ($srcModule in $srcModules) {
            $mainModulePath = Join-Path $mainModulesPath $srcModule.Name
            if (-not (Test-Path $mainModulePath)) {
                $uniqueModules += $srcModule.Name
            }
        }
        
        if ($uniqueModules.Count -gt 0) {
            Write-ValidationLog "  Unique modules to be moved:" -Level WARN
            $uniqueModules | ForEach-Object { Write-ValidationLog "    - $_" }
        } else {
            Write-ValidationLog "  No unique modules found - directory will be simply removed"
        }
    } else {
        Write-ValidationLog "No module structure conflicts found" -Level SUCCESS
    }
}

function Test-MissingModuleManifests {
    Write-ValidationLog "`n=== MISSING MODULE MANIFESTS ===" -Level HEADER
    
    $moduleDirectories = Get-ChildItem -Path "$env:PROJECT_ROOT/pwsh/modules" -Directory
    $missingManifests = @()
    
    foreach ($moduleDir in $moduleDirectories) {
        $manifestPath = Join-Path $moduleDir.FullName "$($moduleDir.Name).psd1"
        
        if (-not (Test-Path $manifestPath)) {
            $missingManifests += $moduleDir.Name
            
            # Try to detect functions
            $moduleFilePath = Join-Path $moduleDir.FullName "$($moduleDir.Name).psm1"
            $publicPath = Join-Path $moduleDir.FullName "Public"
            $functions = @()
            
            if (Test-Path $publicPath) {
                $functions = Get-ChildItem $publicPath -Filter "*.ps1" | ForEach-Object { $_.BaseName }
            }
            
            Write-ValidationLog "  $($moduleDir.Name) - MISSING manifest" -Level WARN
            if ($functions.Count -gt 0) {
                Write-ValidationLog "    Functions detected: $($functions -join ', ')"
            } else {
                Write-ValidationLog "    No functions detected in Public folder"
            }
        }
    }
    
    if ($missingManifests.Count -eq 0) {
        Write-ValidationLog "All modules have manifests" -Level SUCCESS
    } else {
        Write-ValidationLog "Found $($missingManifests.Count) modules without manifests:" -Level WARN
        $missingManifests | ForEach-Object { Write-ValidationLog "  - $_" }
    }
}

function Test-TestHelpers {
    Write-ValidationLog "`n=== TEST HELPERS STATUS ===" -Level HEADER
    
    $testHelpersPath = "$env:PROJECT_ROOT/tests/helpers/TestHelpers.ps1"
    
    if (-not (Test-Path $testHelpersPath)) {
        Write-ValidationLog "TestHelpers.ps1 is MISSING" -Level WARN
        Write-ValidationLog "  Will create: $testHelpersPath" -Level WARN
    } elseif ((Get-Item $testHelpersPath).Length -eq 0) {
        Write-ValidationLog "TestHelpers.ps1 is EMPTY" -Level WARN  
        Write-ValidationLog "  Will populate: $testHelpersPath" -Level WARN
    } else {
        Write-ValidationLog "TestHelpers.ps1 exists and has content" -Level SUCCESS
        $content = Get-Content $testHelpersPath -Raw
        Write-ValidationLog "  Size: $((Get-Item $testHelpersPath).Length) bytes"
        
        # Check if it has the required functions
        $requiredFunctions = @('Import-TestModule', 'Test-ModuleStructure', 'Test-PowerShellSyntax', 'Get-TestConfiguration')
        $missingFunctions = @()
        
        foreach ($func in $requiredFunctions) {
            if ($content -notmatch "function $func") {
                $missingFunctions += $func
            }
        }
        
        if ($missingFunctions.Count -gt 0) {
            Write-ValidationLog "  Missing functions: $($missingFunctions -join ', ')" -Level WARN
        }
    }
}

function Test-EnvironmentIssues {
    Write-ValidationLog "`n=== ENVIRONMENT ISSUES ===" -Level HEADER
    
    # Check PSModulePath
    $currentPSModulePath = $env:PSModulePath
    if ($currentPSModulePath -notlike "*$env:PWSH_MODULES_PATH*") {
        Write-ValidationLog "PSModulePath missing project modules" -Level WARN
        Write-ValidationLog "  Current: $currentPSModulePath"
        Write-ValidationLog "  Will add: $env:PWSH_MODULES_PATH"
    } else {
        Write-ValidationLog "PSModulePath includes project modules" -Level SUCCESS
    }
    
    # Check test configuration files
    $testConfigFiles = @(
        "$env:PROJECT_ROOT/tests/config/TestConfiguration.psd1",
        "$env:PROJECT_ROOT/TestConfiguration.psd1"
    )
    
    $configFilesNeedingUpdate = @()
    
    foreach ($configFile in $testConfigFiles) {
        if (Test-Path $configFile) {
            $content = Get-Content $configFile -Raw
            if ($content -match 'src/pwsh/modules') {
                $configFilesNeedingUpdate += $configFile
                Write-ValidationLog "Config file needs path update: $configFile" -Level WARN
                Write-ValidationLog "  Will change: src/pwsh/modules → pwsh/modules"
            }
        }
    }
    
    if ($configFilesNeedingUpdate.Count -eq 0) {
        Write-ValidationLog "No configuration files need path updates" -Level SUCCESS
    }
}

function Show-Summary {
    Write-ValidationLog "`n=== SUMMARY OF CHANGES ===" -Level HEADER
    
    Write-ValidationLog "The Fix-TestFailures script will:"
    Write-ValidationLog "1. Remove conflicting src/pwsh/modules directory (if exists)"
    Write-ValidationLog "2. Create missing module manifests with detected functions"
    Write-ValidationLog "3. Create/populate TestHelpers.ps1 with standard functions"
    Write-ValidationLog "4. Update configuration files to use correct module paths"
    Write-ValidationLog "5. Add diagnostic comments to unused variables"
    Write-ValidationLog "6. Add SuppressMessage attributes to unused parameters"
    Write-ValidationLog "7. Add project modules to PSModulePath if missing"
    
    Write-ValidationLog "`nThese changes should address the test failures related to:"
    Write-ValidationLog "- Module structure conflicts"
    Write-ValidationLog "- Missing module manifests" 
    Write-ValidationLog "- Empty TestHelpers.ps1"
    Write-ValidationLog "- Incorrect module paths in configuration"
    Write-ValidationLog "- PSScriptAnalyzer warnings about unused variables/parameters"
}

# Run all validations
Write-ValidationLog "=== FIX-TESTFAILURES VALIDATION ===" -Level HEADER
Write-ValidationLog "Analyzing current state before applying fixes..."

Test-ModuleStructureConflicts
Test-MissingModuleManifests  
Test-TestHelpers
Test-EnvironmentIssues
Test-UnusedVariables
Test-UnusedParameters
Show-Summary

Write-ValidationLog "`nValidation complete. Run Fix-TestFailures.ps1 to apply these changes." -Level SUCCESS

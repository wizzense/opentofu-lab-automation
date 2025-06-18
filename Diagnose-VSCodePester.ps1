#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Comprehensive diagnostic for VS Code Pester integration issues

.DESCRIPTION
    This script identifies and fixes the root causes of VS Code Pester popup errors
    and provides detailed diagnostics for test execution problems.
#>

param(
    [switch]$Fix,
    [switch]$Verbose
)

Write-Host "🔍 VS Code Pester Integration Diagnostic" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

$issues = @()
$fixes = @()

# Test 1: PowerShell Version Compatibility
Write-Host "`n1. PowerShell Version Check" -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 7) {
    $issues += "PowerShell version $psVersion is below required minimum (7.0)"
} else {
    Write-Host "   ✓ PowerShell $psVersion (compatible)" -ForegroundColor Green
}

# Test 2: Pester Module Status
Write-Host "`n2. Pester Module Analysis" -ForegroundColor Yellow
$pesterModules = Get-Module -ListAvailable -Name Pester
$pesterLoaded = Get-Module -Name Pester

if ($pesterModules.Count -eq 0) {
    $issues += "No Pester module found"
    $fixes += "Install-Module -Name Pester -Force"
} else {
    $latestPester = $pesterModules | Sort-Object Version -Descending | Select-Object -First 1
    $oldPester = $pesterModules | Where-Object { $_.Version.Major -lt 5 }
    
    Write-Host "   Available versions: $($pesterModules.Version -join ', ')" -ForegroundColor Gray
    
    if ($oldPester) {
        $issues += "Old Pester versions detected: $($oldPester.Version -join ', ')"
        $fixes += "Remove old Pester modules and reinstall Pester 5.x"
    }
    
    if ($pesterLoaded) {
        Write-Host "   ✓ Pester $($pesterLoaded.Version) loaded" -ForegroundColor Green
    } else {
        $issues += "Pester module not loaded"
    }
}

# Test 3: VS Code Settings Validation
Write-Host "`n3. VS Code Configuration Check" -ForegroundColor Yellow
$vscodeSettings = @(
    ".vscode/settings.json",
    "configs/.vscode/settings.json"
)

$settingsFound = $false
foreach ($settingsPath in $vscodeSettings) {
    if (Test-Path $settingsPath) {
        $settingsFound = $true
        Write-Host "   ✓ Found: $settingsPath" -ForegroundColor Green
        
        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            
            # Check Pester-specific settings
            $pesterSettings = @(
                'pester.enableCodeLens',
                'pester.testFilePath',
                'pester.configurationFilePath'
            )
            
            $missingSettings = @()
            foreach ($setting in $pesterSettings) {
                $keys = $setting.Split('.')
                $value = $settings
                foreach ($key in $keys) {
                    if ($value.PSObject.Properties.Name -contains $key) {
                        $value = $value.$key
                    } else {
                        $missingSettings += $setting
                        break
                    }
                }
            }
            
            if ($missingSettings.Count -gt 0) {
                $issues += "Missing VS Code Pester settings: $($missingSettings -join ', ')"
            } else {
                Write-Host "   ✓ Pester settings configured" -ForegroundColor Green
            }
            
        } catch {
            $issues += "VS Code settings file has syntax errors: $settingsPath"
        }
    }
}

if (-not $settingsFound) {
    $issues += "No VS Code settings found"
    $fixes += "Copy configs/.vscode to .vscode in project root"
}

# Test 4: Pester Configuration File
Write-Host "`n4. Pester Configuration Analysis" -ForegroundColor Yellow
$pesterConfigPaths = @(
    "tests/config/PesterConfiguration.psd1",
    "PesterConfiguration.psd1",
    "tests/PesterConfiguration.psd1"
)

$configFound = $false
foreach ($configPath in $pesterConfigPaths) {
    if (Test-Path $configPath) {
        $configFound = $true
        Write-Host "   ✓ Found: $configPath" -ForegroundColor Green
        
        try {
            $configData = Import-PowerShellDataFile $configPath
            
            # Validate required configuration sections
            $requiredSections = @('Run', 'TestResult', 'Output')
            $missingSections = @()
            
            foreach ($section in $requiredSections) {
                if (-not $configData.ContainsKey($section)) {
                    $missingSections += $section
                }
            }
            
            if ($missingSections.Count -gt 0) {
                $issues += "Pester config missing sections: $($missingSections -join ', ')"
            } else {
                Write-Host "   ✓ Configuration structure valid" -ForegroundColor Green
            }
            
            # Check for problematic settings
            if ($configData.CodeCoverage -and $configData.CodeCoverage.Enabled -eq $true) {
                $issues += "CodeCoverage enabled - can cause hangs in VS Code"
                $fixes += "Disable CodeCoverage in Pester configuration"
            }
            
        } catch {
            $issues += "Pester configuration file has syntax errors: $configPath"
        }
        break
    }
}

if (-not $configFound) {
    $issues += "No Pester configuration file found"
    $fixes += "Create tests/config/PesterConfiguration.psd1"
}

# Test 5: Test Directory Structure
Write-Host "`n5. Test Directory Structure" -ForegroundColor Yellow
$requiredDirs = @(
    'tests',
    'tests/unit',
    'tests/integration', 
    'tests/results',
    'tests/config'
)

$missingDirs = @()
foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "   ✓ $dir" -ForegroundColor Green
    } else {
        $missingDirs += $dir
    }
}

if ($missingDirs.Count -gt 0) {
    $issues += "Missing test directories: $($missingDirs -join ', ')"
    $fixes += "Create missing test directories"
}

# Test 6: Test File Analysis
Write-Host "`n6. Test File Analysis" -ForegroundColor Yellow
$testFiles = Get-ChildItem -Path "tests" -Recurse -Filter "*.Tests.ps1" -ErrorAction SilentlyContinue
$problematicTests = @()

if ($testFiles.Count -gt 0) {
    Write-Host "   Found $($testFiles.Count) test files" -ForegroundColor Green
    
    # Check for common syntax issues
    foreach ($testFile in ($testFiles | Select-Object -First 5)) {  # Sample first 5
        try {
            $content = Get-Content $testFile.FullName -Raw -ErrorAction Stop
            if (-not $content.Contains("Describe")) {
                $problematicTests += $testFile.Name
            }
        } catch {
            $problematicTests += $testFile.Name
        }
    }
    
    if ($problematicTests.Count -gt 0) {
        $issues += "Test files with potential issues: $($problematicTests[0..2] -join ', ')$(if($problematicTests.Count -gt 3){'...'})"
    }
} else {
    $issues += "No test files found"
}

# Test 7: Environment Variables
Write-Host "`n7. Environment Variables Check" -ForegroundColor Yellow
$requiredEnvVars = @(
    'PROJECT_ROOT',
    'PWSH_MODULES_PATH'
)

foreach ($envVar in $requiredEnvVars) {
    $value = [Environment]::GetEnvironmentVariable($envVar)
    if ($value) {
        Write-Host "   ✓ $envVar = $value" -ForegroundColor Green
    } else {
        $issues += "Missing environment variable: $envVar"
        $fixes += "Set environment variable $envVar"
    }
}

# Test 8: Module Path Validation
Write-Host "`n8. Module Path Validation" -ForegroundColor Yellow
$modulePath = $env:PWSH_MODULES_PATH
if ($modulePath -and (Test-Path $modulePath)) {
    $modules = Get-ChildItem $modulePath -Directory -ErrorAction SilentlyContinue
    Write-Host "   ✓ Found $($modules.Count) modules in $modulePath" -ForegroundColor Green
    
    if ($Verbose) {
        $modules | ForEach-Object {
            Write-Host "     - $($_.Name)" -ForegroundColor Gray
        }
    }
} else {
    $issues += "Module path not found or inaccessible: $modulePath"
}

# Summary
Write-Host "`n📊 DIAGNOSTIC SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

if ($issues.Count -eq 0) {
    Write-Host "✅ No issues detected! VS Code Pester integration should work correctly." -ForegroundColor Green
} else {
    Write-Host "❌ Found $($issues.Count) issue(s):" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "   • $_" -ForegroundColor Red }
    
    if ($fixes.Count -gt 0) {
        Write-Host "`n🔧 SUGGESTED FIXES:" -ForegroundColor Yellow
        $fixes | ForEach-Object { Write-Host "   • $_" -ForegroundColor Yellow }
    }
    
    if ($Fix) {
        Write-Host "`n🛠️  APPLYING AUTOMATIC FIXES..." -ForegroundColor Cyan
        
        # Fix 1: Create missing directories
        foreach ($dir in $missingDirs) {
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            Write-Host "   ✓ Created directory: $dir" -ForegroundColor Green
        }
        
        # Fix 2: Copy VS Code settings if needed
        if (-not (Test-Path ".vscode/settings.json") -and (Test-Path "configs/.vscode/settings.json")) {
            Copy-Item -Path "configs/.vscode" -Destination ".vscode" -Recurse -Force
            Write-Host "   ✓ Copied VS Code settings to root" -ForegroundColor Green
        }
        
        # Fix 3: Disable problematic CodeCoverage if needed
        $configPath = "tests/config/PesterConfiguration.psd1"
        if ((Test-Path $configPath)) {
            $configContent = Get-Content $configPath -Raw
            if ($configContent -match "Enabled\s*=\s*\$true" -and $configContent -match "CodeCoverage") {
                $configContent = $configContent -replace "(CodeCoverage\s*=\s*@{[^}]*Enabled\s*=\s*)\$true", '${1}$false'
                Set-Content -Path $configPath -Value $configContent -Encoding UTF8
                Write-Host "   ✓ Disabled CodeCoverage in Pester configuration" -ForegroundColor Green
            }
        }
        
        Write-Host "`n✅ Automatic fixes applied. Please restart VS Code for changes to take effect." -ForegroundColor Green
    }
}

Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "   • Restart VS Code after configuration changes" -ForegroundColor Gray
Write-Host "   • Use Ctrl+Shift+P → 'Pester: Discover Tests' to refresh" -ForegroundColor Gray
Write-Host "   • Check VS Code Output panel for Pester extension logs" -ForegroundColor Gray
Write-Host "   • Disable CodeCoverage during development to prevent hangs" -ForegroundColor Gray

return $(if ($issues.Count -eq 0) { 0 } else { 1 })


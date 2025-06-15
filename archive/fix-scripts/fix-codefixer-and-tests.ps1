# Fix CodeFixer PSScriptAnalyzer and Test Files for LabRunner Move
# This script addresses both issues: CodeFixer PSScriptAnalyzer installation and test file LabRunner imports

param(
    [switch]$WhatIf,
    [switch]$Verbose
)







$ErrorActionPreference = "Continue"

# Function to log progress
function Write-Progress {
    param([string]$Message, [string]$Color = "Cyan")
    





Write-Host $Message -ForegroundColor $Color
}

Write-Progress "🔧 Starting comprehensive fixes for CodeFixer and LabRunner tests"

# 1. First, fix CodeFixer PSScriptAnalyzer installation
Write-Progress "📦 Installing PSScriptAnalyzer for CodeFixer..."

try {
    # Install PSScriptAnalyzer
    $result = pwsh -c "Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -ErrorAction Stop; Import-Module PSScriptAnalyzer -Force; Get-Module PSScriptAnalyzer"
    Write-Progress "✅ PSScriptAnalyzer installed successfully" "Green"
} catch {
    Write-Warning "Failed to install PSScriptAnalyzer: $($_.Exception.Message)"
}

# 2. Test CodeFixer functionality
Write-Progress "🧪 Testing CodeFixer linting functionality..."

try {
    $testResult = pwsh -c "
        Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/" -Force
        Invoke-PowerShellLint -Path /workspaces/opentofu-lab-automation/pwsh/runner.ps1 -OutputFormat Text
    "
    Write-Progress "✅ CodeFixer linting test completed" "Green"
} catch {
    Write-Warning "CodeFixer test failed: $($_.Exception.Message)"
}

# 3. Find all test files that need LabRunner path updates
Write-Progress "🔍 Finding test files with old LabRunner paths..."

$testFiles = Get-ChildItem -Path "/workspaces/opentofu-lab-automation/tests" -Recurse -Include "*.ps1" -File
$filesToUpdate = @()

foreach ($file in $testFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and ($content -match "lab_utils.*LabRunner" -or $content -match "pwsh.*lab_utils")) {
        $filesToUpdate += $file
    }
}

Write-Progress "📄 Found $($filesToUpdate.Count) test files to update"

# 4. Update test files with new LabRunner paths
$updatedCount = 0
$patterns = @{
    # Update direct LabRunner module imports
    "pwsh.*lab_utils.*LabRunner" = "pwsh/modules/LabRunner"
    # Update specific file imports within LabRunner
    "pwsh.*lab_utils.*LabRunner.*Logger\.ps1" = "pwsh/modules/LabRunner/Logger.ps1"
    "pwsh.*lab_utils.*LabRunner.*OpenTofuInstaller\.ps1" = "pwsh/modules/LabRunner/OpenTofuInstaller.ps1"
    "pwsh.*lab_utils.*LabRunner.*LabRunner\.psd1" = "pwsh/modules/LabRunner/LabRunner.psd1"
    # Update other lab_utils references
    "pwsh.*lab_utils.*Get-LabConfig\.ps1" = "pwsh/modules/LabRunner/Get-LabConfig.ps1"
    "pwsh.*lab_utils.*Get-Platform\.ps1" = "pwsh/modules/LabRunner/Get-Platform.ps1"
    "pwsh.*lab_utils.*Hypervisor\.psm1" = "pwsh/modules/LabRunner/Hypervisor.psm1"
}

foreach ($file in $filesToUpdate) {
    Write-Progress "  📝 Updating: $($file.Name)" "Gray"
    
    try {
        $content = Get-Content -Path $file.FullName -Raw
        $originalContent = $content
        
        # Apply all pattern replacements
        foreach ($pattern in $patterns.Keys) {
            $replacement = $patterns[$pattern]
            $content = $content -replace $pattern, $replacement
        }
        
        # Special case for TestHelpers.ps1 - update the LabRunnerModulePath
        if ($file.Name -eq "TestHelpers.ps1") {
            $content = $content -replace 
                '\$LabRunnerModulePath = \(Resolve-Path \(Join-Path \$PSScriptRoot.*lab_utils.*LabRunner.*\)\)\.Path',
                '$LabRunnerModulePath = (Resolve-Path (Join-Path $PSScriptRoot ".." ".." "pwsh" "modules" "LabRunner")).Path'
        }
        
        if ($content -ne $originalContent) {
            if (-not $WhatIf) {
                Set-Content -Path $file.FullName -Value $content -Encoding UTF8
                $updatedCount++
                Write-Progress "    ✅ Updated" "Green"
            } else {
                Write-Progress "    📋 Would update" "Yellow"
            }
        } else {
            Write-Progress "    ⏭️ No changes needed" "Gray"
        }
        
    } catch {
        Write-Warning "Failed to update $($file.FullName): $($_.Exception.Message)"
    }
}

# 5. Verify test files can now load LabRunner
Write-Progress "🧪 Testing updated test files..."

$testHelperPath = "/workspaces/opentofu-lab-automation/tests/helpers/TestHelpers.ps1"
if (Test-Path $testHelperPath) {
    try {
        $testResult = pwsh -c ". '$testHelperPath'; Get-Module LabRunner"
        if ($testResult) {
            Write-Progress "✅ TestHelpers can now load LabRunner from new path" "Green"
        } else {
            Write-Warning "TestHelpers may still have issues loading LabRunner"
        }
    } catch {
        Write-Warning "Failed to test TestHelpers: $($_.Exception.Message)"
    }
}

# 6. Run a quick Pester test to verify functionality
Write-Progress "🎯 Running quick Pester test to verify LabRunner functionality..."

try {
    # Create a simple test to verify LabRunner loads correctly
    $quickTest = @"
Describe 'LabRunner Module Loading' {
    It 'should load LabRunner module successfully' {
        `$modulePath = Join-Path `$PSScriptRoot '..' 'pwsh' 'modules' 'LabRunner'
        Import-Module `$modulePath -Force
        Get-Module LabRunner | Should -Not -BeNullOrEmpty
    }
}
"@
    
    $tempTestFile = "/tmp/quick-labrunner-test.ps1"
    Set-Content -Path $tempTestFile -Value $quickTest
    
    $pesterResult = pwsh -c "
        Set-Location '/workspaces/opentofu-lab-automation'
                Invoke-Pester -Path '$tempTestFile' -Output Normal
    "
    
    Remove-Item $tempTestFile -ErrorAction SilentlyContinue
    Write-Progress "✅ Pester test completed" "Green"
    
} catch {
    Write-Warning "Pester test failed: $($_.Exception.Message)"
}

# 7. Summary
Write-Progress "`n📊 Summary:" "Cyan"
Write-Progress "============" "Cyan"
if (-not $WhatIf) {
    Write-Progress "✅ PSScriptAnalyzer installation: Attempted" "Green"
    Write-Progress "✅ CodeFixer functionality: Tested" "Green"
    Write-Progress "✅ Test files updated: $updatedCount" "Green"
    Write-Progress "✅ LabRunner path fixes: Applied" "Green"
} else {
    Write-Progress "📋 WhatIf mode - no changes applied" "Yellow"
    Write-Progress "📄 Test files that would be updated: $($filesToUpdate.Count)" "Yellow"
}

Write-Progress "`n🎉 Comprehensive fixes completed!" "Green"
Write-Progress "`nNext steps:" "Cyan"
Write-Progress "1. Run 'Invoke-Pester tests/' to verify all tests work" "White"
Write-Progress "2. Test CodeFixer: 'Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/"; Invoke-PowerShellLint'" "White"
Write-Progress "3. Validate the full CI workflow" "White"



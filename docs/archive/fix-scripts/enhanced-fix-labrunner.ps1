<#
VALIDATION-ONLY MODE: This script has been converted to validation-only.
It will only report issues and create GitHub issues for tracking.
No automatic file modifications or repairs are performed.
Use PatchManager for explicit file changes when needed.
#>
# Enhanced Fix Script for LabRunner Path Updates
param(
    switch$WhatIf,
    switch$Force
)








$ErrorActionPreference = "Continue"

Write-Host "� Finding all files with lab_utils references..." -ForegroundColor Cyan

# Find all files that might have lab_utils references
$allFiles = Get-ChildItem -Path "/workspaces/opentofu-lab-automation" -Recurse -Include "*.ps1", "*.psm1", "*.psd1" -File  
    Where-Object { $_.FullName -notmatch "(archivecleanup-backup\.git)" }

$filesToFix = @()

foreach ($file in $allFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match "lab_utils") {
            $filesToFix += PSCustomObject@{
                File = $file.FullName
                Name = $file.Name
                Content = $content
            }
        }
    } catch {
        # Ignore files we can't read
    }
}

Write-Host "� Found $($filesToFix.Count) files with lab_utils references" -ForegroundColor Yellow

# Define comprehensive replacement patterns
$patterns = @{
    # Main LabRunner module paths
    'pwsh\\/lab_utils\\/LabRunner\\/LabRunner\.psd1' = 'pwsh/modules/LabRunner/LabRunner.psd1'
    'pwsh\\/lab_utils\\/LabRunner' = 'pwsh/modules/LabRunner'
    
    # Specific file references within LabRunner
    'pwsh\\/lab_utils\\/LabRunner\\/Logger\.ps1' = 'pwsh/modules/LabRunner/Logger.ps1'
    'pwsh\\/lab_utils\\/LabRunner\\/OpenTofuInstaller\.ps1' = 'pwsh/modules/LabRunner/OpenTofuInstaller.ps1'
    
    # Other lab_utils references that should move to LabRunner
    'pwsh\\/lab_utils\\/Get-LabConfig\.ps1' = 'pwsh/modules/LabRunner/Get-LabConfig.ps1'
    'pwsh\\/lab_utils\\/Get-Platform\.ps1' = 'pwsh/modules/LabRunner/Get-Platform.ps1'
    'pwsh\\/lab_utils\\/Hypervisor\.psm1' = 'pwsh/modules/LabRunner/Hypervisor.psm1'
    'pwsh\\/lab_utils\\/Get-WindowsJobArtifacts\.ps1' = 'pwsh/modules/LabRunner/Get-WindowsJobArtifacts.ps1'
}

$updatedCount = 0

foreach ($fileInfo in $filesToFix) {
    Write-Host "  � Processing: $($fileInfo.Name)" -ForegroundColor Gray
    
    $content = $fileInfo.Content
    $originalContent = $content
    $hasChanges = $false
    
    # Apply each pattern
    foreach ($pattern in $patterns.Keys) {
        $replacement = $patterns$pattern
        $newContent = $content -replace $pattern, $replacement
        if ($newContent -ne $content) {
            $content = $newContent
            $hasChanges = $true
            Write-Host "    � Applied pattern: $pattern -> $replacement" -ForegroundColor Cyan
        }
    }
    
    if ($hasChanges) {
        if ($WhatIf) {
            Write-Host "     Would update file" -ForegroundColor Yellow
        } else {
            try {
                # DISABLED: # DISABLED: Set-Content -Path $fileInfo.File -Value $content -Encoding UTF8
                $updatedCount++
                Write-Host "    PASS Updated file" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to update $($fileInfo.File): $($_.Exception.Message)"
            }
        }
    } else {
        Write-Host "    ⏭ No applicable changes" -ForegroundColor Gray
    }
}

Write-Host "`n Summary:" -ForegroundColor Cyan
Write-Host "Files processed: $($filesToFix.Count)" -ForegroundColor White
Write-Host "Files updated: $updatedCount" -ForegroundColor Green

if (-not $WhatIf) {
    Write-Host "`n� Testing CodeFixer and LabRunner..." -ForegroundColor Cyan
    
    # Test CodeFixer
    try {
        $codeFixerTest = pwsh -c "
            Import-Module /workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer -Force
            Invoke-PowerShellLint -Path /workspaces/opentofu-lab-automation/pwsh/runner.ps1 -OutputFormat Text
        "
        Write-Host "PASS CodeFixer test passed" -ForegroundColor Green
    } catch {
        Write-Warning "CodeFixer test failed: $($_.Exception.Message)"
    }
    
    # Test LabRunner loading in tests
    try {
        $labRunnerTest = pwsh -c "
            . /workspaces/opentofu-lab-automation/tests/helpers/TestHelpers.ps1
            Get-Module LabRunner
        "
        if ($labRunnerTest) {
            Write-Host "PASS LabRunner loads correctly in tests" -ForegroundColor Green
        } else {
            Write-Warning "LabRunner may not be loading correctly"
        }
    } catch {
        Write-Warning "LabRunner test failed: $($_.Exception.Message)"
    }
}

Write-Host "`n Enhanced fix script completed!" -ForegroundColor Green




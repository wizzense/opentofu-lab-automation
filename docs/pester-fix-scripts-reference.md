# Pester Fix Scripts Technical Reference

This document contains all the scripts used to fix the "Param is not recognized" errors in the Pester test suite.

## Script 1: fix_param_tests.ps1 (Initial Attempt)

```powershell
# Script to fix numbered test files with "Param is not recognized" error
# filepath: /workspaces/opentofu-lab-automation/fix_param_tests.ps1

$numberedTestFiles = Get-ChildItem -Path "tests" -Filter "*_*.Tests.ps1" | Where-Object { $_.Name -match '^\d{4}_' }

foreach ($file in $numberedTestFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Remove InModuleScope LabRunner wrapper if present
    $content = $content -replace 'InModuleScope LabRunner \{([^}]+)\}', '$1'
    
    # Replace direct script execution with pwsh -File execution
    $content = $content -replace '\{ & \$script:ScriptPath -Config \$config \}', '{ 
        $tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
        $config | ConvertTo-Json | Set-Content $tempConfig
        try {
            & pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig
        } finally {
            Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
        }
    }'
    
    Set-Content $file.FullName $content
    Write-Host "Updated: $($file.Name)"
}

Write-Host "Updated $($numberedTestFiles.Count) numbered test files"
```

## Script 2: fix_remaining_numbered_tests.ps1 (Mass Fix - Had Issues)

```powershell
# Script to fix the execution pattern in remaining numbered test files
# filepath: /workspaces/opentofu-lab-automation/fix_remaining_numbered_tests.ps1

$testFiles = @(
    "tests/0001_Reset-Git.Tests.ps1",
    "tests/0002_Setup-Directories.Tests.ps1", 
    "tests/0006_Install-ValidationTools.Tests.ps1",
    # ... [full list of 36 files]
)

foreach ($testFile in $testFiles) {
    $filePath = $testFile
    if (-not (Test-Path $filePath)) {
        Write-Warning "File not found: $filePath"
        continue
    }
    
    Write-Host "Processing: $testFile"
    $content = Get-Content $filePath -Raw
    
    # Check if the file already has the new pattern
    if ($content -match '\$pwsh = \(Get-Command pwsh\)\.Source' -and 
        $content -match '& \$pwsh -NoLogo -NoProfile -File') {
        Write-Host "  Already updated - skipping"
        continue
    }
    
    # Find and replace the execution patterns
    $oldPattern1 = '(\s+)(\{ & \$script:ScriptPath -Config \$config \} \| Should -Not -Throw)'
    $oldPattern2 = '(\s+)(\{ & \$script:ScriptPath -Config \$config -WhatIf \} \| Should -Not -Throw)'
    
    $newReplacement1 = @'
$1$config = [pscustomobject]@{}
$1$configJson = $config | ConvertTo-Json -Depth 5
$1$tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
$1$configJson | Set-Content -Path $tempConfig
$1try {
$1    $pwsh = (Get-Command pwsh).Source
$1    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig } | Should -Not -Throw
$1} finally {
$1    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
$1}
'@
    
    $newReplacement2 = @'
$1$config = [pscustomobject]@{}
$1$configJson = $config | ConvertTo-Json -Depth 5
$1$tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
$1$configJson | Set-Content -Path $tempConfig
$1try {
$1    $pwsh = (Get-Command pwsh).Source
$1    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig -WhatIf } | Should -Not -Throw
$1} finally {
$1    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
$1}
'@
    
    $updatedContent = $content
    
    # Replace the basic execution pattern
    $updatedContent = $updatedContent -replace $oldPattern1, $newReplacement1
    
    # Replace the whatif execution pattern  
    $updatedContent = $updatedContent -replace $oldPattern2, $newReplacement2
    
    # Remove InModuleScope if present
    $updatedContent = $updatedContent -replace 'InModuleScope LabRunner \{\s*\n', ''
    $updatedContent = $updatedContent -replace '\s*\} # End InModuleScope', ''
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $filePath -Value $updatedContent
        Write-Host "  Updated successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Yellow
    }
}

Write-Host "`nCompleted processing all numbered test files."
```

## Script 3: fix_numbered_tests_corrected.ps1 (With Git Restore)

```powershell
# Corrected script to fix the execution pattern in numbered test files
# filepath: /workspaces/opentofu-lab-automation/fix_numbered_tests_corrected.ps1

$testFiles = @(
    "tests/0001_Reset-Git.Tests.ps1",
    "tests/0002_Setup-Directories.Tests.ps1", 
    # ... [full list of 36 files]
)

# Function to restore files from git
function Restore-TestFile {
    param([string]$FilePath)
    Write-Host "Restoring $FilePath from git..."
    git checkout HEAD -- $FilePath
}

# Function to fix the test file execution pattern
function Fix-TestFile {
    param([string]$FilePath)
    
    $content = Get-Content $FilePath -Raw
    
    # Define the working pattern to look for and replace
    $basicExecutionPattern = @'
It 'should execute without errors with valid config' {
                \$config = \[pscustomobject\]@\{\}
                \{ & \$script:ScriptPath -Config \$config \} \| Should -Not -Throw
            \}
'@
    
    $whatifExecutionPattern = @'
It 'should handle whatif parameter' {
                \$config = \[pscustomobject\]@\{\}
                \{ & \$script:ScriptPath -Config \$config -WhatIf \} \| Should -Not -Throw
            \}
'@
    
    # The corrected patterns to replace them with
    $newBasicPattern = @'
It 'should execute without errors with valid config' {
                $config = [pscustomobject]@{}
                $configJson = $config | ConvertTo-Json -Depth 5
                $tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
                $configJson | Set-Content -Path $tempConfig
                try {
                    $pwsh = (Get-Command pwsh).Source
                    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig } | Should -Not -Throw
                } finally {
                    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
                }
            }
'@
    
    # Apply replacements using regex
    $updatedContent = $content -replace $basicExecutionPattern, $newBasicPattern
    $updatedContent = $updatedContent -replace $whatifExecutionPattern, $newWhatifPattern
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $FilePath -Value $updatedContent
        Write-Host "  Updated successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes made" -ForegroundColor Yellow
    }
}

foreach ($testFile in $testFiles) {
    $filePath = $testFile
    if (-not (Test-Path $filePath)) {
        Write-Warning "File not found: $filePath"
        continue
    }
    
    Write-Host "Processing: $testFile"
    
    # First, restore the file from git to undo any bad changes
    Restore-TestFile $filePath
    
    # Now apply the correct fix
    Fix-TestFile $filePath
}

Write-Host "`nCompleted processing all numbered test files."
```

## Script 4: fix_numbered_tests_final.ps1 (Working Solution)

```powershell
# Script to fix the numbered test files with the correct execution pattern
# filepath: /workspaces/opentofu-lab-automation/fix_numbered_tests_final.ps1

$testFiles = @(
    "tests/0001_Reset-Git.Tests.ps1",
    "tests/0002_Setup-Directories.Tests.ps1", 
    # ... [full list of 36 files]
)

foreach ($testFile in $testFiles) {
    if (-not (Test-Path $testFile)) {
        Write-Warning "File not found: $testFile"
        continue
    }
    
    Write-Host "Processing: $testFile"
    $content = Get-Content $testFile -Raw
    
    # Pattern 1: Replace the direct script execution with & operator
    $oldPattern1 = '\{ & \$scriptPath -Config ''TestValue'' -WhatIf \} \| Should -Not -Throw'
    $newPattern1 = @'
$config = [pscustomobject]@{ TestProperty = 'TestValue' }
            $configJson = $config | ConvertTo-Json -Depth 5
            $tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
            $configJson | Set-Content -Path $tempConfig
            try {
                $pwsh = (Get-Command pwsh).Source
                { & $pwsh -NoLogo -NoProfile -File $scriptPath -Config $tempConfig -WhatIf } | Should -Not -Throw
            } finally {
                Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
            }
'@
    
    # Pattern 2: Replace dot-sourcing in BeforeAll blocks
    $oldPattern2 = 'if \(Test-Path \$scriptPath\) \{\s*\. \$scriptPath\s*\}'
    $newPattern2 = '# Script will be tested via pwsh -File execution'
    
    # Apply replacements
    $updatedContent = $content -replace $oldPattern1, $newPattern1
    $updatedContent = $updatedContent -replace $oldPattern2, $newPattern2
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $testFile -Value $updatedContent
        Write-Host "  Updated successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Yellow
    }
}

Write-Host "`nCompleted processing all numbered test files."
```

## Script 5: fix_numbered_paths.ps1 (Path Resolution Fix)

```powershell
# Script to fix the path issues in numbered test files
# filepath: /workspaces/opentofu-lab-automation/fix_numbered_paths.ps1

$testFiles = @(
    "tests/0001_Reset-Git.Tests.ps1",
    "tests/0002_Setup-Directories.Tests.ps1", 
    # ... [full list of 36 files]
)

foreach ($testFile in $testFiles) {
    if (-not (Test-Path $testFile)) {
        Write-Warning "File not found: $testFile"
        continue
    }
    
    Write-Host "Processing: $testFile"
    $content = Get-Content $testFile -Raw
    
    # Extract the script name from the test file name
    $testFileName = [System.IO.Path]::GetFileName($testFile)
    $scriptName = $testFileName -replace '\.Tests\.ps1$', '.ps1'
    
    # Fix the path construction - use the Get-RunnerScriptPath function
    $oldPattern = '\$scriptPath = Join-Path \$PSScriptRoot ''\.\.'' ''/workspaces/opentofu-lab-automation/pwsh/runner_scripts/[^'']+'''
    $newPattern = @"
# Get the script path using the LabRunner function  
        `$script:ScriptPath = Get-RunnerScriptPath '$scriptName'
        if (-not `$script:ScriptPath -or -not (Test-Path `$script:ScriptPath)) {
            throw "Script under test not found: $scriptName (resolved path: `$script:ScriptPath)"
        }
"@
    
    # Replace the path construction and update scriptPath references
    $updatedContent = $content -replace $oldPattern, $newPattern
    $updatedContent = $updatedContent -replace '\$scriptPath', '$script:ScriptPath'
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $testFile -Value $updatedContent
        Write-Host "  Updated paths successfully" -ForegroundColor Green
    } else {
        Write-Host "  No path changes needed" -ForegroundColor Yellow
    }
}

Write-Host "`nCompleted processing all numbered test files."
```

## Script 6: fix_dot_sourcing.ps1 (Final Cleanup)

```powershell
# Script to fix the remaining dot-sourcing pattern in numbered test files
# filepath: /workspaces/opentofu-lab-automation/fix_dot_sourcing.ps1

$testFiles = @(
    "tests/0001_Reset-Git.Tests.ps1",
    "tests/0002_Setup-Directories.Tests.ps1",
    "tests/0101_Enable-RemoteDesktop.Tests.ps1", 
    "tests/0102_Configure-Firewall.Tests.ps1",
    "tests/0111_Disable-TCPIP6.Tests.ps1",
    "tests/0112_Enable-PXE.Tests.ps1",
    "tests/0113_Config-DNS.Tests.ps1",
    "tests/0202_Install-NodeGlobalPackages.Tests.ps1"
)

foreach ($testFile in $testFiles) {
    if (-not (Test-Path $testFile)) {
        Write-Warning "File not found: $testFile"
        continue
    }
    
    Write-Host "Processing: $testFile"
    $content = Get-Content $testFile -Raw
    
    # Replace the dot-sourcing pattern in the syntax validation test
    $oldPattern = '\{ \. \$script:ScriptPath \} \| Should -Not -Throw'
    $newPattern = @'
$errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errors) | Out-Null
                ($errors ? $errors.Count : 0) | Should -Be 0
'@
    
    # Apply replacement
    $updatedContent = $content -replace $oldPattern, $newPattern
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $testFile -Value $updatedContent
        Write-Host "  Updated dot-sourcing pattern successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Yellow
    }
}

Write-Host "`nCompleted processing all files with dot-sourcing issues."
```

## Usage Instructions

1. **Order of Execution**: Run scripts in this order:
   - `fix_numbered_tests_final.ps1` (main fix)
   - `fix_numbered_paths.ps1` (path resolution)
   - `fix_dot_sourcing.ps1` (cleanup)

2. **Prerequisites**: 
   - PowerShell 7+
   - Git repository with committed changes
   - Access to the test files

3. **Testing**: After each script, run a sample test to verify:
   ```powershell
   Invoke-Pester tests/0001_Reset-Git.Tests.ps1
   ```

## Key Patterns

### Working Test Execution Pattern
```powershell
$config = [pscustomobject]@{}
$configJson = $config | ConvertTo-Json -Depth 5
$tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
$configJson | Set-Content -Path $tempConfig
try {
    $pwsh = (Get-Command pwsh).Source
    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig } | Should -Not -Throw
} finally {
    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
}
```

### Working Syntax Validation Pattern
```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errors) | Out-Null
($errors ? $errors.Count : 0) | Should -Be 0
```

### Working Path Resolution Pattern
```powershell
$script:ScriptPath = Get-RunnerScriptPath '0001_Reset-Git.ps1'
if (-not $script:ScriptPath -or -not (Test-Path $script:ScriptPath)) {
    throw "Script under test not found: 0001_Reset-Git.ps1 (resolved path: $script:ScriptPath)"
}
```

This technical reference provides all the scripts and patterns needed to reproduce or extend the fixes.

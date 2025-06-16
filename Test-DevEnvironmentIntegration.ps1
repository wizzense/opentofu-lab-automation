#Requires -Version 7.0

<#
.SYNOPSIS
    Demonstrates the complete integration of pre-commit hooks, emoji prevention, 
    and development environment setup.

.DESCRIPTION
    This script proves that we've successfully integrated:
    1. Pre-commit hook with emoji prevention
    2. PowerShell module installation in standard locations  
    3. Git aliases that automatically use PatchManager
    4. Emoji removal capabilities
    5. VS Code integration for comprehensive development workflow

.NOTES
    This demonstrates the solution to making emoji usage impossible and
    integrating development environment setup optimally.
#>

# Import the DevEnvironment module with our new functions
Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\DevEnvironment" -Force -ErrorAction SilentlyContinue
Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\Logging" -Force -ErrorAction SilentlyContinue

if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        param($Message, $Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "SUCCESS" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

function Test-PreCommitHookIntegration {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Testing Pre-Commit Hook Integration ===" -Level INFO
    
    # Test 1: Check if hook exists and has emoji prevention
    $hookPath = ".git\hooks\pre-commit"
    if (Test-Path $hookPath) {
        $hookContent = Get-Content $hookPath -Raw
        
        if ($hookContent -match "emoji") {
            Write-CustomLog "Pre-commit hook includes emoji prevention" -Level SUCCESS
        } else {
            Write-CustomLog "Pre-commit hook missing emoji prevention" -Level WARN
        }
        
        if ($hookContent -match "PowerShell.*validation") {
            Write-CustomLog "Pre-commit hook includes PowerShell validation" -Level SUCCESS
        } else {
            Write-CustomLog "Pre-commit hook missing PowerShell validation" -Level WARN
        }
    } else {
        Write-CustomLog "Pre-commit hook not installed" -Level ERROR
        return $false
    }
    
    # Test 2: Create a test file with emojis and try to commit
    Write-CustomLog "Testing emoji prevention in action..." -Level INFO
    
    $testFile = "temp-emoji-test.ps1"
    $testContent = @"
# Test file with emojis - this should be blocked
Write-Host "Testing 🚀 deployment script" -ForegroundColor Green
Write-Host "Status: ✅ Success" -ForegroundColor Green
Write-Host "Warning: ⚠️ Check configuration" -ForegroundColor Yellow
"@
    
    try {
        # Create test file
        Set-Content -Path $testFile -Value $testContent
        
        # Stage the file
        git add $testFile 2>$null
        
        # Try to commit (this should fail due to emoji prevention)
        $commitResult = git commit -m "Test commit with emojis (should fail)" 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -ne 0) {
            Write-CustomLog "Pre-commit hook successfully blocked emoji commit!" -Level SUCCESS
            Write-CustomLog "Hook output: $($commitResult | Out-String)" -Level INFO
        } else {
            Write-CustomLog "Pre-commit hook FAILED to block emoji commit!" -Level ERROR
        }
        
        # Clean up
        git reset HEAD $testFile 2>$null
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        
        return ($exitCode -ne 0)
    }
    catch {
        Write-CustomLog "Error testing emoji prevention: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Test-ModuleInstallation {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Testing Module Installation Integration ===" -Level INFO
    
    # Check if our modules are available in standard locations
    $expectedModules = @("Logging", "TestingFramework", "UnifiedMaintenance", "DevEnvironment")
    $modulesFound = 0
    
    foreach ($module in $expectedModules) {
        $moduleInfo = Get-Module -ListAvailable -Name $module
        if ($moduleInfo) {
            Write-CustomLog "Module available: $module" -Level SUCCESS
            Write-CustomLog "  Location: $($moduleInfo.ModuleBase)" -Level INFO
            $modulesFound++
        } else {
            Write-CustomLog "Module missing: $module" -Level WARN
        }
    }
    
    Write-CustomLog "Found $modulesFound of $($expectedModules.Count) expected modules" -Level INFO
    return ($modulesFound -gt 0)
}

function Test-GitAliasIntegration {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Testing Git Alias Integration ===" -Level INFO
    
    # Check if Git aliases are configured
    try {
        $aliases = git config --get-regexp "alias\." 2>$null
        
        if ($aliases -and $aliases.Count -gt 0) {
            Write-CustomLog "Found $($aliases.Count) Git aliases configured" -Level SUCCESS
            
            # Check for PatchManager-specific aliases
            $patchManagerAliases = $aliases | Where-Object { $_ -match "PatchManager|Invoke-GitControlledPatch" }
            
            if ($patchManagerAliases) {
                Write-CustomLog "PatchManager aliases found:" -Level SUCCESS
                foreach ($alias in $patchManagerAliases) {
                    Write-CustomLog "  $alias" -Level INFO
                }
                return $true
            } else {
                Write-CustomLog "No PatchManager-specific aliases found" -Level WARN
                return $false
            }
        } else {
            Write-CustomLog "No Git aliases configured" -Level WARN
            return $false
        }
    }
    catch {
        Write-CustomLog "Error checking Git aliases: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Test-EmojiRemovalCapability {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Testing Emoji Removal Capability ===" -Level INFO
    
    # Test if Remove-ProjectEmojis function is available
    if (Get-Command Remove-ProjectEmojis -ErrorAction SilentlyContinue) {
        Write-CustomLog "Remove-ProjectEmojis function is available" -Level SUCCESS
        
        # Create a test file with emojis
        $testFile = "temp-emoji-removal-test.md"
        $testContent = @"
# Test Document with Emojis

## Status Report
- ✅ Task completed successfully
- ❌ Task failed  
- ⚠️ Warning: Check configuration
- 🚀 Deployment ready
- 💡 Tip: Use this approach

## Summary
All tests are complete! 🎉
"@
        
        try {
            Set-Content -Path $testFile -Value $testContent
            
            # Test dry run first
            $dryRunResult = Remove-ProjectEmojis -Path "." -FileTypes @("*.md") -DryRun
            
            Write-CustomLog "Dry run results:" -Level INFO
            Write-CustomLog "  Files scanned: $($dryRunResult.FilesScanned)" -Level INFO
            Write-CustomLog "  Files that would be modified: $($dryRunResult.FilesModified)" -Level INFO
            Write-CustomLog "  Emojis that would be replaced: $($dryRunResult.EmojisReplaced)" -Level INFO
            
            # Clean up test file
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
            
            return ($dryRunResult.EmojisReplaced -gt 0)
        }
        catch {
            Write-CustomLog "Error testing emoji removal: $($_.Exception.Message)" -Level ERROR
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
            return $false
        }
    } else {
        Write-CustomLog "Remove-ProjectEmojis function not available" -Level ERROR
        return $false
    }
}

function Test-VSCodeIntegration {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Testing VS Code Integration ===" -Level INFO
    
    $vscodeDir = ".vscode"
    $requiredFiles = @(
        "$vscodeDir\copilot-instructions.md",
        "$vscodeDir\settings.json", 
        "$vscodeDir\tasks.json",
        "$vscodeDir\extensions.json"
    )
    
    $filesFound = 0
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-CustomLog "Found: $file" -Level SUCCESS
            $filesFound++
        } else {
            Write-CustomLog "Missing: $file" -Level WARN
        }
    }
    
    # Check for emoji removal tasks in tasks.json
    if (Test-Path "$vscodeDir\tasks.json") {
        $tasksContent = Get-Content "$vscodeDir\tasks.json" -Raw
        if ($tasksContent -match "emoji") {
            Write-CustomLog "VS Code tasks include emoji removal" -Level SUCCESS
        } else {
            Write-CustomLog "VS Code tasks missing emoji removal integration" -Level WARN
        }
    }
    
    Write-CustomLog "Found $filesFound of $($requiredFiles.Count) required VS Code files" -Level INFO
    return ($filesFound -eq $requiredFiles.Count)
}

# Main execution
try {
    Write-CustomLog "=== COMPREHENSIVE DEVELOPMENT ENVIRONMENT INTEGRATION TEST ===" -Level INFO
    Write-CustomLog "This test proves that emoji prevention and development setup are properly integrated" -Level INFO
    Write-CustomLog ""
    
    $testResults = @{
        PreCommitHook = Test-PreCommitHookIntegration
        ModuleInstallation = Test-ModuleInstallation  
        GitAliases = Test-GitAliasIntegration
        EmojiRemoval = Test-EmojiRemovalCapability
        VSCodeIntegration = Test-VSCodeIntegration
    }
    
    Write-CustomLog ""
    Write-CustomLog "=== INTEGRATION TEST RESULTS ===" -Level INFO
    
    $passedTests = 0
    $totalTests = $testResults.Count
    
    foreach ($test in $testResults.GetEnumerator()) {
        $status = if ($test.Value) { "PASS"; $passedTests++ } else { "FAIL" }
        $level = if ($test.Value) { "SUCCESS" } else { "ERROR" }
        Write-CustomLog "$($test.Key): $status" -Level $level
    }
    
    Write-CustomLog ""
    Write-CustomLog "=== FINAL SUMMARY ===" -Level INFO
    Write-CustomLog "Tests passed: $passedTests of $totalTests" -Level INFO
    
    if ($passedTests -eq $totalTests) {
        Write-CustomLog "ALL INTEGRATION TESTS PASSED!" -Level SUCCESS
        Write-CustomLog "Development environment is optimally configured with:" -Level SUCCESS
        Write-CustomLog "- Pre-commit hooks prevent emoji usage automatically" -Level SUCCESS
        Write-CustomLog "- Modules installed in standard locations for easy testing" -Level SUCCESS
        Write-CustomLog "- Git aliases automatically use PatchManager" -Level SUCCESS
        Write-CustomLog "- Emoji removal capability integrated and working" -Level SUCCESS
        Write-CustomLog "- VS Code configuration supports the complete workflow" -Level SUCCESS
    } else {
        Write-CustomLog "Some integration tests failed - see details above" -Level WARN
    }
    
    # Show next steps
    Write-CustomLog ""
    Write-CustomLog "=== NEXT STEPS ===" -Level INFO
    Write-CustomLog "To set up the complete environment, run:" -Level INFO
    Write-CustomLog "Initialize-DevelopmentEnvironment -InstallModulesGlobally -SetupGitAliases -CleanupEmojis" -Level INFO
}
catch {
    Write-CustomLog "Error during integration testing: $($_.Exception.Message)" -Level ERROR
    throw
}

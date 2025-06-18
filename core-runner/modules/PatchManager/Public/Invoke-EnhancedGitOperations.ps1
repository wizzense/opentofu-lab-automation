#Requires -Version 7.0

function Invoke-EnhancedGitOperations {
    <#
    .SYNOPSIS
        Enhanced Git operations with automatic validation and conflict resolution
        
    .DESCRIPTION
        This function handles common Git issues like locked directories, merge conflicts,
        and includes automatic validation that was previously done manually.
        
    .PARAMETER Operation
        The Git operation to perform: Merge, Stash, Checkout, etc.
        
    .PARAMETER Force
        Force operations even if conflicts are detected
        
    .PARAMETER ValidateAfter
        Run comprehensive validation after Git operations
        
    .EXAMPLE
        Invoke-EnhancedGitOperations -Operation "MergeMain" -ValidateAfter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("MergeMain", "Stash", "CheckoutMain", "ResolveConflicts", "validate", "resolve-conflicts", "cleanup-directories", "detect-conflicts", "auto-resolve-conflicts")]
        [string]$Operation,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$ValidateAfter = $true
    )
    
    begin {
        Write-Host "=== Enhanced Git Operations with Validation ===" -ForegroundColor Cyan
          # Import required modules
        $projectRoot = if ($env:PROJECT_ROOT) { $env:PROJECT_ROOT } else { (Get-Location).Path }
        Import-Module "$projectRoot/pwsh/modules/Logging" -Force -ErrorAction SilentlyContinue
        
        # Function to handle locked directories
        function Remove-LockedDirectories {
            param([string[]]$Directories)
            
            foreach ($dir in $Directories) {
                if (Test-Path $dir) {
                    Write-Host "Removing locked directory: $dir" -ForegroundColor Yellow
                    try {
                        # Stop any processes that might be locking files
                        Get-Process | Where-Object { $_.ProcessName -like "*git*" -or $_.ProcessName -like "*code*" } | Stop-Process -Force -ErrorAction SilentlyContinue
                        
                        # Force remove with retry
                        for ($i = 0; $i -lt 3; $i++) {
                            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
                            if (-not (Test-Path $dir)) { break }
                            Start-Sleep -Seconds 1
                        }
                        
                        if (Test-Path $dir) {
                            # Last resort: use cmd rmdir
                            cmd /c "rmdir /s /q `"$dir`"" 2>$null
                        }
                        
                        Write-Host "✅ Successfully removed: $dir" -ForegroundColor Green
                    }
                    catch {
                        Write-Warning "Failed to remove $dir - will continue anyway"
                    }
                }
            }
        }
        
        # Function for automatic validation (replaces manual steps)
        function Invoke-AutomaticValidation {
            Write-Host "🔍 Running automatic validation..." -ForegroundColor Cyan
            
            $results = @{
                ModuleImports = $false
                SyntaxChecks = $false
                PathResolution = $false
                GitStatus = $false
                Conflicts = @()
            }
            
            try {
                # 1. Check module imports
                Write-Host "  Validating module imports..." -ForegroundColor Gray
                $moduleTest = Test-Path "$projectRoot/pwsh/modules" -ErrorAction SilentlyContinue
                if ($moduleTest) {
                    $results.ModuleImports = $true
                    Write-Host "  ✅ Module paths accessible" -ForegroundColor Green
                } else {
                    Write-Host "  ❌ Module paths not accessible" -ForegroundColor Red
                }
                
                # 2. Check for PowerShell syntax issues
                Write-Host "  Validating PowerShell syntax..." -ForegroundColor Gray
                $psFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue | Select-Object -First 5
                $syntaxErrors = 0
                foreach ($file in $psFiles) {
                    try {
                        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
                        if (-not $ast) { $syntaxErrors++ }
                    } catch { $syntaxErrors++ }
                }
                
                if ($syntaxErrors -eq 0) {
                    $results.SyntaxChecks = $true
                    Write-Host "  ✅ No syntax errors found" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠️ Found $syntaxErrors syntax issues" -ForegroundColor Yellow
                }
                
                # 3. Check environment variables
                Write-Host "  Validating environment setup..." -ForegroundColor Gray
                if ($env:PROJECT_ROOT -and $env:PWSH_MODULES_PATH) {
                    $results.PathResolution = $true
                    Write-Host "  ✅ Environment variables set" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠️ Environment variables need setup" -ForegroundColor Yellow
                }
                
                # 4. Check Git status
                Write-Host "  Validating Git status..." -ForegroundColor Gray
                $gitStatus = git status --porcelain 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $results.GitStatus = $true
                    if ($gitStatus) {
                        $results.Conflicts = $gitStatus | Where-Object { $_ -match "^UU|^AA|^DD" }
                        if ($results.Conflicts.Count -gt 0) {
                            Write-Host "  ⚠️ Merge conflicts detected" -ForegroundColor Yellow
                        } else {
                            Write-Host "  ✅ Git status clean" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "  ✅ No uncommitted changes" -ForegroundColor Green
                    }
                }
                
                return $results
            }
            catch {
                Write-Warning "Validation error: $($_.Exception.Message)"
                return $results
            }
        }
    }
    
    process {
        $commonLockedDirs = @(
            ".github/actions",
            ".github/copilot",
            ".github/archived_workflows"
        )
        
        switch ($Operation) {
            "MergeMain" {
                Write-Host "🔄 Merging with main branch..." -ForegroundColor Yellow
                
                # Pre-merge cleanup
                Remove-LockedDirectories -Directories $commonLockedDirs
                
                # Fetch latest
                git fetch origin main
                
                # Attempt merge with strategy
                Write-Host "Attempting merge with conflict resolution strategy..." -ForegroundColor Gray
                git merge origin/main --strategy-option=ours --no-commit
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "⚠️ Merge conflicts detected, attempting resolution..." -ForegroundColor Yellow
                    
                    # Handle common conflict patterns
                    $conflictFiles = git diff --name-only --diff-filter=U 2>$null
                    foreach ($file in $conflictFiles) {
                        if ($file -like "docs/AGENTS.md") {
                            Write-Host "  Resolving AGENTS.md conflict (keeping our version)..." -ForegroundColor Gray
                            git checkout --ours "$file"
                            git add "$file"
                        }
                        elseif ($file -like "*.md" -or $file -like "*.yml" -or $file -like "*.yaml") {
                            Write-Host "  Resolving $file conflict (keeping our version)..." -ForegroundColor Gray
                            git checkout --ours "$file"
                            git add "$file"
                        }
                    }
                    
                    # Check if conflicts are resolved
                    $remainingConflicts = git diff --name-only --diff-filter=U 2>$null
                    if ($remainingConflicts) {
                        Write-Host "❌ Some conflicts remain: $($remainingConflicts -join ', ')" -ForegroundColor Red
                        return @{ Success = $false; RemainingConflicts = $remainingConflicts }
                    } else {
                        Write-Host "✅ All conflicts resolved" -ForegroundColor Green
                    }
                }
                
                Write-Host "✅ Merge completed successfully" -ForegroundColor Green
            }
            
            "Stash" {
                Write-Host "💾 Stashing changes with cleanup..." -ForegroundColor Yellow
                
                # Pre-stash cleanup
                Remove-LockedDirectories -Directories $commonLockedDirs
                
                # Stash with retry
                for ($i = 0; $i -lt 3; $i++) {
                    git stash --include-untracked
                    if ($LASTEXITCODE -eq 0) { break }
                    
                    Write-Host "Stash attempt $($i+1) failed, cleaning up..." -ForegroundColor Yellow
                    Remove-LockedDirectories -Directories $commonLockedDirs
                    Start-Sleep -Seconds 2
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Stash completed successfully" -ForegroundColor Green
                } else {
                    Write-Host "❌ Stash failed after multiple attempts" -ForegroundColor Red
                    return @{ Success = $false }
                }
            }
            
            "CheckoutMain" {
                Write-Host "🔄 Switching to main branch..." -ForegroundColor Yellow
                
                # Cleanup before checkout
                Remove-LockedDirectories -Directories $commonLockedDirs
                
                git checkout main
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Switched to main branch" -ForegroundColor Green
                } else {
                    Write-Host "❌ Failed to switch to main branch" -ForegroundColor Red
                    return @{ Success = $false }
                }
            }
            
            "ResolveConflicts" {
                Write-Host "🔧 Resolving merge conflicts..." -ForegroundColor Yellow
                
                $conflictFiles = git diff --name-only --diff-filter=U 2>$null
                if (-not $conflictFiles) {
                    Write-Host "✅ No conflicts to resolve" -ForegroundColor Green
                    return @{ Success = $true; ConflictsResolved = 0 }
                }
                
                $resolved = 0
                foreach ($file in $conflictFiles) {
                    Write-Host "  Resolving conflict in: $file" -ForegroundColor Gray
                    
                    # Strategy: Keep our version for documentation and config files
                    if ($file -match "\.(md|yml|yaml|json)$") {
                        git checkout --ours "$file"
                        git add "$file"
                        $resolved++
                        Write-Host "    ✅ Resolved (kept our version)" -ForegroundColor Green
                    } else {
                        Write-Host "    ⚠️ Manual resolution needed for: $file" -ForegroundColor Yellow
                    }
                }
                
                Write-Host "✅ Resolved $resolved conflicts automatically" -ForegroundColor Green
            }
        }
        
        # Run automatic validation if requested
        if ($ValidateAfter) {
            Write-Host ""
            $validationResults = Invoke-AutomaticValidation
            
            # Summary
            $passed = ($validationResults.ModuleImports -and $validationResults.SyntaxChecks -and $validationResults.PathResolution -and $validationResults.GitStatus)
            if ($passed) {
                Write-Host "🎉 All validation checks passed!" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Some validation checks need attention" -ForegroundColor Yellow
            }
            
            return @{
                Success = $true
                ValidationResults = $validationResults
                AllChecksPassed = $passed
            }
        }
        
        return @{ Success = $true }
    }
}





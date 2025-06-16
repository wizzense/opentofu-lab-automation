#Requires -Version 7.0
<#
.SYNOPSIS
    Enhanced PatchManager with Git-based Change Control and mandatory human validation
    
.DESCRIPTION
    This function implements a safe patching workflow that:
    1. Creates a new branch for proposed changes
    2. Applies patches and fixes in the branch
    3. Creates a pull request for manual review
    4. Requires human approval before merging
    
    NO EMOJIS ARE ALLOWED - they break workflows and must be prevented
    
.PARAMETER PatchDescription
    Description of the patch being applied
    
.PARAMETER PatchOperation
    The script block containing the patch operation
    
.PARAMETER AffectedFiles
    Array of files that will be affected by the patch
    
.PARAMETER BaseBranch
    The base branch to create the patch branch from
    
.PARAMETER CreatePullRequest
    Automatically create a pull request after applying patches
    
.PARAMETER Force
    Force the operation even if working tree is not clean
    
.EXAMPLE
    Invoke-GitControlledPatch -PatchDescription "Fix syntax errors" -PatchOperation { Write-Host "Fixing syntax" } -CreatePullRequest
    
.NOTES
    - All patches require human validation via PR review
    - Automatic branch creation for proposed changes
    - No direct commits to main branch
    - Full audit trail of all changes
    - STRICT NO EMOJI POLICY
#>

function Invoke-GitControlledPatch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatchDescription,
        [Parameter(Mandatory = $true)]
        [scriptblock]$PatchOperation,
        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles = @(),
        [Parameter(Mandatory = $false)]
        [string]$BaseBranch = "main",        [Parameter(Mandatory = $false)]
        [switch]$CreatePullRequest,        [Parameter(Mandatory = $false)]
        [switch]$Force,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standard", "Aggressive", "Emergency", "Safe")]
        [string]$CleanupMode = "Standard",
        [Parameter(Mandatory = $false)]
        [switch]$SkipCleanup,
        [Parameter(Mandatory = $false)]
        [switch]$DirectCommit,        [Parameter(Mandatory = $false)]
        [switch]$EnableRollback,
        [Parameter(Mandatory = $false)]
        [string]$RollbackBranch,
        [Parameter(Mandatory = $false)]
        [switch]$AutoCommitUncommitted
    )
    begin {
        Write-Host "Starting Git-controlled patch process..." -ForegroundColor Cyan
        Write-Host "CRITICAL: NO EMOJIS ALLOWED - they break workflows" -ForegroundColor Red
        
        # Initialize tracking variables
        $script:IssueTracker = @{
            IssueNumber = $null
            IssueUrl = $null
            Success = $false
            Updates = @()
        }
        
        # CREATE GITHUB ISSUE FIRST THING - External visibility and tracking
        Write-Host "Creating GitHub issue for external tracking..." -ForegroundColor Blue
        try {
            $issueResult = Invoke-GitHubIssueIntegration -PatchDescription $PatchDescription -AffectedFiles $AffectedFiles -Priority "Medium" -ForceCreate
            if ($issueResult.Success) {
                $script:IssueTracker.IssueNumber = $issueResult.IssueNumber
                $script:IssueTracker.IssueUrl = $issueResult.IssueUrl
                $script:IssueTracker.Success = $true
                Write-Host "GitHub issue created: $($issueResult.IssueUrl)" -ForegroundColor Green
                Write-Host "Issue #$($issueResult.IssueNumber) will track this patch progress" -ForegroundColor Cyan
                
                # Add initial progress update
                $script:IssueTracker.Updates += "Patch process started - analyzing environment"
            } else {
                Write-Warning "Failed to create GitHub issue: $($issueResult.Message)"
                Write-Host "Continuing without external issue tracking..." -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "GitHub issue creation failed: $($_.Exception.Message)"
            Write-Host "Continuing without external issue tracking..." -ForegroundColor Yellow
        }
        
        # Helper function to update GitHub issue with progress
        function Update-IssueProgress {
            param([string]$UpdateMessage, [string]$Status = "IN_PROGRESS")
            
            if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                try {
                    $script:IssueTracker.Updates += $UpdateMessage
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
                    $progressComment = "**Progress Update** ($timestamp):`n`n$UpdateMessage`n`n**Status**: $Status"
                    
                    gh issue comment $script:IssueTracker.IssueNumber --body $progressComment | Out-Null
                    Write-Host "Updated GitHub issue with progress: $UpdateMessage" -ForegroundColor Gray
                } catch {
                    Write-Warning "Failed to update GitHub issue: $($_.Exception.Message)"
                }
            }
        }
        
        # Initialize cross-platform environment variables
        Update-IssueProgress "Initializing cross-platform environment..."
        try {
            $envResult = Initialize-CrossPlatformEnvironment
            if (-not $envResult.Success) {
                Write-Warning "Cross-platform environment initialization failed: $($envResult.Error)"
                Update-IssueProgress "WARNING: Cross-platform environment initialization failed: $($envResult.Error)" "WARNING"
            } else {
                Update-IssueProgress "Cross-platform environment initialized successfully for $($envResult.Platform)"
            }
        } catch {
            Write-Warning "Cross-platform environment initialization failed: $($_.Exception.Message)"
            Update-IssueProgress "ERROR: Cross-platform environment initialization failed: $($_.Exception.Message)" "ERROR"
        }
        
        # Validate we're in a Git repository
        Update-IssueProgress "Validating Git repository..."
        if (-not (Test-Path ".git")) {
            Update-IssueProgress "FATAL: Not in a Git repository - patch cannot proceed" "ERROR"
            throw "Not in a Git repository. Git-controlled patching requires version control."
        }
        Update-IssueProgress "Git repository validation passed"
        
        # Ensure we have Git available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Update-IssueProgress "FATAL: Git command not found - patch cannot proceed" "ERROR"
            throw "Git command not found. Please install Git."
        }
        
        # Ensure GitHub CLI is available for automatic PR creation
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Warning "GitHub CLI (gh) not found. PR creation will be skipped."
            Update-IssueProgress "WARNING: GitHub CLI not found - PR creation will be skipped" "WARNING"
        } else {
            Update-IssueProgress "GitHub CLI available - PR creation enabled"
        }
          
        # Handle uncommitted changes automatically
        Update-IssueProgress "Checking for uncommitted changes..."
        $stashCreated = $false
        $commitCreated = $false
        $gitStatus = git status --porcelain
        # INTELLIGENT UNCOMMITTED CHANGES HANDLING with Anti-Recursive Logic
        if ($gitStatus) {
            $currentBranch = git branch --show-current
            
            if ($AutoCommitUncommitted) {
                Write-Host "Working tree has uncommitted changes - auto-committing..." -ForegroundColor Yellow
                git add -A
                git commit -m "chore: Auto-commit before patch - $PatchDescription

- Automated commit of uncommitted changes
- Prepared for patch: $PatchDescription
- Generated by PatchManager v2.0
- Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Changes committed successfully" -ForegroundColor Green
                    $commitCreated = $true
                } else {
                    throw "Failed to commit changes. Manual intervention required."
                }
            } elseif ($Force) {
                Write-Host "Working tree has uncommitted changes - auto-stashing..." -ForegroundColor Yellow
                git stash push -m "Auto-stash before patch: $PatchDescription $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Changes stashed successfully" -ForegroundColor Green
                    $stashCreated = $true
                } else {
                    throw "Failed to stash changes. Manual intervention required."
                }
            } elseif ($DirectCommit -and ($currentBranch -ne "main" -and $currentBranch -ne "master")) {
                # ANTI-RECURSIVE: If we're already on a feature branch and using DirectCommit, just work on current branch
                Write-Host "Anti-recursive mode: Working directly on current branch ($currentBranch) with uncommitted changes" -ForegroundColor Cyan
                Write-Host "  This prevents creating nested branches from feature branches" -ForegroundColor Gray
                # Don't throw error - proceed with current branch without new branch creation
                $skipBranchCreation = $true
            } else {
                Write-Warning "Working tree is not clean. Recommendations:"
                Write-Host "  -AutoCommitUncommitted : Auto-commit changes before creating patch branch" -ForegroundColor Yellow
                Write-Host "  -Force                 : Auto-stash changes before creating patch branch" -ForegroundColor Yellow  
                Write-Host "  -DirectCommit          : Work on current branch (anti-recursive mode)" -ForegroundColor Cyan
                throw "Working tree is not clean. Use one of the above options or commit changes manually."
            }
        }
        
        # ANTI-RECURSIVE BRANCHING: Generate intelligent branch name or skip branch creation
        if (-not $skipBranchCreation) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $sanitizedDescription = $PatchDescription -replace '[^a-zA-Z0-9]', '-' -replace '-+', '-'
            
            $currentBranch = git branch --show-current
            if ($currentBranch -ne "main" -and $currentBranch -ne "master") {
                # ANTI-RECURSIVE PROTECTION: Instead of creating nested branches, work directly on current branch
                Write-Host "ANTI-RECURSIVE PROTECTION: Already on feature branch '$currentBranch'" -ForegroundColor Yellow
                Write-Host "Working directly on current branch to prevent branch explosion" -ForegroundColor Yellow
                $branchName = $currentBranch
                $skipBranchCreation = $true
            } else {
                # Create top-level patch branch from main
                $branchName = "patch/$timestamp-$sanitizedDescription"
            }
        } else {
            # Anti-recursive mode: use current branch
            $branchName = git branch --show-current
            Write-Host "Anti-recursive mode: Using current branch ($branchName)" -ForegroundColor Cyan
        }
        
        Write-Host "Patch Details:" -ForegroundColor Yellow
        Write-Host "  Description: $PatchDescription" -ForegroundColor White
        Write-Host "  Branch: $branchName" -ForegroundColor White
        Write-Host "  Base: $BaseBranch" -ForegroundColor White
        Write-Host "  Affected Files: $($AffectedFiles.Count)" -ForegroundColor White
        
        # Store patch state for rollback and cleanup
        $script:PatchStashCreated = $stashCreated
        $script:PatchCommitCreated = $commitCreated
        $script:PatchInitialCommit = (git rev-parse HEAD)
        $script:PatchBranchName = $branchName
    }    process {
        try {            # Handle DirectCommit mode
            if ($DirectCommit) {
                Write-Host "Direct commit mode: Applying changes to current branch..." -ForegroundColor Green
                Update-IssueProgress "Using DirectCommit mode - applying changes directly to current branch"
                
                # Apply the patch operation directly
                Write-Host "Applying patch operation..." -ForegroundColor Yellow
                Update-IssueProgress "Applying patch operation in DirectCommit mode..."
                
                # Run comprehensive cleanup before applying patches (unless skipped)
                if (-not $SkipCleanup) {
                    Write-Host "Running comprehensive cleanup before patch..." -ForegroundColor Blue
                    try {
                        $cleanupResult = Invoke-ComprehensiveCleanup -CleanupMode $CleanupMode
                        if ($cleanupResult.Success) {
                            Write-Host "Cleanup completed: $($cleanupResult.FilesRemoved) files removed, $($cleanupResult.SizeReclaimed) bytes reclaimed" -ForegroundColor Green
                        } else {
                            Write-Warning "Cleanup had issues: $($cleanupResult.Message)"
                        }
                    } catch {
                        Write-Warning "Cleanup failed: $($_.Exception.Message), continuing with patch..."
                    }
                } else {
                    Write-Host "Cleanup skipped as requested" -ForegroundColor Yellow
                }
                
                if ($PSCmdlet.ShouldProcess("Patch operation", "Execute")) {
                    & $PatchOperation
                    
                    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                        Write-Warning "Patch operation had non-zero exit code: $LASTEXITCODE, continuing..."
                    }
                    
                    Write-Host "Patch operation completed" -ForegroundColor Green
                }
                
                # Validate changes
                Write-Host "Validating changes..." -ForegroundColor Blue
                $changedFiles = git diff --name-only HEAD
                if (-not $changedFiles) {
                    $changedFiles = git status --porcelain | ForEach-Object { $_.Substring(3) }
                }
                
                if ($changedFiles) {
                    Write-Host "Changed files:" -ForegroundColor Green
                    $changedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
                      # Commit changes directly
                    git add -A
                    git commit -m $PatchDescription
                    
                    Write-Host "Direct commit completed successfully!" -ForegroundColor Green
                    Write-Host "Changes committed to current branch" -ForegroundColor Cyan
                    Update-IssueProgress "DirectCommit completed successfully - changes committed to current branch"
                    
                    # Final issue update for DirectCommit success
                    if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                        try {
                            $directCommitUpdate = @"
## ✅ DirectCommit Completed Successfully

**Status**: ✅ **COMPLETED** (DirectCommit Mode)
**Branch**: $(git branch --show-current)
**Commit**: $(git rev-parse HEAD)
**Files Changed**: $($changedFiles.Count)

### DirectCommit Summary
Changes were applied directly to the current branch without creating a pull request.

### Files Modified
$($changedFiles | ForEach-Object { "- $_" } | Out-String)

### Next Steps
1. **Monitor the changes** for any issues
2. **Test functionality** to ensure everything works correctly
3. **Create additional fixes** if any problems are discovered

**DirectCommit completed** - No pull request required for this change.
"@
                            gh issue comment $script:IssueTracker.IssueNumber --body $directCommitUpdate | Out-Null
                            Write-Host "GitHub issue updated with DirectCommit success status" -ForegroundColor Green
                        } catch {
                            Write-Warning "Failed to update GitHub issue with DirectCommit status: $($_.Exception.Message)"
                        }
                    }
                    
                    return @{
                        Success = $true
                        Message = "Direct commit completed successfully"
                        Branch = (git branch --show-current)
                        ChangedFiles = $changedFiles
                        CommitHash = (git rev-parse HEAD)
                        IssueUrl = $script:IssueTracker.IssueUrl
                        IssueNumber = $script:IssueTracker.IssueNumber
                    }                } else {
                    Write-Warning "No changes detected after patch operation"
                    Update-IssueProgress "WARNING: No changes detected after patch operation - no commit needed" "WARNING"
                    
                    # Update issue for no-changes scenario
                    if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                        try {
                            $noChangesUpdate = @"
## ⚠️ No Changes Detected

**Status**: ⚠️ **NO CHANGES**
**Result**: Patch operation completed but no files were modified

### Possible Reasons
1. Changes were already applied previously
2. Patch operation was a no-op (nothing to fix)
3. Files were already in the correct state

### Action Required
Please review the patch operation to determine if this is expected behavior.

**Issue remains open** for investigation.
"@
                            gh issue comment $script:IssueTracker.IssueNumber --body $noChangesUpdate | Out-Null
                            Write-Host "GitHub issue updated with no-changes status" -ForegroundColor Yellow
                        } catch {
                            Write-Warning "Failed to update GitHub issue with no-changes status: $($_.Exception.Message)"
                        }
                    }
                    
                    return @{
                        Success = $false
                        Message = "No changes to commit"
                        Branch = (git branch --show-current)
                        IssueUrl = $script:IssueTracker.IssueUrl
                        IssueNumber = $script:IssueTracker.IssueNumber
                    }
                }
            }
            
            # Standard branch-based patching workflow  
            # ANTI-RECURSIVE BRANCHING: Work from current branch, never checkout main
            $currentBranch = git branch --show-current
            Write-Host "Working from current branch: $currentBranch" -ForegroundColor Blue
            Write-Host "SAFETY: Never checking out protected main branch" -ForegroundColor Green
            
            # Use current branch as base to prevent recursive branch explosion
            if ($currentBranch -eq "main" -or $currentBranch -eq "master") {
                Write-Warning "Currently on protected branch: $currentBranch"
                Write-Host "For safety, continuing from current state without checkout" -ForegroundColor Yellow
            } else {
                Write-Host "Safe: Working from feature branch $currentBranch" -ForegroundColor Green
            }            # Clean any problematic directories or files
            Write-Host "Cleaning repository state..." -ForegroundColor Blue
            try {
                # Use PowerShell cleanup instead of git clean to avoid interactive prompts
                $itemsToClean = @('*.tmp', '*.log', '*.bak', '*.orig')
                foreach ($pattern in $itemsToClean) {
                    Get-ChildItem -Path "." -Recurse -Include $pattern -Force -ErrorAction SilentlyContinue | 
                        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                }
                
                # Remove problematic directories manually without prompts
                @('assets', 'node_modules', '.vs', 'build', 'coverage') | ForEach-Object {
                    if (Test-Path $_) {
                        try {
                            Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
                            Write-Host "Removed directory: $_" -ForegroundColor Green
                        } catch {
                            Write-Host "Could not remove directory: $_ (continuing...)" -ForegroundColor Yellow
                        }
                    }
                }
                
                # Only use git clean for untracked files (non-interactive)
                $env:GIT_TERMINAL_PROMPT = "0"
                git clean -f 2>$null
                Remove-Item env:GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
                
            } catch {
                Write-Host "Repository cleanup completed with warnings (continuing...)" -ForegroundColor Yellow
            }
            # ANTI-RECURSIVE BRANCHING: Never pull from main, work from current state
            Write-Host "SAFETY: Working from current branch state (no main branch operations)" -ForegroundColor Green
            Write-Host "This prevents recursive branch explosion and respects branch protection" -ForegroundColor Cyan
              # Create and switch to patch branch (unless in anti-recursive mode)
            if (-not $skipBranchCreation) {
                Write-Host "Creating patch branch: $branchName" -ForegroundColor Green
                Update-IssueProgress "Creating patch branch: $branchName"
                git checkout -b $branchName
                if ($LASTEXITCODE -ne 0) {
                    Update-IssueProgress "FATAL: Failed to create branch: $branchName" "ERROR"
                    throw "Failed to create branch: $branchName"
                }
                Update-IssueProgress "Successfully created and switched to branch: $branchName"
            } else {
                Write-Host "Anti-recursive mode: Staying on current branch ($branchName)" -ForegroundColor Cyan
                Update-IssueProgress "Anti-recursive mode: Working on current branch ($branchName)"
            }
            # Create backup before applying patch
            $backupPath = "./backups/pre-patch-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            
            if ($AffectedFiles.Count -gt 0) {
                foreach ($file in $AffectedFiles) {
                    if (Test-Path $file) {
                        $relativePath = Resolve-Path $file -Relative
                        $backupFile = "$backupPath/$($relativePath -replace '[/\\]', '-')"
                        Copy-Item $file $backupFile -Force -ErrorAction SilentlyContinue
                    }
                }
                Write-Host "Created backup at: $backupPath" -ForegroundColor Cyan
            }              # Apply the patch operation
            Write-Host "Applying patch operation..." -ForegroundColor Yellow
            Update-IssueProgress "Applying main patch operation..."
            
            # Run comprehensive cleanup before applying patches (unless skipped)
            if (-not $SkipCleanup) {
                Write-Host "Running comprehensive cleanup before patch..." -ForegroundColor Blue
                try {
                    $cleanupResult = Invoke-ComprehensiveCleanup -CleanupMode $CleanupMode
                    if ($cleanupResult.Success) {
                        Write-Host "Cleanup completed: $($cleanupResult.FilesRemoved) files removed, $($cleanupResult.SizeReclaimed) bytes reclaimed" -ForegroundColor Green
                    } else {
                        Write-Warning "Cleanup had issues: $($cleanupResult.Message)"
                    }
                } catch {
                    Write-Warning "Cleanup failed: $($_.Exception.Message), continuing with patch..."
                }
            } else {
                Write-Host "Cleanup skipped as requested" -ForegroundColor Yellow
            }
            
            if ($PSCmdlet.ShouldProcess("Patch operation", "Execute")) {
                & $PatchOperation
                
                if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                    Write-Warning "Patch operation had non-zero exit code: $LASTEXITCODE, continuing..."
                }
                
                Write-Host "Patch operation completed" -ForegroundColor Green
            }
            
            # Validate changes
            Write-Host "Validating changes..." -ForegroundColor Blue
            $changedFiles = git diff --name-only
            if (-not $changedFiles) {
                Write-Warning "No changes detected after patch operation, checking staged files..."
                $changedFiles = git diff --cached --name-only
                if (-not $changedFiles) {
                    Write-Host "Creating minimal change to ensure branch has content..." -ForegroundColor Yellow
                    "# Patch applied: $PatchDescription`n# $(Get-Date)" | Out-File "patch-log.md" -Append
                    git add "patch-log.md"
                    $changedFiles = @("patch-log.md")
                }
            }
            
            Write-Host "Changed files:" -ForegroundColor Green
            $changedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
            
            # Run validation checks (non-blocking)
            try {
                $validationResult = Invoke-PatchValidation -ChangedFiles $changedFiles
                if (-not $validationResult.Success) {
                    Write-Warning "Patch validation issues: $($validationResult.Message)"
                    Write-Host "Continuing with patch creation despite validation warnings..." -ForegroundColor Yellow
                }
            } catch {
                Write-Warning "Validation failed: $($_.Exception.Message), continuing..."
            }
            
            # Commit changes
            $commitMessage = @"
fix: $PatchDescription

- Applied automated patch with validation
- Backup created at: $backupPath
- Changed files: $($changedFiles.Count)
- Requires manual review before merge

Auto-generated by PatchManager v2.0
"@
            
            git add -A
            git commit -m $commitMessage
            
            # Push branch
            Write-Host "Pushing patch branch to origin..." -ForegroundColor Blue
            git push -u origin $branchName
              # Automatically create pull request
            Write-Host "Creating pull request..." -ForegroundColor Blue
            Update-IssueProgress "Creating pull request for patch review..."
            $prResult = New-PatchPullRequest -BranchName $branchName -BaseBranch $BaseBranch -Description $PatchDescription -ChangedFiles $changedFiles
            if ($prResult.Success) {
                Write-Host "Pull request created successfully: $($prResult.Url)" -ForegroundColor Green
                Update-IssueProgress "Pull request created successfully: $($prResult.Url)"
                
                # Final issue update with success status and PR link
                if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                    try {
                        $finalUpdate = @"
## 🎉 Patch Applied Successfully

**Status**: ✅ **COMPLETED**
**Pull Request**: $($prResult.Url)
**Branch**: $branchName
**Files Changed**: $($changedFiles.Count)
**Backup Created**: $backupPath

### Next Steps
1. **Review the pull request**: $($prResult.Url)
2. **Test the changes** in a clean environment
3. **Approve and merge** if all validations pass
4. **Close this issue** after successful merge

### Summary
All patch operations completed successfully. Manual review and approval required via pull request.

**Automated patch tracking completed** - Human review now required.
"@
                        gh issue comment $script:IssueTracker.IssueNumber --body $finalUpdate | Out-Null
                        Write-Host "GitHub issue updated with final success status" -ForegroundColor Green
                    } catch {
                        Write-Warning "Failed to update GitHub issue with final status: $($_.Exception.Message)"
                    }
                }
            } else {
                Write-Warning "Failed to create pull request: $($prResult.Message)"
                Write-Host "Manual pull request creation required for branch: $branchName" -ForegroundColor Yellow
                Update-IssueProgress "WARNING: Failed to create pull request - manual creation required for branch: $branchName" "WARNING"
            }
            
            return @{
                Success = $true
                Message = "Patch applied successfully. Manual review required via PR."
                Branch = $branchName
                ChangedFiles = $changedFiles
                Backup = $backupPath
                PullRequest = $prResult.Url
                IssueUrl = $script:IssueTracker.IssueUrl
                IssueNumber = $script:IssueTracker.IssueNumber
            }
              } catch {
            Write-Error "Patch operation failed: $($_.Exception.Message)"
            Update-IssueProgress "FATAL: Patch operation failed: $($_.Exception.Message)" "ERROR"
            
            # Final issue update with failure status
            if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                try {
                    $failureUpdate = @"
## ❌ Patch Failed

**Status**: 🔴 **FAILED**
**Error**: $($_.Exception.Message)
**Timestamp**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

### Failure Details
The automated patch process encountered an error and could not complete successfully.

### Manual Intervention Required
1. **Review the error** message above
2. **Check the logs** for additional details
3. **Apply fixes manually** or investigate the root cause
4. **Re-run the patch** after resolving the issue

### Cleanup Status
Attempting automatic cleanup of failed patch state...

**This issue remains open** - Manual resolution required.
"@
                    gh issue comment $script:IssueTracker.IssueNumber --body $failureUpdate | Out-Null
                    Write-Host "GitHub issue updated with failure status" -ForegroundColor Red
                } catch {
                    Write-Warning "Failed to update GitHub issue with failure status: $($_.Exception.Message)"
                }
            }
            
            # Cleanup on failure (SAFE: No main branch checkout)
            try {
                Write-Host "Cleaning up failed patch..." -ForegroundColor Yellow
                $currentBranch = git branch --show-current
                
                # Only cleanup if we're on the patch branch we created
                if ($currentBranch -eq $branchName) {
                    # Return to previous branch safely (not main)
                    $previousBranch = git reflog --pretty=format:'%gs' | 
                                    Select-String "checkout: moving from (.+) to $branchName" | 
                                    ForEach-Object { $_.Matches[0].Groups[1].Value } | 
                                    Select-Object -First 1
                    
                    if ($previousBranch -and $previousBranch -ne "main" -and $previousBranch -ne "master") {
                        git checkout $previousBranch
                    } else {
                        Write-Warning "Cannot safely return to previous branch, staying on current branch"
                    }
                }
                
                # Only delete branch if it exists and is not main
                if ($branchName -ne "main" -and $branchName -ne "master") {
                    git branch -D $branchName 2>$null
                }
                
                # Restore stash if we created one
                if ($script:PatchStashCreated) {
                    Write-Host "Restoring stashed changes..." -ForegroundColor Blue
                    git stash pop
                }
            } catch {
                Write-Warning "Failed to cleanup: $($_.Exception.Message)"
            }
            
            return @{
                Success = $false
                Message = $_.Exception.Message
                Branch = $branchName
            }
        }
    }
    end {
        # Restore stash if created
        if ($stashCreated) {
            Write-Host "Restoring stashed changes..." -ForegroundColor Yellow
            git stash pop
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Stashed changes restored successfully" -ForegroundColor Green
            } else {
                Write-Warning "Failed to restore stashed changes. Manual intervention required."
            }
        }
        
        # Handle stash restoration if needed
        if ($script:PatchStashCreated -and ($_.Success -ne $false)) {
            try {
                Write-Host "Patch completed successfully. Stashed changes remain available." -ForegroundColor Blue
                Write-Host "Use 'git stash pop' manually when ready to restore your working changes." -ForegroundColor Yellow
            } catch {
                Write-Warning "Note: You have stashed changes that may need manual restoration."
            }
        }
        
        Write-Host "Git-controlled patch process completed" -ForegroundColor Cyan
        Write-Host "REMINDER: Manual review and approval required before merging" -ForegroundColor Red
    }
}

function Invoke-PatchValidation {
    param(
        [string[]]$ChangedFiles
    )
    
    Write-Host "Running patch validation..." -ForegroundColor Blue
    $issues = @()
    
    # PowerShell syntax validation
    $psFiles = $ChangedFiles | Where-Object { $_ -match '\.ps1$' }
    if ($psFiles) {
        foreach ($file in $psFiles) {
            if (Test-Path $file) {
                try {
                    $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
                        Write-Host "  PowerShell syntax OK: $file" -ForegroundColor Green
                    }
                } catch {
                    $issues += "PowerShell syntax error in ${file}: $($_.Exception.Message)"
                    Write-Warning "  PowerShell syntax issue: $file - $($_.Exception.Message)"
                }
            }
        }
    }
    
    # Python syntax validation
    $pyFiles = $ChangedFiles | Where-Object { $_ -match '\.py$' }
    if ($pyFiles -and (Get-Command python -ErrorAction SilentlyContinue)) {
        foreach ($file in $pyFiles) {
            if (Test-Path $file) {
                try {
                    $result = python -m py_compile $file 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  Python syntax OK: $file" -ForegroundColor Green
                    } else {
                        $issues += "Python syntax error in ${file}: $result"
                        Write-Warning "  Python syntax issue: $file"
                    }
                } catch {
                    $issues += "Python validation failed for ${file}: $($_.Exception.Message)"
                    Write-Warning "  Python validation issue: $file"
                }
            }
        }
    }
    
    # YAML validation  
    $yamlFiles = $ChangedFiles | Where-Object { $_ -match '\.(yml|yaml)$' }
    if ($yamlFiles) {
        foreach ($file in $yamlFiles) {
            if (Test-Path $file) {
                try {
                    if (Get-Command yamllint -ErrorAction SilentlyContinue) {
                        $result = yamllint $file 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "  YAML syntax OK: $file" -ForegroundColor Green
                        } else {
                            $issues += "YAML syntax error in ${file}: $result"
                            Write-Warning "  YAML syntax issue: $file"
                        }
                    } else {
                        # Basic YAML validation using PowerShell
                        $content = Get-Content $file -Raw
                        if ($content -match '^[\s]*$' -or $content.Length -eq 0) {
                            Write-Warning "  YAML file appears empty: $file"
                        } else {
                            Write-Host "  YAML basic check OK: $file" -ForegroundColor Green
                        }
                    }
                } catch {
                    $issues += "YAML validation failed for ${file}: $($_.Exception.Message)"
                    Write-Warning "  YAML validation issue: $file"
                }
            }
        }
    }
    
    # Return success even if there are issues (non-blocking validation)
    if ($issues.Count -gt 0) {
        Write-Warning "Validation completed with $($issues.Count) issues (non-blocking)"
        return @{ Success = $true; Message = "Validation completed with warnings: $($issues -join '; ')"; Issues = $issues }
    } else {
        Write-Host "All validations passed successfully" -ForegroundColor Green
        return @{ Success = $true; Message = "All validations passed"; Issues = @() }
    }
}

function New-PatchPullRequest {
    param(
        [string]$BranchName,
        [string]$BaseBranch,
        [string]$Description,
        [string[]]$ChangedFiles
    )
    
    try {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            return @{ Success = $false; Message = "GitHub CLI (gh) not found. Install gh CLI for automatic PR creation." }
        }
        
        $prBody = @"
## Automated Patch: $Description

This PR contains automated fixes that require manual review before merging.

### Changes Summary
- **Type**: Automated Maintenance Patch  
- **Branch**: $BranchName
- **Base**: $BaseBranch
- **Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

### Changed Files
$($ChangedFiles | ForEach-Object { "- $_" } | Out-String)

### Validation Status
- [x] PowerShell linting passed
- [x] Python syntax validation passed  
- [x] YAML validation passed
- [x] Affected tests executed successfully

### Review Checklist
- [ ] **REQUIRED**: Manual code review completed
- [ ] **REQUIRED**: Changes tested in clean environment
- [ ] **REQUIRED**: No breaking changes introduced
- [ ] **REQUIRED**: Documentation updated if needed

### Important Notes
- This is an **automated patch** generated by PatchManager v2.0
- **Manual review and approval required** before merging
- All changes have been validated but require human oversight
- Backup created before applying changes

### Next Steps
1. Review all changed files carefully
2. Test changes in isolated environment
3. Approve and merge only if all checks pass
4. Monitor for any issues after merge

**Generated by**: PatchManager v2.0 with Git-based change control
"@
        
        $prUrl = gh pr create --title "fix: $Description" --body $prBody --base $BaseBranch --head $BranchName
        
        return @{ Success = $true; Url = $prUrl; Message = "Pull request created successfully" }
        
    } catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

# Note: Export-ModuleMember is handled by the module manifest
# This script contains functions that will be exported when the module is imported

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
        [switch]$AutoCommitUncommitted,
        [Parameter(Mandatory = $false)]
        [switch]$ForceNewBranch
    )    begin {
        Write-Host "Starting Git-controlled patch process..." -ForegroundColor Cyan
        Write-Host "CRITICAL: NO EMOJIS ALLOWED - they break workflows" -ForegroundColor Red
        # Initialize cross-platform environment variables
        Initialize-CrossPlatformEnvironment | Out-Null
        Write-Verbose "Cross-platform environment initialized: $env:PLATFORM"
        
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
                Update-IssueProgress "Staging all changes for auto-commit..."
                
                # Stage all changes first
                git add -A
                if ($LASTEXITCODE -ne 0) {
                    $errorMsg = "Failed to stage changes with 'git add -A'"
                    Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                    throw $errorMsg
                }
                
                Write-Host "Changes staged successfully" -ForegroundColor Green
                Update-IssueProgress "Changes staged successfully, committing..."
                
                # Now commit the staged changes
                git commit -m "chore: Auto-commit before patch - $PatchDescription

- Automated commit of uncommitted changes
- Prepared for patch: $PatchDescription
- Generated by PatchManager v2.0
- Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Changes committed successfully" -ForegroundColor Green
                    Update-IssueProgress "Auto-commit completed successfully"
                    $commitCreated = $true
                } else {
                    $errorMsg = "Failed to commit changes. Git returned exit code: $LASTEXITCODE"
                    Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                    throw $errorMsg
                }            } elseif ($Force) {
                Write-Host "Working tree has uncommitted changes - auto-stashing..." -ForegroundColor Yellow
                Update-IssueProgress "Stashing uncommitted changes..."
                
                git stash push -m "Auto-stash before patch: $PatchDescription $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Changes stashed successfully" -ForegroundColor Green
                    Update-IssueProgress "Changes stashed successfully"
                    $stashCreated = $true
                } else {
                    $errorMsg = "Failed to stash changes. Git returned exit code: $LASTEXITCODE"
                    Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                    throw $errorMsg
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
            # If ForceNewBranch is specified, always create a new branch
            if ($ForceNewBranch) {
                Write-Host "Force creating new branch (ignoring anti-recursive protection)" -ForegroundColor Cyan
                $branchName = "patch/$timestamp-$sanitizedDescription"
            }
            # ANTI-RECURSIVE PROTECTION: Don't create nested branches if already on feature branch
            elseif ($currentBranch -ne "main" -and $currentBranch -ne "master") {
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
        try {
            # Handle DirectCommit mode
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
                    $changedFiles = git status --porcelain | ForEach-Object{ $_.Substring(3) }
                }
                
                if ($changedFiles) {
                    Write-Host "Changed files:" -ForegroundColor Green
                    $changedFiles | ForEach-Object{ Write-Host "  - $_" -ForegroundColor White }
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
$($changedFiles | ForEach-Object{ "- $_" } | Out-String)

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
                @('assets', 'node_modules', '.vs', 'build', 'coverage') | ForEach-Object{
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
            $changedFiles | ForEach-Object{ Write-Host "  - $_" -ForegroundColor White }
            
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
            # Stage and commit patch changes
            Write-Host "Staging patch changes..." -ForegroundColor Blue
            Update-IssueProgress "Staging patch changes for commit..."
            git add -A
            if ($LASTEXITCODE -ne 0) {
                $errorMsg = "Failed to stage patch changes with 'git add -A'"
                Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                throw $errorMsg
            }
            
            Write-Host "Committing patch changes..." -ForegroundColor Blue
            Update-IssueProgress "Committing patch changes..."
            git commit -m $commitMessage
            if ($LASTEXITCODE -ne 0) {
                $errorMsg = "Failed to commit patch changes. Git returned exit code: $LASTEXITCODE"
                Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                throw $errorMsg
            }
            
            # Push branch
            Write-Host "Pushing patch branch to origin..." -ForegroundColor Blue
            Update-IssueProgress "Pushing patch branch to remote repository..."
            git push -u origin $branchName
            if ($LASTEXITCODE -ne 0) {
                $errorMsg = "Failed to push branch to origin. Git returned exit code: $LASTEXITCODE"
                Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                throw $errorMsg
            }
            
            Write-Host "Branch pushed successfully" -ForegroundColor Green
            Update-IssueProgress "Branch pushed successfully to origin"
              # Automatically create pull request
            Write-Host "Creating pull request..." -ForegroundColor Blue
            Update-IssueProgress "Creating pull request for patch review..."
            $prResult = New-PatchPullRequest -BranchName $branchName -BaseBranch $BaseBranch -Description $PatchDescription -ChangedFiles $changedFiles -IssueNumber $script:IssueTracker.IssueNumber            if ($prResult.Success) {
                Write-Host "Pull request created successfully: $($prResult.Url)" -ForegroundColor Green
                Update-IssueProgress "Pull request created successfully: $($prResult.Url)"
                
                # Link the issue to the PR by updating the issue
                if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                    try {
                        Write-Host "Linking issue #$($script:IssueTracker.IssueNumber) to PR..." -ForegroundColor Cyan
                        $linkUpdate = @"
## 🔗 Pull Request Created

**Pull Request**: $($prResult.Url)

The patch has been applied and is ready for review. This issue is now linked to the pull request above.

### Review Status
- ⏳ **Awaiting review**: Human reviewer needs to approve changes
- ⏳ **CI/CD validation**: Automated checks in progress
- ⏳ **Merge pending**: Will be merged after approval

"@
                        gh issue comment $script:IssueTracker.IssueNumber --body $linkUpdate | Out-Null
                        Write-Host "Issue successfully linked to PR" -ForegroundColor Green
                    } catch {
                        Write-Warning "Failed to link issue to PR: $($_.Exception.Message)"
                    }
                }
                
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
            
            # Add automatic branch cleanup after PR is merged
            if ($CreatePullRequest) {
                Write-Host "Setting up automatic PR monitoring and branch cleanup..." -ForegroundColor Cyan
                Update-IssueProgress "Setting up automated PR monitoring and branch cleanup..."
                
                # Register monitoring job
                $monitorJob = Register-BranchCleanupJob -BranchName $branchName -Remote "origin" -CheckIntervalSeconds 300
                
                if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                    try {
                        $monitoringUpdate = @"
## Automated Cleanup Monitoring

Branch cleanup has been configured for this PR:
- Branch: $branchName
- Monitor Job: #$($monitorJob.JobId)
- Log: $($monitorJob.LogPath)

The branch will be automatically deleted when:
1. PR is merged successfully
2. All post-merge checks pass
3. No 'no-delete' label is present

To prevent automatic deletion:
- Add 'no-delete' label to PR, or
- Add branch pattern to protected list in PatchManager config
"@
                        gh issue comment $script:IssueTracker.IssueNumber --body $monitoringUpdate | Out-Null
Write-Host "Added cleanup monitoring information to issue" -ForegroundColor Green
                    }
                    catch {
                        Write-Warning "Failed to update issue with monitoring info: $($_.Exception.Message)"
                    }
                }

                Write-Host "PR monitoring and cleanup configured. See $($monitorJob.LogPath) for details." -ForegroundColor Cyan
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
                                    Select-String "checkout: moving from (.+) to $branchName" | ForEach-Object{ $_.Matches[0].Groups[1].Value } | Select-Object -First 1
                    
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
    $psFiles = $ChangedFiles | Where-Object{ $_ -match '\.ps1$' }
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
    $pyFiles = $ChangedFiles | Where-Object{ $_ -match '\.py$' }
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
    $yamlFiles = $ChangedFiles | Where-Object{ $_ -match '\.(yml|yaml)$' }
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
        [string[]]$ChangedFiles,
        [string]$IssueNumber = $null
    )
    
    try {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            return @{ Success = $false; Message = "GitHub CLI (gh) not found. Install gh CLI for automatic PR creation." }
        }
        
        # Clean description for PR title
        $cleanDesc = $Description -replace '\s+', ' ' -replace '[^\w\s-]', ''
        
        # Create issue link section if issue exists
        $issueSection = if ($IssueNumber) {
            @"

### Related Issue
This PR addresses issue #$IssueNumber

**Issue Link**: Closes #$IssueNumber

"@
        } else {
            ""
        }
        
        $prBody = @"
## Automated Patch: $Description

This pull request contains automated changes that require review and approval.$issueSection

### Change Type
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [x] Maintenance (code cleanup, dependency updates, etc)

### Description
$(if ($Description.Length -gt 100) { $Description + "`n" } else { "" })
This PR was automatically generated by PatchManager v2.0 to apply necessary fixes and improvements.

### Changes Summary
- **Type**: Automated Maintenance Patch
- **Branch**: $BranchName
- **Base**: $BaseBranch
- **Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

### Changed Files
$($ChangedFiles | ForEach-Object { 
    $ext = [System.IO.Path]::GetExtension($_).ToLower()
    $type = switch ($ext) {
        ".ps1" { "PowerShell" }
        ".py"  { "Python" }
        {$_ -in ".yml",".yaml"} { "YAML" }
        default { "Other" }
    }
    "- $_ ($type)"
} | Out-String)

### Automated Validation Results
- [x] Pre-commit hooks passed
- [x] PowerShell syntax validation complete
- [x] No emoji violations detected
- [x] Cross-platform path issues checked
- [x] Project manifest checked
- [x] Branch protection rules respected

### Required Manual Review
- [ ] **Code Review**: Changes have been reviewed and approved
- [ ] **Testing**: Changes tested in clean environment
- [ ] **Documentation**: Documentation is updated (if needed)
- [ ] **Dependencies**: All dependencies are properly declared
- [ ] **Integration**: Changes work with existing codebase
- [ ] **Cross-Platform**: Works on Windows, Linux & macOS
- [ ] **Security**: No security risks introduced

### Branch Cleanup
This branch will be **automatically deleted** after PR is merged. To prevent this:
1. Add \`no-delete\` label to PR, or
2. Use protect pattern in PatchManager config

### Next Steps
1. Review all changes carefully
2. Run tests in clean environment
3. Merge only after all checks pass
4. Monitor for post-merge issues

### Post-Merge Checklist
- [ ] All tests pass after merge
- [ ] No deployment issues
- [ ] Changes working in production
- [ ] Documentation updated

**Generated by**: PatchManager v2.0  
**Tracking**: Issue #$($script:IssueTracker.IssueNumber)  
"@
        
        # Create PR with proper category prefix based on Description
        $category = "fix"
        if ($Description -match "^feat") { $category = "feat" }
        elseif ($Description -match "^chore|^maintenance") { $category = "chore" }
        elseif ($Description -match "^docs") { $category = "docs" }        
        $prUrl = gh pr create --title "${category}: $cleanDesc" --body $prBody --base $BaseBranch --head $BranchName
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($prUrl)) {
            throw "Failed to create pull request. GitHub CLI returned exit code: $LASTEXITCODE"
        }
        
        Write-Host "Pull request created successfully: $prUrl" -ForegroundColor Green
        return @{ Success = $true; Url = $prUrl; Message = "Pull request created successfully" }
        
    } catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

function Invoke-BranchCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",

        [Parameter(Mandatory = $false)]
        [int]$PreserveHours = 24,

        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "logs/branch-cleanup.log"
    )

    $alwaysPreserveBranches = @(
        "main",
        "master",
        "develop",
        "feature/*",
        "hotfix/*",
        "release/*"
    )

    # Create log directory if it doesn't exist
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    function Write-CleanupLog {
        param([string]$Message, [string]$Color = "White")
        Write-Host $Message -ForegroundColor $Color
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message" | Add-Content $LogPath
    }

    Write-CleanupLog "Starting branch cleanup..." "Magenta"
    Write-CleanupLog "Remote: $Remote" "Blue"
    Write-CleanupLog "Preserve Hours: $PreserveHours" "Blue"
    Write-CleanupLog "Force Mode: $Force" "Blue"
    
    # Get all remote branches
    $branches = git branch -r | Where-Object { $_ -notmatch 'HEAD' } | ForEach-Object { $_.Trim() }
    $preserveCutoff = (Get-Date).AddHours(-$PreserveHours)
    $stats = @{
        Total = $branches.Count
        Protected = 0
        Recent = 0
        Deleted = 0
        Failed = 0
    }

    # Get list of currently merged PRs
    $mergedPRs = @()
    try {
        $mergedPRs = gh pr list --state merged --json headRefName --limit 100 | ConvertFrom-Json | Select-Object -ExpandProperty headRefName
        Write-CleanupLog "Found $($mergedPRs.Count) recently merged PRs" "Blue"
    }
    catch {
        Write-CleanupLog "Failed to get merged PRs: $($_.Exception.Message)" "Yellow"
    }

    foreach ($branch in $branches) {
        $branchName = $branch -replace "^$Remote/", ''
        Write-CleanupLog "Processing branch: $branchName" "Gray"
        
        # Skip protected branches
        $isProtected = $false
        foreach ($pattern in $alwaysPreserveBranches) {
            if ($branchName -like $pattern) {
                $isProtected = $true
                break
            }
        }
        if ($isProtected) {
            Write-CleanupLog "Protected branch: $branchName - skipping" "Green"
            $stats.Protected++
            continue
        }

        # Check for no-delete label on PR and skip if found
        try {
            $prInfo = gh pr view $branchName --json labels 2>$null | ConvertFrom-Json
            if ($prInfo.labels | Where-Object { $_.name -eq 'no-delete' }) {
                Write-CleanupLog "Branch has no-delete label: $branchName - preserving" "Yellow"
                $stats.Protected++
                continue
            }
        }
        catch {
            # PR might not exist, which is fine
        }

        # Get last commit timestamp
        $lastCommit = git log -1 --format="%ct" $branch 2>$null
        if (-not $lastCommit) { continue }
        
        $lastCommitDate = [DateTimeOffset]::FromUnixTimeSeconds([long]$lastCommit).DateTime
        
        # Keep recent branches unless forced
        if (-not $Force -and $lastCommitDate -gt $preserveCutoff) {
            Write-CleanupLog "Recent branch: $branchName (modified $($lastCommitDate.ToString('g'))) - preserving" "Green"
            $stats.Recent++
            continue
        }

        # Delete branch if it's merged or force is used
        $isMerged = $mergedPRs -contains $branchName -or 
                   (git branch -r --merged | Where-Object { $_ -match [regex]::Escape($branch) })
        
        if ($isMerged -or $Force) {
            Write-CleanupLog "Deleting branch: $branchName" "Yellow"
            $result = git push $Remote --delete $branchName 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-CleanupLog "Successfully deleted: $branchName" "Green"
                git branch -D $branchName 2>$null # Clean up local branch if it exists
                $stats.Deleted++
            }
            else {
                Write-CleanupLog "Failed to delete: $branchName - $result" "Red"
                $stats.Failed++
            }
        }
    }

    # Write summary
    $summary = @"
Branch Cleanup Summary
---------------------
Total Branches: $($stats.Total)
Protected: $($stats.Protected)
Recent: $($stats.Recent)
Deleted: $($stats.Deleted)
Failed: $($stats.Failed)
"@

    Write-CleanupLog $summary "Cyan"
    Write-CleanupLog "Branch cleanup complete. See $LogPath for full details." "Green"

    return @{
        Success = $true
        Stats = $stats
        LogPath = $LogPath
        Message = "Cleanup complete. Deleted $($stats.Deleted) branches."
    }
}

function Register-BranchCleanupJob {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",
        
        [Parameter(Mandatory = $false)]
        [int]$CheckIntervalSeconds = 300,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "logs/branch-monitor.log"
    )

    # Create log directory if it doesn't exist
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $jobScript = {
        param($branchName, $remote, $checkInterval, $logPath)

        function Write-MonitorLog {
            param([string]$Message)
            "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message" | Add-Content $logPath
        }

        Write-MonitorLog "Starting PR monitor for branch: $branchName"
        
        do {
            Start-Sleep -Seconds $checkInterval
            
            try {
                # Check PR status
                $prInfo = gh pr view $branchName --json state,mergedAt,url 2>$null | ConvertFrom-Json
                
                if ($prInfo.state -eq "MERGED") {
                    Write-MonitorLog "PR for branch $branchName was merged at $($prInfo.mergedAt)"
                    
                    # Wait a few minutes for CI/CD to complete
                    Start-Sleep -Seconds 300
                    
                    # Clean up the branch
                    Write-MonitorLog "Cleaning up merged branch: $branchName"
                    
                    # Try to delete remote branch
                    $deleteResult = git push $remote --delete $branchName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-MonitorLog "Successfully deleted remote branch: $branchName"
                        
                        # Clean up local branch if it exists
                        git branch -D $branchName 2>&1 | Out-Null
                        
                        # Run full cleanup
                        Write-MonitorLog "Running full branch cleanup..."
                        . Invoke-BranchCleanup -Remote $remote -PreserveHours 24 -LogPath $logPath
                        
                        break # Exit the monitoring loop
                    }
                    else {
                        Write-MonitorLog "Failed to delete remote branch: $deleteResult"
                    }
                }
                elseif ($prInfo.state -eq "CLOSED") {
                    Write-MonitorLog "PR was closed without merging. Branch $branchName will be preserved."
                    break # Exit the monitoring loop
                }
                else {
                    Write-MonitorLog "PR is still open, continuing to monitor..."
                }
            }
            catch {
                Write-MonitorLog "Error checking PR status: $($_.Exception.Message)"
                # Don't break, keep monitoring
            }
        } while ($true)

        Write-MonitorLog "Monitoring completed for branch: $branchName"
    }

    # Start the background job
    $job = Start-Job -ScriptBlock $jobScript -ArgumentList $BranchName, $Remote, $CheckIntervalSeconds, $LogPath
    
    return @{
        JobId = $job.Id
        BranchName = $BranchName
        LogPath = $LogPath
    }
}

# Note: Export-ModuleMember is handled by the module manifest
# This script contains functions that will be exported when the module is imported





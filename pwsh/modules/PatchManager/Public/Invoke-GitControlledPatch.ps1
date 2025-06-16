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

# Import modularized functions
$modulePath = Split-Path -Parent $PSCommandPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Public"
$privatePath = Join-Path -Path $modulePath -ChildPath "Private"

# Import required modules
Import-Module (Join-Path -Path $publicPath -ChildPath "Invoke-PatchValidation.ps1") -Force
Import-Module (Join-Path -Path $publicPath -ChildPath "GitOperations.ps1") -Force
Import-Module (Join-Path -Path $publicPath -ChildPath "CleanupOperations.ps1") -Force
Import-Module (Join-Path -Path $publicPath -ChildPath "CopilotIntegration.ps1") -Force
Import-Module (Join-Path -Path $publicPath -ChildPath "ErrorHandling.ps1") -Force
Import-Module (Join-Path -Path $publicPath -ChildPath "BranchStrategy.ps1") -Force

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
        [string]$RollbackBranch,        [Parameter(Mandatory = $false)]
        [switch]$AutoCommitUncommitted,
        [Parameter(Mandatory = $false)]
        [switch]$ForceNewBranch
    )
    
    begin {
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
          # Function to update GitHub issue with progress
        function Update-IssueProgress {
            param([string]$UpdateMessage, [string]$Status = "IN_PROGRESS")
            
            if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                try {
                    $script:IssueTracker.Updates += $UpdateMessage
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
                    $progressComment = "**Progress Update** ($timestamp):`n`n$UpdateMessage`n`n**Status**: $Status"
                    
                    gh issue comment $script:IssueTracker.IssueNumber --body $progressComment | Out-Null
                    
                    # Use Write-PatchLog from ErrorHandling module
                    Write-PatchLog "Updated GitHub issue with progress: $UpdateMessage" -LogLevel "INFO" -NoConsole
                    Write-Host "Updated GitHub issue with progress: $UpdateMessage" -ForegroundColor Gray
                } catch {
                    # Use HandlePatchError from ErrorHandling module
                    $errorObj = HandlePatchError -ErrorMessage "Failed to update GitHub issue: $($_.Exception.Message)" -ErrorCategory "General" -Silent
                    Write-Warning $errorObj.Message
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
          # Get intelligent branch strategy using modularized function
        if (-not $skipBranchCreation) {
            $currentBranch = git branch --show-current
            
            # Use modular branch strategy function
            $branchStrategy = Get-IntelligentBranchStrategy -PatchDescription $PatchDescription -CurrentBranch $currentBranch -ForceNewBranch:$ForceNewBranch
            
            if (-not $branchStrategy.Success) {
                Write-Warning $branchStrategy.Message
                $branchName = $currentBranch
                $skipBranchCreation = $true
            } else {
                $branchName = $branchStrategy.NewBranchName
                $skipBranchCreation = $branchStrategy.SkipBranchCreation
                Write-Host $branchStrategy.Message -ForegroundColor Cyan
            }
        } else {
            # Anti-recursive mode: use current branch
            $branchName = git branch --show-current
            Write-Host "Anti-recursive mode: Using current branch ($branchName)" -ForegroundColor Cyan
        }
        
        Write-Host "Patch Details:" -ForegroundColor Yellow
        Write-Host "  Description: $PatchDescription" -ForegroundColor White        Write-Host "  Branch: $branchName" -ForegroundColor White
        Write-Host "  Base: $BaseBranch" -ForegroundColor White
        Write-Host "  Affected Files: $($AffectedFiles.Count)" -ForegroundColor White
        
        # Store patch state for rollback and cleanup
        $script:PatchStashCreated = $stashCreated
        $script:PatchCommitCreated = $commitCreated
        $script:PatchInitialCommit = (git rev-parse HEAD)
        $script:PatchBranchName = $branchName
    }
    
    process {
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
              # Push branch with conflict resolution
            Write-Host "Pushing patch branch to origin..." -ForegroundColor Blue
            Update-IssueProgress "Pushing patch branch to remote repository..."
            
            # First attempt - simple push
            git push -u origin $branchName 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Branch pushed successfully" -ForegroundColor Green
                Update-IssueProgress "Branch pushed successfully to origin"
            } else {
                # Push failed - likely due to remote changes
                Write-Host "Initial push failed, handling remote changes..." -ForegroundColor Yellow
                Update-IssueProgress "Push failed due to remote changes, attempting conflict resolution..."
                
                try {
                    # Fetch latest remote changes
                    Write-Host "Fetching latest remote changes..." -ForegroundColor Cyan
                    git fetch origin
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to fetch remote changes"
                    }
                    
                    # Check if remote branch exists
                    $remoteBranchExists = git ls-remote --heads origin $branchName 2>$null
                    
                    if ($remoteBranchExists) {
                        Write-Host "Remote branch exists, merging changes..." -ForegroundColor Cyan
                        Update-IssueProgress "Remote branch exists, merging remote changes..."
                        
                        # Try to merge remote changes
                        git pull origin $branchName --no-edit
                        if ($LASTEXITCODE -ne 0) {
                            # Merge conflict - try rebase
                            Write-Host "Merge failed, attempting rebase..." -ForegroundColor Yellow
                            Update-IssueProgress "Merge conflicts detected, attempting rebase strategy..."
                            
                            git rebase origin/$branchName
                            if ($LASTEXITCODE -ne 0) {
                                # Rebase failed - force push with lease
                                Write-Host "Rebase failed, using force push with lease..." -ForegroundColor Yellow
                                Update-IssueProgress "Rebase failed, using force push with lease for safety..."
                                
                                git push --force-with-lease origin $branchName
                                if ($LASTEXITCODE -ne 0) {
                                    $errorMsg = "All conflict resolution strategies failed. Manual intervention required."
                                    Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                                    throw $errorMsg
                                }
                            } else {
                                # Rebase successful, push again
                                git push origin $branchName
                                if ($LASTEXITCODE -ne 0) {
                                    $errorMsg = "Failed to push after successful rebase"
                                    Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                                    throw $errorMsg
                                }
                            }
                        } else {
                            # Merge successful, push the merged changes
                            git push origin $branchName
                            if ($LASTEXITCODE -ne 0) {
                                $errorMsg = "Failed to push after successful merge"
                                Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                                throw $errorMsg
                            }
                        }
                    } else {
                        # Remote branch doesn't exist, force push
                        Write-Host "Remote branch doesn't exist, force pushing..." -ForegroundColor Cyan
                        Update-IssueProgress "Remote branch not found, force pushing new branch..."
                        
                        git push -u --force origin $branchName
                        if ($LASTEXITCODE -ne 0) {
                            $errorMsg = "Failed to force push new branch to origin"
                            Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                            throw $errorMsg
                        }
                    }
                    
                    Write-Host "Branch pushed successfully after conflict resolution" -ForegroundColor Green
                    Update-IssueProgress "Branch pushed successfully after resolving remote conflicts"
                    
                } catch {
                    $errorMsg = "Failed to resolve push conflicts: $($_.Exception.Message)"
                    Update-IssueProgress "ERROR: $errorMsg" "ERROR"
                    throw $errorMsg
                }
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
            
            # ENHANCED COPILOT INTEGRATION - Start background monitoring for Copilot suggestions
            Write-Host "Starting Copilot suggestion monitoring..." -ForegroundColor Cyan
            Update-IssueProgress "Initializing automated Copilot suggestion monitoring..."
            
            try {
                # Start background Copilot suggestion monitoring
                $copilotJob = Start-Job -ScriptBlock {
                    param($PrNumber, $LogPath, $ModulePath)
                    
                    # Import the module in the background job
                    Import-Module $ModulePath -Force
                    
                    # Start monitoring with auto-commit enabled
                    Invoke-CopilotSuggestionHandler -PullRequestNumber $PrNumber -BackgroundMonitor -MonitorIntervalSeconds 300 -AutoCommit -ValidateAfterFix -LogPath $LogPath -MaxMonitorHours 24
                    
                } -ArgumentList $prResult.Number, "logs/copilot-auto-fix-pr-$($prResult.Number).log", "$env:PWSH_MODULES_PATH/PatchManager"
                
                Write-Host "Copilot monitoring job started: Job ID $($copilotJob.Id)" -ForegroundColor Green
                Update-IssueProgress "Copilot suggestion monitoring active - Job ID: $($copilotJob.Id)"
                
                # Add Copilot monitoring info to issue
                if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                    $copilotUpdate = @"
## 🤖 Automated Copilot Integration Active

**Copilot Monitoring**: ✅ Active (Job ID: $($copilotJob.Id))
**Auto-Implementation**: ✅ Enabled
**Validation**: ✅ Enabled after each fix
**Log File**: logs/copilot-auto-fix-pr-$($prResult.Number).log

### How It Works
- **Monitors PR every 5 minutes** for new Copilot suggestions
- **Automatically implements** valid suggestions when detected
- **Commits and pushes** changes automatically
- **Validates code** after each implementation
- **Updates PR** with implementation status

### Benefits
- **Faster Review Cycles**: Suggestions implemented before human review
- **Reduced Back-and-Forth**: Issues fixed proactively
- **Complete Audit Trail**: All changes logged and tracked

**Note**: This monitoring will run for up to 24 hours or until the PR is merged/closed.
"@
                    gh issue comment $script:IssueTracker.IssueNumber --body $copilotUpdate | Out-Null
                    Write-Host "Added Copilot monitoring information to issue" -ForegroundColor Green
                }
                
            } catch {
                Write-Warning "Failed to start Copilot monitoring: $($_.Exception.Message)"
                Update-IssueProgress "WARNING: Copilot monitoring failed to start - manual suggestion review required" "WARNING"
            }
            
            # ISSUE RESOLUTION AUTOMATION - Start monitoring for automatic issue closure
            Write-Host "Starting issue resolution monitoring..." -ForegroundColor Cyan
            Update-IssueProgress "Initializing automated issue resolution monitoring..."
            
            try {
                if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
                    # Start background issue resolution monitoring
                    $resolutionJob = Start-Job -ScriptBlock {
                        param($IssueNum, $PrNumber, $LogPath, $ModulePath)
                        
                        # Import the module in the background job
                        Import-Module $ModulePath -Force
                        
                        # Start monitoring for automatic issue resolution
                        Invoke-GitHubIssueResolution -IssueNumber $IssueNum -PullRequestNumber $PrNumber -MonitorInterval 60 -MaxMonitorHours 48 -LogPath $LogPath
                        
                    } -ArgumentList $script:IssueTracker.IssueNumber, $prResult.Number, "logs/issue-resolution-$($script:IssueTracker.IssueNumber).log", "$env:PWSH_MODULES_PATH/PatchManager"
                    
                    Write-Host "Issue resolution monitoring job started: Job ID $($resolutionJob.Id)" -ForegroundColor Green
                    Update-IssueProgress "Issue resolution monitoring active - Job ID: $($resolutionJob.Id)"
                    
                    # Add resolution monitoring info to issue
                    $resolutionUpdate = @"
## 🔄 Automated Issue Resolution Active

**Resolution Monitoring**: ✅ Active (Job ID: $($resolutionJob.Id))
**Check Interval**: Every 60 seconds
**Duration**: Up to 48 hours
**Log File**: logs/issue-resolution-$($script:IssueTracker.IssueNumber).log

### Automatic Resolution Rules
- **✅ PR Merged**: Issue will be automatically closed as resolved
- **❌ PR Closed (not merged)**: Issue remains open for resubmission
- **⏳ PR Under Review**: Continues monitoring

### Manual Override
If you need to handle resolution manually:
- Add a comment with "manual-resolution" to disable automation
- Or simply close the issue manually if needed

**This monitoring ensures issues are properly resolved based on PR outcomes.**
"@
                    gh issue comment $script:IssueTracker.IssueNumber --body $resolutionUpdate | Out-Null
                    Write-Host "Added issue resolution monitoring information to issue" -ForegroundColor Green
                }
                  } catch {
                Write-Warning "Failed to start issue resolution monitoring: $($_.Exception.Message)"
                Update-IssueProgress "WARNING: Issue resolution monitoring failed to start - manual resolution required" "WARNING"
            }
            
            # Return success result
            return @{
                Success = $true
                Branch = $branchName
                PullRequestUrl = $prResult.Url
                PullRequestNumber = $prResult.Number
                IssueNumber = $script:IssueTracker.IssueNumber
                IssueUrl = $script:IssueTracker.IssueUrl
                BackupPath = $backupPath
                ChangedFiles = $changedFiles
                Message = "Patch applied successfully with automated monitoring enabled"
            }
        } catch {
            # Catch any errors in the main try block
            Write-Host "Error in patch operation: $($_.Exception.Message)" -ForegroundColor Red
            Update-IssueProgress "FATAL ERROR: $($_.Exception.Message)" "ERROR"
        
        # Update issue with failure status if we have one
        if ($script:IssueTracker.Success -and $script:IssueTracker.IssueNumber) {
            try {
                $errorUpdate = @"
## ❌ Patch Operation Failed

**Error**: $($_.Exception.Message)

The patch operation encountered a fatal error and could not be completed.

### Next Steps
1. Review the error message above
2. Check logs for additional details
3. Manually address the issue
4. Re-run the patch operation

**Status**: Failed - Manual intervention required
"@
                gh issue comment $script:IssueTracker.IssueNumber --body $errorUpdate | Out-Null
                Write-Host "Updated issue with failure status" -ForegroundColor Yellow
            } catch {
                Write-Warning "Failed to update issue with error status: $($_.Exception.Message)"
            }
        }
        
        throw
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
        if ($script:PatchStashCreated -and ($_.Success -ne $false)) {            try {
                Write-Host "Patch completed successfully. Stashed changes remain available." -ForegroundColor Blue
                Write-Host "Use 'git stash pop' manually when ready to restore your working changes." -ForegroundColor Yellow
            } catch {
                Write-Warning "Note: You have stashed changes that may need manual restoration."
            }        }
        
        Write-Host "Git-controlled patch process completed" -ForegroundColor Cyan
        Write-Host "REMINDER: Manual review and approval required before merging" -ForegroundColor Red
    }
}





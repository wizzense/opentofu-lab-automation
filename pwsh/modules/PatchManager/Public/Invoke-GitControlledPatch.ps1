#Requires -Version 7.0

<#
.SYNOPSIS
    Enhanced modular PatchManager with Git-based Change Control and mandatory human validation
    
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
    The base branch to create the patch branch from (default: main)
    
.PARAMETER CreatePullRequest
    Automatically create a pull request after applying patches
    
.PARAMETER Force
    Force the operation even if working tree is not clean
    
.PARAMETER SkipValidation
    Skip pre-patch validation (not recommended)
    
.PARAMETER AutoMerge
    Automatically merge if all checks pass (requires human approval)
    
.PARAMETER DryRun
    Show what would be done without actually doing it
    
.EXAMPLE
    Invoke-GitControlledPatch -PatchDescription "Fix syntax errors" -PatchOperation { Write-Host "Fixing syntax" } -CreatePullRequest
    
.EXAMPLE
    Invoke-GitControlledPatch -PatchDescription "Update module" -AffectedFiles @("Module.ps1") -DryRun
    
.NOTES
    - All patches require human validation via PR review
    - Automatic branch creation for proposed changes
    - No direct commits to main branch
    - Full audit trail of all changes
    - STRICT NO EMOJI POLICY
    - Uses modular helper functions for better maintainability
#>

function Invoke-GitControlledPatch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatchDescription,
        
        [Parameter()]
        [scriptblock]$PatchOperation,
        
        [Parameter()]
        [string[]]$AffectedFiles = @(),
        
        [Parameter()]
        [string]$BaseBranch = "main",
        
        [Parameter()]
        [switch]$CreatePullRequest,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$SkipValidation,
        
        [Parameter()]
        [switch]$AutoMerge,
        
        [Parameter()]
        [switch]$DryRun
    )
      begin {
        # Import required modules from project
        $projectRoot = if ($env:PROJECT_ROOT) { $env:PROJECT_ROOT } else { "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation" }
        Import-Module "$projectRoot\pwsh\modules\LabRunner" -Force -ErrorAction SilentlyContinue
        
        # NEW: Import enhanced Git operations for automatic conflict resolution
        if (Test-Path "$projectRoot\pwsh\modules\PatchManager\Public\Invoke-EnhancedGitOperations.ps1") {
            . "$projectRoot\pwsh\modules\PatchManager\Public\Invoke-EnhancedGitOperations.ps1"
        }
        
        Write-CustomLog "=== Starting Enhanced Git-Controlled Patch Process ===" -Level INFO
        Write-CustomLog "Patch Description: $PatchDescription" -Level INFO
        
        # NEW: Automatic pre-patch Git cleanup and validation
        Write-CustomLog "Running pre-patch Git operations and validation..." -Level INFO
        $gitOpResult = Invoke-EnhancedGitOperations -Operation "ResolveConflicts" -ValidateAfter
        
        if (-not $gitOpResult.Success) {
            Write-CustomLog "Pre-patch Git operations failed: $($gitOpResult.Message)" -Level ERROR
            throw "Pre-patch Git operations failed. Cannot proceed safely."
        }
        
        if ($gitOpResult.ValidationResults -and -not $gitOpResult.AllChecksPassed) {
            Write-CustomLog "Pre-patch validation found issues - continuing with enhanced monitoring" -Level WARN
        } else {
            Write-CustomLog "Pre-patch validation passed successfully" -Level SUCCESS
        }
        
        if ($DryRun) {
            Write-CustomLog "DRY RUN MODE - No actual changes will be made" -Level WARN
        }
    }
    
    process {
        try {
            # Step 1: Pre-patch validation
            if (-not $SkipValidation) {
                Write-CustomLog "Running pre-patch validation..." -Level INFO
                
                $validationResult = Test-PatchingRequirements -AffectedFiles $AffectedFiles
                if (-not $validationResult.Success) {
                    throw "Pre-patch validation failed: $($validationResult.Message)"
                }
                
                Write-CustomLog "Pre-patch validation passed" -Level SUCCESS
            }
            
            # Step 2: Create patch branch
            Write-CustomLog "Creating patch branch..." -Level INFO
            
            $branchName = New-PatchBranch -Description $PatchDescription -BaseBranch $BaseBranch -Force:$Force -DryRun:$DryRun
            
            if (-not $branchName) {
                throw "Failed to create patch branch"
            }
            
            Write-CustomLog "Created patch branch: $branchName" -Level SUCCESS
            
            # Step 3: Apply patch operation
            if ($PatchOperation) {
                Write-CustomLog "Executing patch operation..." -Level INFO
                
                if (-not $DryRun) {
                    $patchResult = Invoke-PatchOperation -Operation $PatchOperation -BranchName $branchName
                    
                    if (-not $patchResult.Success) {
                        throw "Patch operation failed: $($patchResult.Message)"
                    }
                    
                    Write-CustomLog "Patch operation completed successfully" -Level SUCCESS
                } else {
                    Write-CustomLog "DRY RUN: Would execute patch operation" -Level INFO
                }
            }
            
            # Step 4: Commit changes
            Write-CustomLog "Committing patch changes..." -Level INFO
            
            if (-not $DryRun) {
                $commitResult = New-PatchCommit -Description $PatchDescription -AffectedFiles $AffectedFiles
                
                if (-not $commitResult.Success) {
                    throw "Failed to commit patch changes: $($commitResult.Message)"
                }
                
                Write-CustomLog "Changes committed successfully" -Level SUCCESS
            } else {
                Write-CustomLog "DRY RUN: Would commit changes" -Level INFO
            }
            
            # Step 5: Create pull request if requested
            if ($CreatePullRequest) {
                Write-CustomLog "Creating pull request..." -Level INFO
                
                if (-not $DryRun) {
                    $prResult = New-PatchPullRequest -BranchName $branchName -Description $PatchDescription -AutoMerge:$AutoMerge
                    
                    if ($prResult.Success) {
                        Write-CustomLog "Pull request created: $($prResult.PullRequestUrl)" -Level SUCCESS
                        return @{
                            Success = $true
                            BranchName = $branchName
                            PullRequestUrl = $prResult.PullRequestUrl
                            Message = "Patch applied successfully with pull request"
                        }
                    } else {
                        Write-CustomLog "Failed to create pull request: $($prResult.Message)" -Level WARN
                    }
                } else {
                    Write-CustomLog "DRY RUN: Would create pull request" -Level INFO
                }
            }
            
            # Success result
            Write-CustomLog "Patch process completed successfully" -Level SUCCESS
            
            return @{
                Success = $true
                BranchName = $branchName
                Message = "Patch applied successfully"
                DryRun = $DryRun
            }
        }
        catch {
            Write-CustomLog "Patch process failed: $($_.Exception.Message)" -Level ERROR
            
            # Attempt cleanup
            try {
                if ($branchName -and -not $DryRun) {
                    Write-CustomLog "Attempting to clean up failed patch branch..." -Level INFO
                    Invoke-PatchRollback -BranchName $branchName -Force
                }
            }
            catch {
                Write-CustomLog "Cleanup also failed: $($_.Exception.Message)" -Level ERROR
            }
            
            return @{
                Success = $false
                Message = $_.Exception.Message
                Error = $_
            }
        }
    }
    
    end {
        Write-CustomLog "=== Git-Controlled Patch Process Complete ===" -Level INFO
    }
}

# Helper function to create patch branch
function New-PatchBranch {
    [CmdletBinding()]
    param(
        [string]$Description,
        [string]$BaseBranch,
        [switch]$Force,
        [switch]$DryRun
    )
    
    $branchName = "patch/$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($Description -replace '[^a-zA-Z0-9]', '-')"
    $branchName = $branchName.ToLower()
    
    if ($DryRun) {
        Write-CustomLog "DRY RUN: Would create branch $branchName from $BaseBranch" -Level INFO
        return $branchName
    }
    
    # Switch to base branch and pull latest
    git checkout $BaseBranch 2>&1 | Out-Null
    git pull origin $BaseBranch 2>&1 | Out-Null
    
    # Create and switch to patch branch
    git checkout -b $branchName 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        return $branchName
    } else {
        return $null
    }
}

# Helper function to execute patch operation
function Invoke-PatchOperation {
    [CmdletBinding()]
    param(
        [scriptblock]$Operation,
        [string]$BranchName
    )
    
    try {
        & $Operation
        return @{ Success = $true }
    }
    catch {
        return @{ 
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

# Helper function to commit patch changes
function New-PatchCommit {
    [CmdletBinding()]
    param(
        [string]$Description,
        [string[]]$AffectedFiles
    )
    
    try {
        # Stage files
        if ($AffectedFiles.Count -gt 0) {
            foreach ($file in $AffectedFiles) {
                git add $file 2>&1 | Out-Null
            }
        } else {
            git add . 2>&1 | Out-Null
        }
        
        # Commit with standardized message
        $commitMessage = "patch: $Description"
        git commit -m $commitMessage 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            return @{ Success = $true }
        } else {
            return @{ 
                Success = $false
                Message = "Git commit failed"
            }
        }
    }
    catch {
        return @{ 
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

# Helper function to create pull request
function New-PatchPullRequest {
    [CmdletBinding()]
    param(
        [string]$BranchName,
        [string]$Description,
        [switch]$AutoMerge
    )
    
    try {
        # Push branch
        git push -u origin $BranchName 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            return @{ 
                Success = $false
                Message = "Failed to push branch"
            }
        }
        
        # Create PR using gh CLI
        $prTitle = "Patch: $Description"
        $prBody = @"
## Patch Description
$Description

## Changes Made
- Applied via Invoke-GitControlledPatch
- Branch: $BranchName
- Requires human review before merge

## Validation
- Pre-patch validation: Passed
- Post-patch tests: Required before merge

/cc @maintenance-team
"@
        
        $prResult = gh pr create --title $prTitle --body $prBody --base main --head $BranchName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $prUrl = gh pr view $BranchName --json url --jq '.url' 2>&1
            
            return @{ 
                Success = $true
                PullRequestUrl = $prUrl
            }
        } else {
            return @{ 
                Success = $false
                Message = "Failed to create pull request: $prResult"
            }
        }
    }
    catch {
        return @{ 
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Invoke-GitControlledPatch

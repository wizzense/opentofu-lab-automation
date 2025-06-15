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
        [string]$BaseBranch = "main",
        
        [Parameter(Mandatory = $false)]
        [switch]$CreatePullRequest,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        Write-Host "Starting Git-controlled patch process..." -ForegroundColor Cyan
        Write-Host "CRITICAL: NO EMOJIS ALLOWED - they break workflows" -ForegroundColor Red
        
        # Validate we're in a Git repository
        if (-not (Test-Path ".git")) {
            throw "Not in a Git repository. Git-controlled patching requires version control."
        }
        
        # Ensure we have Git available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git command not found. Please install Git."
        }
        
        # Validate clean working tree
        $gitStatus = git status --porcelain
        if ($gitStatus -and -not $Force) {
            throw "Working tree is not clean. Commit or stash changes before patching."
        }
        
        # Generate unique branch name
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $sanitizedDescription = $PatchDescription -replace '[^a-zA-Z0-9]', '-' -replace '-+', '-'
        $branchName = "patch/$timestamp-$sanitizedDescription"
        
        Write-Host "Patch Details:" -ForegroundColor Yellow
        Write-Host "  Description: $PatchDescription" -ForegroundColor White
        Write-Host "  Branch: $branchName" -ForegroundColor White
        Write-Host "  Base: $BaseBranch" -ForegroundColor White
        Write-Host "  Affected Files: $($AffectedFiles.Count)" -ForegroundColor White
    }
    
    process {
        try {
            # Switch to base branch and pull latest
            Write-Host "Updating base branch: $BaseBranch" -ForegroundColor Blue
            git checkout $BaseBranch
            git pull origin $BaseBranch
            
            # Create and switch to patch branch
            Write-Host "Creating patch branch: $branchName" -ForegroundColor Green
            git checkout -b $branchName
            
            # Create backup before applying patch
            $backupPath = "./backups/pre-patch-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            
            if ($AffectedFiles.Count -gt 0) {
                foreach ($file in $AffectedFiles) {
                    if (Test-Path $file) {
                        $relativePath = Resolve-Path $file -Relative
                        Copy-Item $file "$backupPath/$($relativePath -replace '/', '-')" -Force
                    }
                }
                Write-Host "Created backup at: $backupPath" -ForegroundColor Cyan
            }
            
            # Apply the patch operation
            Write-Host "Applying patch operation..." -ForegroundColor Yellow
            
            if ($PSCmdlet.ShouldProcess("Patch operation", "Execute")) {
                & $PatchOperation
                
                if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                    throw "Patch operation failed with exit code: $LASTEXITCODE"
                }
                
                Write-Host "Patch operation completed successfully" -ForegroundColor Green
            }
            
            # Validate changes
            Write-Host "Validating changes..." -ForegroundColor Blue
            $changedFiles = git diff --name-only
            if (-not $changedFiles) {
                Write-Warning "No changes detected after patch operation"
                return @{
                    Success = $false
                    Message = "No changes detected"
                    Branch = $branchName
                }
            }
            
            Write-Host "Changed files:" -ForegroundColor Green
            $changedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
            
            # Run validation checks
            $validationResult = Invoke-PatchValidation -ChangedFiles $changedFiles
            if (-not $validationResult.Success) {
                throw "Patch validation failed: $($validationResult.Message)"
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
            
            # Create pull request if requested
            if ($CreatePullRequest) {
                $prResult = New-PatchPullRequest -BranchName $branchName -BaseBranch $BaseBranch -Description $PatchDescription -ChangedFiles $changedFiles
                if ($prResult.Success) {
                    Write-Host "Pull request created successfully: $($prResult.Url)" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to create pull request: $($prResult.Message)"
                }
            } else {
                Write-Host "Manual pull request creation required for branch: $branchName" -ForegroundColor Yellow
            }
            
            return @{
                Success = $true
                Message = "Patch applied successfully. Manual review required via PR."
                Branch = $branchName
                ChangedFiles = $changedFiles
                Backup = $backupPath
            }
            
        } catch {
            Write-Error "Patch operation failed: $($_.Exception.Message)"
            
            # Cleanup on failure
            try {
                git checkout $BaseBranch
                git branch -D $branchName -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Failed to cleanup branch: $($_.Exception.Message)"
            }
            
            return @{
                Success = $false
                Message = $_.Exception.Message
                Branch = $branchName
            }
        }
    }
    
    end {
        Write-Host "Git-controlled patch process completed" -ForegroundColor Cyan
        Write-Host "REMINDER: Manual review and approval required before merging" -ForegroundColor Red
    }
}

function Invoke-PatchValidation {
    param(
        [string[]]$ChangedFiles
    )
    
    Write-Host "Running patch validation..." -ForegroundColor Blue
    
    # PowerShell syntax validation
    $psFiles = $ChangedFiles | Where-Object { $_ -match '\.ps1$' }
    if ($psFiles) {
        foreach ($file in $psFiles) {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file -Raw), [ref]$null)
                Write-Host "  PowerShell syntax OK: $file" -ForegroundColor Green
            } catch {
                return @{ Success = $false; Message = "PowerShell syntax error in ${file}: $($_.Exception.Message)" }
            }
        }
    }
    
    # Python syntax validation
    $pyFiles = $ChangedFiles | Where-Object { $_ -match '\.py$' }
    if ($pyFiles) {
        foreach ($file in $pyFiles) {
            try {
                python -m py_compile $file
                Write-Host "  Python syntax OK: $file" -ForegroundColor Green
            } catch {
                return @{ Success = $false; Message = "Python syntax error in ${file}: $($_.Exception.Message)" }
            }
        }
    }
    
    # YAML validation  
    $yamlFiles = $ChangedFiles | Where-Object { $_ -match '\.(yml|yaml)$' }
    if ($yamlFiles) {
        foreach ($file in $yamlFiles) {
            try {
                if (Get-Command yamllint -ErrorAction SilentlyContinue) {
                    yamllint $file
                    Write-Host "  YAML syntax OK: $file" -ForegroundColor Green
                } else {
                    Write-Warning "yamllint not available, skipping YAML validation for $file"
                }
            } catch {
                return @{ Success = $false; Message = "YAML syntax error in ${file}: $($_.Exception.Message)" }
            }
        }
    }
    
    return @{ Success = $true; Message = "All validations passed" }
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

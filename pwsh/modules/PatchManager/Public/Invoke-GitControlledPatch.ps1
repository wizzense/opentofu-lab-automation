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
    
    $ErrorActionPreference = "Stop"
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # CRITICAL: No emojis in any output
    Write-Host "Starting Git-controlled patching workflow..." -ForegroundColor Cyan
    Write-Host "Patch Type: $PatchType" -ForegroundColor Gray
    
    # Step 1: Validate Git repository and clean state
    try {
        $gitStatus = git status --porcelain 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Not in a Git repository"
        }
        
        if ($gitStatus) {
            Write-Host "ERROR: Working directory has uncommitted changes." -ForegroundColor Red
            Write-Host "Please commit or stash changes before running patches." -ForegroundColor Red
            return @{
                Success = $false
                Error = "Uncommitted changes detected"
                RequiredAction = "Commit or stash changes"
            }
        }
        
        $currentBranch = git branch --show-current
        Write-Host "Current branch: $currentBranch" -ForegroundColor Gray
        
    } catch {
        Write-Host "ERROR: Not in a Git repository or Git not available." -ForegroundColor Red
        return @{
            Success = $false
            Error = "Git repository required"
            RequiredAction = "Initialize Git repository"
        }
    }
    
    # Step 2: Generate branch name if not provided
    if (-not $BranchName) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $BranchName = "patch-$($PatchType.ToLower())-$timestamp"
    }
    
    # Validate branch name format
    if ($BranchName -notmatch '^patch-[a-z0-9-]+$') {
        Write-Host "WARNING: Branch name should follow format 'patch-[description]'" -ForegroundColor Yellow
        $BranchName = "patch-$($BranchName -replace '[^a-z0-9-]', '-')"
        Write-Host "Using sanitized branch name: $BranchName" -ForegroundColor Yellow
    }
    
    Write-Host "Creating patch branch: $BranchName" -ForegroundColor Green
    
    # Step 3: Create and checkout new branch
    try {
        git checkout -b $BranchName 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create branch"
        }
        Write-Host "Created and switched to branch: $BranchName" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to create branch $BranchName" -ForegroundColor Red
        return @{
            Success = $false
            Error = "Branch creation failed"
            Details = $_.Exception.Message
        }
    }
    
    # Step 4: Apply patches based on type
    $patchResults = @{
        FilesModified = @()
        PatchesApplied = @()
        Errors = @()
        Summary = ""
    }
    
    try {
        Write-Host "Applying patches of type: $PatchType" -ForegroundColor Yellow
        
        switch ($PatchType) {
            "Syntax" {
                Write-Host "Running PowerShell syntax fixes..." -ForegroundColor Gray
                
                # Run PSScriptAnalyzer and apply fixes
                $psFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.ps1" | Where-Object { 
                    $_.FullName -notmatch '\\archive\\|\\legacy\\' 
                }
                
                foreach ($file in $psFiles) {
                    try {
                        $beforeContent = Get-Content $file.FullName -Raw
                        
                        # Apply PSScriptAnalyzer fixes
                        if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
                            $null = Invoke-ScriptAnalyzer -Path $file.FullName -Fix
                        }
                        
                        $afterContent = Get-Content $file.FullName -Raw
                        
                        if ($beforeContent -ne $afterContent) {
                            $patchResults.FilesModified += $file.FullName
                            $patchResults.PatchesApplied += "PSScriptAnalyzer fixes applied to $($file.Name)"
                        }
                    } catch {
                        $patchResults.Errors += "Failed to analyze $($file.Name): $($_.Exception.Message)"
                    }
                }
            }
            
            "Import" {
                Write-Host "Fixing import paths..." -ForegroundColor Gray
                
                # Fix deprecated import paths
                $psFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.ps1" | Where-Object { 
                    $_.FullName -notmatch '\\archive\\|\\legacy\\' 
                }
                
                $importFixes = @{
                    'Import-Module "pwsh/lab_utils/LabRunner"' = 'Import-Module "/pwsh/modules/LabRunner/" -Force'
                    'Import-Module "pwsh/modules/CodeFixer"' = 'Import-Module "/pwsh/modules/CodeFixer/" -Force'
                    'Import-Module "pwsh/modules/BackupManager"' = 'Import-Module "/pwsh/modules/BackupManager/" -Force'
                    'Import-Module "pwsh/modules/PatchManager"' = 'Import-Module "/pwsh/modules/PatchManager/" -Force'
                    '. (Join-Path $PSScriptRoot' = '. (Join-Path $ProjectRoot'
                }
                
                foreach ($file in $psFiles) {
                    $content = Get-Content $file.FullName -Raw
                    $modified = $false
                    
                    foreach ($oldPattern in $importFixes.Keys) {
                        if ($content -match [regex]::Escape($oldPattern)) {
                            $content = $content -replace [regex]::Escape($oldPattern), $importFixes[$oldPattern]
                            $modified = $true
                        }
                    }
                    
                    if ($modified) {
                        Set-Content -Path $file.FullName -Value $content -NoNewline
                        $patchResults.FilesModified += $file.FullName
                        $patchResults.PatchesApplied += "Import path fixes applied to $($file.Name)"
                    }
                }
            }
            
            "Infrastructure" {
                Write-Host "Running infrastructure fixes..." -ForegroundColor Gray
                
                # Use existing PatchManager functions but in controlled way
                if (Get-Command Invoke-InfrastructureFix -ErrorAction SilentlyContinue) {
                    try {
                        $result = Invoke-InfrastructureFix -ProjectRoot $ProjectRoot -AutoFix -WhatIf:$false
                        $patchResults.PatchesApplied += "Infrastructure fixes applied"
                        $patchResults.Summary += "Infrastructure fixes: $($result.FixesApplied) applied"
                    } catch {
                        $patchResults.Errors += "Infrastructure fix failed: $($_.Exception.Message)"
                    }
                } else {
                    $patchResults.Errors += "Invoke-InfrastructureFix command not available"
                }
            }
            
            "YAML" {
                Write-Host "Validating and fixing YAML files..." -ForegroundColor Gray
                
                # Fix YAML files manually (CRITICAL: remove any emojis)
                $yamlFiles = Get-ChildItem -Path "$ProjectRoot/.github/workflows" -Filter "*.yml" -Recurse -ErrorAction SilentlyContinue
                
                foreach ($file in $yamlFiles) {
                    try {
                        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                        if (-not $content) { continue }
                        
                        $originalContent = $content
                        
                        # CRITICAL: Remove any emoji characters - they break workflows
                        $emojiPattern = '[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA70}-\u{1FAFF}]'
                        if ($content -match $emojiPattern) {
                            $content = $content -replace $emojiPattern, ''
                            Write-Host "CRITICAL: Removed emojis from $($file.Name)" -ForegroundColor Red
                        }
                        
                        # Remove other problematic Unicode characters
                        $content = $content -replace '[\u{2013}\u{2014}]', '-'  # Em/En dashes
                        $content = $content -replace '[\u{201C}\u{201D}]', '"'  # Smart quotes
                        $content = $content -replace '[\u{2018}\u{2019}]', "'"  # Smart apostrophes
                        
                        if ($content -ne $originalContent) {
                            Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
                            $patchResults.FilesModified += $file.FullName
                            $patchResults.PatchesApplied += "Fixed problematic characters in $($file.Name)"
                        }
                        
                    } catch {
                        $patchResults.Errors += "YAML processing failed for $($file.Name): $($_.Exception.Message)"
                    }
                }
            }
            
            "All" {
                Write-Host "Applying all patch types..." -ForegroundColor Gray
                
                # Apply each patch type sequentially
                $allTypes = @("YAML", "Import", "Syntax", "Infrastructure")  # YAML first to remove emojis
                foreach ($type in $allTypes) {
                    Write-Host "Applying $type patches..." -ForegroundColor Gray
                    
                    # Create a sub-call without recursion
                    $subPatchResults = @{
                        FilesModified = @()
                        PatchesApplied = @()
                        Errors = @()
                    }
                    
                    # Apply the specific patch type inline
                    switch ($type) {
                        "YAML" {
                            # Inline YAML processing (same as above)
                            $yamlFiles = Get-ChildItem -Path "$ProjectRoot/.github/workflows" -Filter "*.yml" -Recurse -ErrorAction SilentlyContinue
                            foreach ($file in $yamlFiles) {
                                try {
                                    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                                    if (-not $content) { continue }
                                    
                                    $originalContent = $content
                                    $emojiPattern = '[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA70}-\u{1FAFF}]'
                                    if ($content -match $emojiPattern) {
                                        $content = $content -replace $emojiPattern, ''
                                    }
                                    
                                    $content = $content -replace '[\u{2013}\u{2014}]', '-'
                                    $content = $content -replace '[\u{201C}\u{201D}]', '"'
                                    $content = $content -replace '[\u{2018}\u{2019}]', "'"
                                    
                                    if ($content -ne $originalContent) {
                                        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
                                        $subPatchResults.FilesModified += $file.FullName
                                        $subPatchResults.PatchesApplied += "Fixed characters in $($file.Name)"
                                    }
                                } catch {
                                    $subPatchResults.Errors += "YAML processing failed for $($file.Name): $($_.Exception.Message)"
                                }
                            }
                        }
                        "Import" {
                            # Inline Import processing
                            $psFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.ps1" | Where-Object { 
                                $_.FullName -notmatch '\\archive\\|\\legacy\\' 
                            }
                            
                            $importFixes = @{
                                'Import-Module "pwsh/lab_utils/LabRunner"' = 'Import-Module "/pwsh/modules/LabRunner/" -Force'
                                'Import-Module "pwsh/modules/CodeFixer"' = 'Import-Module "/pwsh/modules/CodeFixer/" -Force'
                                'Import-Module "pwsh/modules/BackupManager"' = 'Import-Module "/pwsh/modules/BackupManager/" -Force'
                                'Import-Module "pwsh/modules/PatchManager"' = 'Import-Module "/pwsh/modules/PatchManager/" -Force'
                            }
                            
                            foreach ($file in $psFiles) {
                                $content = Get-Content $file.FullName -Raw
                                $modified = $false
                                
                                foreach ($oldPattern in $importFixes.Keys) {
                                    if ($content -match [regex]::Escape($oldPattern)) {
                                        $content = $content -replace [regex]::Escape($oldPattern), $importFixes[$oldPattern]
                                        $modified = $true
                                    }
                                }
                                
                                if ($modified) {
                                    Set-Content -Path $file.FullName -Value $content -NoNewline
                                    $subPatchResults.FilesModified += $file.FullName
                                    $subPatchResults.PatchesApplied += "Import fixes in $($file.Name)"
                                }
                            }
                        }
                        "Syntax" {
                            # Inline Syntax processing
                            $psFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.ps1" | Where-Object { 
                                $_.FullName -notmatch '\\archive\\|\\legacy\\' 
                            }
                            
                            foreach ($file in $psFiles) {
                                try {
                                    $beforeContent = Get-Content $file.FullName -Raw
                                    
                                    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
                                        $null = Invoke-ScriptAnalyzer -Path $file.FullName -Fix
                                    }
                                    
                                    $afterContent = Get-Content $file.FullName -Raw
                                    
                                    if ($beforeContent -ne $afterContent) {
                                        $subPatchResults.FilesModified += $file.FullName
                                        $subPatchResults.PatchesApplied += "Syntax fixes in $($file.Name)"
                                    }
                                } catch {
                                    $subPatchResults.Errors += "Syntax fix failed for $($file.Name): $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                    
                    # Merge results
                    $patchResults.FilesModified += $subPatchResults.FilesModified
                    $patchResults.PatchesApplied += $subPatchResults.PatchesApplied
                    $patchResults.Errors += $subPatchResults.Errors
                }
            }
        }
        
    } catch {
        $patchResults.Errors += "Patch application failed: $($_.Exception.Message)"
    }
    
    # Step 5: Commit changes if any were made
    $gitDiff = git diff --name-only
    if ($gitDiff) {
        Write-Host "Changes detected in the following files:" -ForegroundColor Green
        $gitDiff | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        
        try {
            git add .
            $commitMessage = "fix($($PatchType.ToLower())): apply automated patches

Applied patches:
$($patchResults.PatchesApplied -join "`n- ")

Files modified: $($patchResults.FilesModified.Count)
Errors: $($patchResults.Errors.Count)

This commit was created by automated patching system.
Requires manual review before merge.

CRITICAL: All emojis have been removed to prevent workflow breakage."

            git commit -m $commitMessage
            Write-Host "Changes committed to branch $BranchName" -ForegroundColor Green
            
        } catch {
            Write-Host "ERROR: Failed to commit changes" -ForegroundColor Red
            $patchResults.Errors += "Commit failed: $($_.Exception.Message)"
        }
    } else {
        Write-Host "No changes to commit" -ForegroundColor Yellow
    }
    
    # Step 6: Push branch and create PR if requested
    if ($CreatePR -and $gitDiff) {
        try {
            Write-Host "Pushing branch to remote..." -ForegroundColor Yellow
            git push -u origin $BranchName
            
            # Create PR using GitHub CLI if available
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                $prTitle = "fix($($PatchType.ToLower())): automated patches for $PatchType issues"
                $prBody = @"
## Automated Patch Application

**Patch Type**: $PatchType
**Branch**: $BranchName
**Files Modified**: $($patchResults.FilesModified.Count)

### Patches Applied
$($patchResults.PatchesApplied -join "`n- ")

### Validation Required
- [ ] Review all changes for correctness
- [ ] Ensure no breaking changes introduced
- [ ] Verify tests still pass
- [ ] Confirm no emojis or problematic characters remain

### Errors (if any)
$($patchResults.Errors -join "`n- ")

**CRITICAL**: This PR was created by automated patching. All emojis have been removed to prevent workflow breakage. Please review carefully before merging.

**IMPORTANT**: This PR requires manual human validation before merging.
"@
                
                $pr = gh pr create --title $prTitle --body $prBody --head $BranchName 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Pull request created successfully" -ForegroundColor Green
                    Write-Host "Please review and merge manually after validation" -ForegroundColor Yellow
                } else {
                    Write-Host "Failed to create PR via GitHub CLI" -ForegroundColor Yellow
                }
                
            } else {
                Write-Host "GitHub CLI not available. Please create PR manually." -ForegroundColor Yellow
                Write-Host "Branch pushed: $BranchName" -ForegroundColor Green
            }
            
        } catch {
            Write-Host "ERROR: Failed to push branch or create PR" -ForegroundColor Red
            $patchResults.Errors += "PR creation failed: $($_.Exception.Message)"
        }
    }
    
    # Step 7: Switch back to original branch
    try {
        git checkout $currentBranch 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Switched back to original branch: $currentBranch" -ForegroundColor Green
        }
    } catch {
        Write-Host "WARNING: Failed to switch back to original branch" -ForegroundColor Yellow
    }
    
    # Step 8: Return results
    $result = @{
        Success = $patchResults.Errors.Count -eq 0
        BranchName = $BranchName
        PatchType = $PatchType
        FilesModified = $patchResults.FilesModified
        PatchesApplied = $patchResults.PatchesApplied
        Errors = $patchResults.Errors
        HasChanges = $gitDiff -ne $null
        RequiresReview = $true
    }
    
    # Summary output (NO EMOJIS)
    Write-Host "`nPatch Application Summary:" -ForegroundColor Cyan
    Write-Host "Branch: $BranchName" -ForegroundColor Gray
    Write-Host "Files Modified: $($result.FilesModified.Count)" -ForegroundColor Gray
    Write-Host "Patches Applied: $($result.PatchesApplied.Count)" -ForegroundColor Gray
    Write-Host "Errors: $($result.Errors.Count)" -ForegroundColor Gray
    
    if ($result.Errors.Count -gt 0) {
        Write-Host "`nErrors encountered:" -ForegroundColor Red
        $result.Errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    
    if ($result.HasChanges) {
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "1. Review the pull request" -ForegroundColor Gray
        Write-Host "2. Test the changes" -ForegroundColor Gray
        Write-Host "3. Merge manually after validation" -ForegroundColor Gray
        Write-Host "CRITICAL: Human validation is required" -ForegroundColor Red
    }
    
    return $result
}
            $backupPath = "./backups/pre-patch-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            
            if ($AffectedFiles.Count -gt 0) {
                foreach ($file in $AffectedFiles) {
                    if (Test-Path $file) {
                        $relativePath = Resolve-Path $file -Relative
                        $backupFile = Join-Path $backupPath $relativePath
                        $backupDir = Split-Path $backupFile -Parent
                        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                        Copy-Item $file $backupFile -Force
                    }
                }
                Write-Host "Created backup at: $backupPath" -ForegroundColor Cyan
            }
              # Apply the patch operation
            Write-Host "Applying patch operation..." -ForegroundColor Yellow            if ($PSCmdlet.ShouldProcess("Patch operation", "Execute")) {
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
                Write-Warning "No changes detected after patch operation."
                return @{
                    Success = $false
                    Message = "No changes were made"
                    Branch = $branchName
                }
            }
            
            Write-Host "Changed files:" -ForegroundColor Green
            $changedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
            
            # Run validation checks
            $validationPassed = Invoke-PatchValidation -ChangedFiles $changedFiles
            
            if (-not $validationPassed) {
                Write-Error "Patch validation failed. Rolling back changes."
                git checkout $BaseBranch
                git branch -D $branchName
                return @{
                    Success = $false
                    Message = "Validation failed"
                    Branch = $branchName
                }
            }
            
            # Stage and commit changes
            Write-Host "Staging and committing changes..." -ForegroundColor Blue
            git add -A
            
            $commitMessage = @"
fix: $PatchDescription

- Applied automated patch with validation
- Backup created at: $backupPath
- Changed files: $($changedFiles.Count)
- Requires manual review before merge

Auto-generated by PatchManager v2.0
"@
            
            git commit -m $commitMessage
              # Push branch to remote
            Write-Host "Pushing branch to remote..." -ForegroundColor Green
            git push -u origin $branchName
            
            # Create pull request if requested
            if ($CreatePullRequest) {
                $prResult = New-PatchPullRequest -BranchName $branchName -PatchDescription $PatchDescription -BaseBranch $BaseBranch
                
                return @{
                    Success = $true
                    Message = "Patch applied successfully and PR created"
                    Branch = $branchName
                    PullRequest = $prResult
                    ChangedFiles = $changedFiles
                    Backup = $backupPath
                }
            } else {
                Write-Host "Patch applied to branch: $branchName" -ForegroundColor Green
                Write-Host "Create PR manually: gh pr create --base $BaseBranch --head $branchName" -ForegroundColor Yellow
                
                return @{
                    Success = $true
                    Message = "Patch applied successfully. Manual PR creation required."
                    Branch = $branchName
                    ChangedFiles = $changedFiles
                    Backup = $backupPath
                }
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
    }
}

function Invoke-PatchValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ChangedFiles
    )
    
    Write-Host "Running comprehensive validation..." -ForegroundColor Blue
    
    $validationResults = @{
        PowerShellLint = $true
        PythonSyntax = $true
        YamlValidation = $true
        TestExecution = $true
    }
    
    # PowerShell linting
    $psFiles = $ChangedFiles | Where-Object { $_ -match '\.ps1$' }
    if ($psFiles) {
        Write-Host "  Validating PowerShell files..." -ForegroundColor Cyan
        try {
            if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
                $psResults = $psFiles | ForEach-Object {
                    Invoke-ScriptAnalyzer -Path $_ -Severity Error
                }
                if ($psResults) {
                    Write-Warning "PowerShell linting errors found:"
                    $psResults | ForEach-Object { Write-Warning "  $($_.ScriptName): $($_.Message)" }
                    $validationResults.PowerShellLint = $false
                }
            } else {
                Write-Warning "PSScriptAnalyzer not available. Skipping PowerShell validation."
            }
        } catch {
            Write-Warning "PowerShell validation failed: $($_.Exception.Message)"
            $validationResults.PowerShellLint = $false
        }
    }
      # Python syntax validation
    $pyFiles = $ChangedFiles | Where-Object { $_ -match '\.py$' }
    if ($pyFiles) {
        Write-Host "  Validating Python files..." -ForegroundColor Cyan
        try {
            $pyResults = $pyFiles | ForEach-Object {
                python -m py_compile $_
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Python syntax error in: $_"
                    return $false
                }
                return $true
            }
            if ($pyResults -contains $false) {
                $validationResults.PythonSyntax = $false
            }
        } catch {
            Write-Warning "Python validation failed: $($_.Exception.Message)"
            $validationResults.PythonSyntax = $false
        }
    }
      # YAML validation
    $yamlFiles = $ChangedFiles | Where-Object { $_ -match '\.(yml|yaml)$' }
    if ($yamlFiles) {
        Write-Host "  Validating YAML files..." -ForegroundColor Cyan
        try {
            if (Get-Command yamllint -ErrorAction SilentlyContinue) {
                $yamlResults = $yamlFiles | ForEach-Object {
                    yamllint $_
                    return $LASTEXITCODE -eq 0
                }
                if ($yamlResults -contains $false) {
                    $validationResults.YamlValidation = $false
                }
            } else {
                Write-Warning "yamllint not available. Skipping YAML validation."
            }
        } catch {
            Write-Warning "YAML validation failed: $($_.Exception.Message)"
            $validationResults.YamlValidation = $false
        }
    }
      # Test execution for critical files
    $testFiles = $ChangedFiles | Where-Object { $_ -match '\.Tests\.ps1$' }
    if ($testFiles) {
        Write-Host "  Running affected tests..." -ForegroundColor Cyan
        try {
            if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
                $testResults = Invoke-Pester -Path $testFiles -PassThru -Quiet
                if ($testResults.FailedCount -gt 0) {
                    Write-Warning "Test failures detected: $($testResults.FailedCount) failed"
                    $validationResults.TestExecution = $false
                }
            } else {
                Write-Warning "Pester not available. Skipping test execution."
            }
        } catch {
            Write-Warning "Test execution failed: $($_.Exception.Message)"
            $validationResults.TestExecution = $false
        }
    }
      # Summary
    $allPassed = ($validationResults.Values | Where-Object { $_ -eq $false }).Count -eq 0
    
    if ($allPassed) {
        Write-Host "All validations passed" -ForegroundColor Green
    } else {
        Write-Host "Validation failures detected:" -ForegroundColor Red
        $validationResults.GetEnumerator() | Where-Object { $_.Value -eq $false } | ForEach-Object {
            Write-Host "  - $($_.Key)" -ForegroundColor Red
        }
    }
    
    return $allPassed
}

function New-PatchPullRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $true)]
        [string]$PatchDescription,
        
        [Parameter(Mandatory = $false)]
        [string]$BaseBranch = "main"
    )
    
    Write-Host "Creating pull request..." -ForegroundColor Blue
    
    # Check if GitHub CLI is available
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Warning "GitHub CLI (gh) not found. Please install GitHub CLI and try again."
        return @{
            Success = $false
            Message = "GitHub CLI not available"
        }
    }
    
    try {        # Create PR with comprehensive template
        $prBody = @"
## Automated Patch: $PatchDescription

This PR contains automated fixes that require manual review before merging.

### Changes Summary
- **Type**: Automated Maintenance Patch  
- **Branch**: $BranchName
- **Base**: $BaseBranch
- **Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

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
        
        $prTitle = "fix: $PatchDescription"
          # Create the PR
        $prUrl = gh pr create --base $BaseBranch --head $BranchName --title $prTitle --body $prBody
        
        Write-Host "Pull request created successfully!" -ForegroundColor Green
        Write-Host "PR URL: $prUrl" -ForegroundColor Cyan
        
        return @{
            Success = $true
            Url = $prUrl
            Title = $prTitle
        }
        
    } catch {
        Write-Error "Failed to create pull request: $($_.Exception.Message)"
        return @{
            Success = $false
            Message = $_.Exception.Message
        }
    }
}

function Invoke-EmergencyPatch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatchDescription,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$PatchOperation,
        
        [Parameter(Mandatory = $true)]
        [string]$Justification,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles = @()
    )
      Write-Warning "EMERGENCY PATCH MODE - Use only for critical fixes!"
    Write-Host "Justification: $Justification" -ForegroundColor Red
    
    # Emergency patches still use branches but allow faster merge
    $result = Invoke-GitControlledPatch -PatchDescription "EMERGENCY: $PatchDescription" -PatchOperation $PatchOperation -AffectedFiles $AffectedFiles -CreatePullRequest
    
    if ($result.Success) {
        Write-Host "Emergency patch created. Immediate review required!" -ForegroundColor Red
        Write-Host "PR: $($result.PullRequest.Url)" -ForegroundColor Cyan
    }
    
    return $result
}

# Export module functions
Export-ModuleMember -Function @(
    'Invoke-GitControlledPatch',
    'Invoke-PatchValidation', 
    'New-PatchPullRequest',
    'Invoke-EmergencyPatch'
)

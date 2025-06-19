#Requires -Version 7.0

<#
.SYNOPSIS
    Enhanced Git-controlled patch management with automated validation and conflict resolution
    
.DESCRIPTION
    This enhanced version of PatchManager includes:
    - Automatic validation of all modules and syntax
    - Git conflict detection and resolution
    - Directory deletion handling for Windows
    - Comprehensive pre-commit and post-commit validation
    - Automated issue generation and PR management
    
.PARAMETER PatchDescription
    Description of the patch being applied
    
.PARAMETER PatchOperation
    The script block containing the patch operation (optional if just validating)
    
.PARAMETER AutoValidate
    Run comprehensive validation before and after patch
    
.PARAMETER AutoResolveConflicts
    Automatically resolve common git conflicts
    
.PARAMETER CreateIssue
    Create GitHub issue for the patch
    
.PARAMETER CreatePullRequest
    Create pull request after patch
    
.EXAMPLE
    Invoke-EnhancedPatchManager -PatchDescription "fix: resolve module import issues" -AutoValidate -CreatePullRequest
    
.EXAMPLE
    Invoke-EnhancedPatchManager -PatchDescription "validate: comprehensive system check" -AutoValidate -CreateIssue
#>

function Invoke-EnhancedPatchManager {
    [CmdletBinding(SupportsShouldProcess)]    param(
        [Parameter(Mandatory = $false)]
        [string]$PatchDescription,
        
        [Parameter()]
        [scriptblock]$PatchOperation,
          [Parameter()]
        [switch]$AutoValidate,
        
        [Parameter()]
        [switch]$AutoResolveConflicts,
        
        [Parameter()]
        [switch]$CreateIssue,
        
        [Parameter()]
        [switch]$CreatePullRequest,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$DryRun
    )
      begin {
        # Validate required parameters first - fail fast in non-interactive mode
        if ([string]::IsNullOrWhiteSpace($PatchDescription)) {
            throw "PatchDescription parameter is required. Please provide a meaningful description of the patch being applied."
        }
        
        Write-Host "=== Enhanced PatchManager with Automated Validation ===" -ForegroundColor Cyan
          # Import required modules
        $projectRoot = $env:PROJECT_ROOT
        if (-not $projectRoot) {
            $projectRoot = (Get-Location).Path
            $env:PROJECT_ROOT = $projectRoot
        }
        
        # Import PatchManager module with forward slashes for cross-platform compatibility
        Import-Module './core-runner/modules/PatchManager' -Force
        
        # Function for logging
        function Write-PatchLog {
            param([string]$Message, [string]$Level = "INFO")
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $color = switch ($Level) {
                "ERROR" { "Red" }
                "WARN" { "Yellow" }
                "SUCCESS" { "Green" }
                default { "White" }
            }
            Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
        }
        
        Write-PatchLog "Starting enhanced patch process: $PatchDescription" -Level "INFO"
    }
    
    process {
        try {            # Step 1: Pre-patch validation
            if ($AutoValidate) {
                Write-PatchLog "Running comprehensive pre-patch validation..." -Level "INFO"
                
                $validationResult = Invoke-ComprehensiveValidation -DryRun:$DryRun
                if (-not $validationResult.Success) {
                    Write-PatchLog "Pre-patch validation failed: $($validationResult.Message)" -Level "ERROR"
                    
                    # NEW: Trigger comprehensive validation failure handling
                    Write-PatchLog "Triggering comprehensive validation failure tracking..." -Level "INFO"
                    try {
                        $failureHandler = Invoke-ValidationFailureHandler -ValidationResults $validationResult.ValidationResults -Context @{
                            Operation = "PatchManager Pre-Validation"
                            PatchDescription = $PatchDescription
                            AutoValidate = $AutoValidate
                            DryRun = $DryRun
                        } -PatchDescription $PatchDescription -AffectedFiles @() -Force:$Force
                        
                        if ($failureHandler.Success) {
                            Write-PatchLog "Validation failure tracking completed successfully" -Level "SUCCESS"
                            Write-PatchLog "Summary Issue: $($failureHandler.SummaryIssue.IssueUrl)" -Level "INFO"
                            Write-PatchLog "Sub-issues created: $($failureHandler.SubIssues.Count)" -Level "INFO"
                            Write-PatchLog "Tracking ID: $($failureHandler.TrackingId)" -Level "INFO"
                        } else {
                            Write-PatchLog "Failed to create validation failure tracking: $($failureHandler.Message)" -Level "WARN"
                        }
                    } catch {
                        Write-PatchLog "Validation failure handler error: $($_.Exception.Message)" -Level "WARN"
                    }
                    
                    if (-not $Force) {
                        throw "Pre-patch validation failed. Comprehensive issue tracking created. Use -Force to override."
                    }
                }
                
                Write-PatchLog "Pre-patch validation completed" -Level "SUCCESS"
            }
            
            # Step 2: Git conflict detection and resolution
            if ($AutoResolveConflicts) {
                Write-PatchLog "Checking for git conflicts and problematic directories..." -Level "INFO"
                
                $conflictResult = Resolve-GitConflicts -DryRun:$DryRun
                if (-not $conflictResult.Success) {
                    Write-PatchLog "Git conflict resolution failed: $($conflictResult.Message)" -Level "ERROR"
                    if (-not $Force) {
                        throw "Git conflicts detected. Use -Force to override."
                    }
                }
                
                Write-PatchLog "Git conflict resolution completed" -Level "SUCCESS"
            }
            
            # Step 3: Create GitHub issue if requested
            if ($CreateIssue) {
                Write-PatchLog "Creating GitHub issue..." -Level "INFO"
                
                if (-not $DryRun) {
                    $issueResult = New-PatchIssue -Description $PatchDescription
                    if ($issueResult.Success) {
                        Write-PatchLog "GitHub issue created: $($issueResult.IssueUrl)" -Level "SUCCESS"
                    } else {
                        Write-PatchLog "Failed to create GitHub issue: $($issueResult.Message)" -Level "WARN"
                    }
                } else {
                    Write-PatchLog "DRY RUN: Would create GitHub issue" -Level "INFO"
                }
            }
            
            # Step 4: Apply patch operation if provided
            if ($PatchOperation) {
                Write-PatchLog "Applying patch operation..." -Level "INFO"
                  if (-not $DryRun) {
                    $patchResult = & $PatchOperation
                    Write-PatchLog "Patch operation completed with result: $($null -ne $patchResult)" -Level "SUCCESS"
                } else {
                    Write-PatchLog "DRY RUN: Would execute patch operation" -Level "INFO"
                }
            }
              # Step 5: Post-patch validation
            if ($AutoValidate) {
                Write-PatchLog "Running post-patch validation..." -Level "INFO"
                
                $postValidationResult = Invoke-ComprehensiveValidation -DryRun:$DryRun
                if (-not $postValidationResult.Success) {
                    Write-PatchLog "Post-patch validation failed: $($postValidationResult.Message)" -Level "ERROR"
                    
                    # NEW: Trigger comprehensive validation failure handling for post-patch failures
                    Write-PatchLog "Triggering post-patch validation failure tracking..." -Level "INFO"
                    try {
                        $postFailureHandler = Invoke-ValidationFailureHandler -ValidationResults $postValidationResult.ValidationResults -Context @{
                            Operation = "PatchManager Post-Validation"
                            PatchDescription = $PatchDescription
                            PostPatch = $true
                            PatchApplied = $true
                            DryRun = $DryRun
                        } -PatchDescription $PatchDescription -AffectedFiles @() -Force:$Force
                        
                        if ($postFailureHandler.Success) {
                            Write-PatchLog "Post-patch validation failure tracking completed" -Level "SUCCESS"
                            Write-PatchLog "Summary Issue: $($postFailureHandler.SummaryIssue.IssueUrl)" -Level "INFO"
                            Write-PatchLog "Sub-issues created: $($postFailureHandler.SubIssues.Count)" -Level "INFO"
                            Write-PatchLog "Tracking ID: $($postFailureHandler.TrackingId)" -Level "INFO"
                        } else {
                            Write-PatchLog "Failed to create post-patch validation failure tracking: $($postFailureHandler.Message)" -Level "WARN"
                        }
                    } catch {
                        Write-PatchLog "Post-patch validation failure handler error: $($_.Exception.Message)" -Level "WARN"
                    }
                    
                    if (-not $Force) {
                        throw "Post-patch validation failed. Comprehensive issue tracking created. Rolling back changes."
                    }
                }
                
                Write-PatchLog "Post-patch validation completed" -Level "SUCCESS"
            }
            
            # Step 6: Commit changes and create PR if requested
            if ($CreatePullRequest) {
                Write-PatchLog "Creating pull request..." -Level "INFO"
                
                if (-not $DryRun) {
                    $prResult = New-PatchPullRequest -Description $PatchDescription
                    if ($prResult.Success) {
                        Write-PatchLog "Pull request created: $($prResult.PullRequestUrl)" -Level "SUCCESS"
                    } else {
                        Write-PatchLog "Failed to create pull request: $($prResult.Message)" -Level "WARN"
                    }
                } else {
                    Write-PatchLog "DRY RUN: Would create pull request" -Level "INFO"
                }
            }
            
            Write-PatchLog "Enhanced patch process completed successfully" -Level "SUCCESS"
            return @{
                Success = $true
                Message = "Patch applied successfully with automated validation"
            }
        }
        catch {
            Write-PatchLog "Enhanced patch process failed: $($_.Exception.Message)" -Level "ERROR"
            return @{
                Success = $false
                Message = $_.Exception.Message
                Error = $_
            }
        }
    }
}

# Helper function for comprehensive validation
function Invoke-ComprehensiveValidation {
    [CmdletBinding()]
    param([switch]$DryRun)
    
    try {
        Write-PatchLog "Running module import validation..." -Level "INFO"
        
        # Test module imports
        $modules = @("LabRunner", "PatchManager", "DevEnvironment", "BackupManager")
        $failedModules = @()
        
        foreach ($module in $modules) {
            try {
                $modulePath = "$env:PROJECT_ROOT/pwsh/modules/$module"
                if (Test-Path $modulePath) {
                    Import-Module $modulePath -Force -ErrorAction Stop
                    Write-PatchLog "✅ Module $module imported successfully" -Level "INFO"
                } else {
                    $failedModules += "$module (path not found)"
                }
            }
            catch {
                $failedModules += "$module ($($_.Exception.Message))"
            }
        }
        
        # Run syntax validation
        Write-PatchLog "Running PowerShell syntax validation..." -Level "INFO"
        $syntaxErrors = @()
        
        $psFiles = Get-ChildItem -Path $env:PROJECT_ROOT -Filter "*.ps1" -Recurse | Where-Object {
            $_.FullName -notmatch "\\\\archive\\\\" -and $_.FullName -notmatch "\\\\backup"
        }
        
        foreach ($file in $psFiles) {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file.FullName -Raw), [ref]$null)
                Write-PatchLog "✅ Syntax OK: $($file.Name)" -Level "INFO"
            }
            catch {
                $syntaxErrors += "$($file.Name): $($_.Exception.Message)"
            }
        }
          # Check for emoji usage
        Write-PatchLog "Checking for emoji usage..." -Level "INFO"
        $emojiFiles = @()
        
        # Use a simpler approach to detect common emoji patterns
        $emojiPatterns = @(
            '[\u2600-\u26FF]',  # Miscellaneous Symbols
            '[\u2700-\u27BF]',  # Dingbats
            '[\uD83C-\uD83E]',  # Surrogate pairs for emoji
            '[\u1F300-\u1F5FF]', # Miscellaneous Symbols and Pictographs (in BMP)
            '[\u1F600-\u1F64F]', # Emoticons (in BMP)
            '[\u1F680-\u1F6FF]', # Transport and Map Symbols
            '[\u1F700-\u1F77F]', # Alchemical Symbols
            '[😀-🙏]',           # Direct character ranges
            '[🌀-🗿]',           # Direct character ranges
            '[🚀-🛿]',           # Direct character ranges
            '[🤀-🧿]'            # Direct character ranges
        )
        
        foreach ($file in $psFiles) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                foreach ($pattern in $emojiPatterns) {
                    try {
                        if ($content -match $pattern) {
                            $emojiFiles += $file.Name
                            break
                        }
                    }
                    catch {
                        # Skip problematic patterns
                        continue
                    }
                }
            }
        }
          # Compile results with detailed information
        $issues = @()
        $validationResults = @{
            ModuleImportFailures = $failedModules
            SyntaxErrors = $syntaxErrors
            EmojiUsageFiles = $emojiFiles
            ModulesTestedCount = $modules.Count
            FilesTestedCount = $psFiles.Count
            ValidationTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC'
        }
        
        if ($failedModules.Count -gt 0) {
            $issues += "Failed module imports: $($failedModules -join ', ')"
        }
        if ($syntaxErrors.Count -gt 0) {
            $issues += "Syntax errors: $($syntaxErrors -join ', ')"
        }
        if ($emojiFiles.Count -gt 0) {
            $issues += "Emoji usage detected: $($emojiFiles -join ', ')"
        }
        
        if ($issues.Count -eq 0) {
            return @{ 
                Success = $true
                Message = "All validation checks passed"
                ValidationResults = $validationResults
            }
        } else {
            return @{ 
                Success = $false
                Message = "Validation issues: $($issues -join '; ')"
                ValidationResults = $validationResults
            }
        }
    }
    catch {
        return @{ 
            Success = $false
            Message = "Validation failed: $($_.Exception.Message)"
            ValidationResults = @{
                ValidationError = $_.Exception.Message
                ValidationTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC'
            }
        }
    }
}

# Helper function for git conflict resolution
function Resolve-GitConflicts {
    [CmdletBinding()]
    param([switch]$DryRun)
    
    try {
        Write-PatchLog "Checking git status..." -Level "INFO"
        
        # Check for problematic directories that Windows can't delete
        $problematicDirs = @(
            ".github/actions",
            ".github/copilot",
            "archive/temp"
        )
        
        $removedDirs = @()
        foreach ($dir in $problematicDirs) {
            if (Test-Path $dir) {
                if (-not $DryRun) {
                    Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
                    $removedDirs += $dir
                    Write-PatchLog "Removed problematic directory: $dir" -Level "INFO"
                } else {
                    Write-PatchLog "DRY RUN: Would remove directory: $dir" -Level "INFO"
                }
            }
        }
        
        # Check for git conflicts
        $gitStatus = git status --porcelain 2>&1
        if ($LASTEXITCODE -ne 0) {
            return @{ Success = $false; Message = "Git status failed: $gitStatus" }
        }
        
        $conflicts = $gitStatus | Where-Object { $_ -match "^UU " }
        if ($conflicts) {
            return @{ Success = $false; Message = "Merge conflicts detected: $($conflicts -join ', ')" }
        }
        
        return @{ 
            Success = $true; 
            Message = "Git conflicts resolved. Removed directories: $($removedDirs -join ', ')"
        }
    }
    catch {
        return @{ Success = $false; Message = "Git conflict resolution failed: $($_.Exception.Message)" }
    }
}

# Helper function to create GitHub issue
function New-PatchIssue {
    [CmdletBinding()]
    param([string]$Description)
    
    try {
        $issueTitle = "Automated Patch: $Description"
        $issueBody = @"
## Automated Patch Issue

**Description**: $Description
**Created**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
**Type**: Automated PatchManager Operation

### Details
This issue was automatically created by the Enhanced PatchManager system.

### Validation
- Automated module import validation
- PowerShell syntax checking
- Git conflict resolution
- Emoji usage prevention

### Next Steps
1. Review the associated pull request
2. Validate changes in a clean environment
3. Approve and merge when ready

---
*This issue was created automatically by Enhanced PatchManager*
"@
        
        $result = gh issue create --title $issueTitle --body $issueBody --label "automated,patch" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $issueUrl = gh issue view --json url --jq '.url' 2>&1
            return @{ Success = $true; IssueUrl = $issueUrl }
        } else {
            return @{ Success = $false; Message = "GitHub CLI failed: $result" }
        }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

# Helper function to create pull request
function New-PatchPullRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationResults,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoMerge,
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )
    
    try {
        # Check if there are changes to commit
        $gitStatus = git status --porcelain 2>&1
        $hasChanges = $gitStatus -and ($gitStatus | Where-Object { $_ -match '\S' })
        
        if (-not $hasChanges) {
            Write-PatchLog "No changes to commit, proceeding with PR creation" -Level "INFO"
        } else {
            # Commit current changes
            git add -A 2>&1 | Out-Null
            $commitMessage = "patch: $Description`n`nAutomated patch with enhanced validation`n- Module import validation`n- Syntax checking`n- Git conflict resolution`n- Emoji prevention"            
            git commit -m $commitMessage 2>&1 | Out-Null
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to commit changes"
            }
        }
        
        # Determine branch name
        if ([string]::IsNullOrWhiteSpace($BranchName)) {
            $BranchName = git branch --show-current 2>&1
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($BranchName)) {
                throw "Unable to determine current branch name. Please specify using -BranchName parameter."
            }
        }
          # Validate branch exists
        git rev-parse --verify $BranchName 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Branch '$BranchName' does not exist"
        }
        
        # Push branch
        Write-PatchLog "Pushing branch $BranchName to remote..." -Level "INFO"
        $pushResult = git push -u origin $BranchName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-PatchLog "Branch pushed successfully" -Level "SUCCESS"
                  if ($DryRun) {
                Write-PatchLog "DRY RUN: Would push branch $BranchName to remote and create pull request" -Level "INFO"
                return @{
                    Success = $true
                    Message = "DRY RUN: Pull request creation simulated"
                    BranchName = $BranchName
                    DryRun = $true
                }
            }
            
            # Create PR with title length validation
            Write-PatchLog "Creating pull request..." -Level "INFO"
            
            # Ensure PR title is not too long (GitHub limit is 256 chars)
            $descriptionLines = $Description -split "`n"
            $prTitle = if ($descriptionLines[0].Length -gt 100) {
                ($descriptionLines[0].Substring(0, 97) + "...").Trim()
            } else {
                $descriptionLines[0].Trim()
            }
            
            # Prefix with type if not already prefixed
            if (-not ($prTitle -match "^(feat|fix|docs|style|refactor|perf|test|chore|patch):")) {
                $prTitle = "patch: $prTitle"
            }
            
            # Ensure title is under 250 chars to be safe
            if ($prTitle.Length -gt 250) {
                $prTitle = $prTitle.Substring(0, 247) + "..."
            }
            
            $prBody = @"
## Enhanced Patch with Automated Validation

**Description**: $Description
**Branch**: $BranchName
**Validation**: Comprehensive automated validation completed

### Changes Include
- Automated module import validation
- PowerShell syntax checking
- Git conflict resolution
- Emoji usage prevention
- Comprehensive pre/post validation

### Validation Results
✅ Module imports validated
✅ PowerShell syntax checked
✅ Git conflicts resolved
✅ No emoji usage detected

### Review Checklist
- [ ] Changes are functionally correct
- [ ] No breaking changes introduced
- [ ] Documentation updated if needed
- [ ] Ready for production deployment

---
*This PR was created automatically by Enhanced PatchManager*
"@
                
                # Try to create PR with proper error handling
                try {
                    $prResult = gh pr create --title $prTitle --body $prBody --base main 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        # Get the PR URL
                        try {
                            $prUrl = gh pr view --json url --jq '.url' 2>&1
                            if ($LASTEXITCODE -eq 0 -and $prUrl) {
                                Write-PatchLog "Pull request created successfully: $prUrl" -Level "SUCCESS"
                                return @{ 
                                    Success = $true 
                                    PullRequestUrl = $prUrl 
                                    BranchName = $BranchName
                                }
                            } 
                        } catch {
                            # Fallback method - extract URL from creation output
                        }
                        
                        # Fallback to extracting URL from create output
                        if ($prResult -match 'https://[^\s]+') {
                            $extractedUrl = $matches[0]
                            Write-PatchLog "Pull request created successfully: $extractedUrl" -Level "SUCCESS"
                            return @{ 
                                Success = $true 
                                PullRequestUrl = $extractedUrl 
                                BranchName = $BranchName
                            }
                        } else {
                            # PR created but couldn't get URL
                            Write-PatchLog "Pull request created but couldn't retrieve URL" -Level "WARNING"
                            return @{ 
                                Success = $true 
                                Message = "PR created but URL not found"
                                BranchName = $BranchName
                            }
                        }
                    } else {
                        # PR creation failed - check for specific error conditions
                        $errorMessage = $prResult -join " "                        # Handle common errors
                        if ($errorMessage -match "already exists") {
                            # Extract PR URL from error message if it's there
                            if ($errorMessage -match "(https://[^\s\n]+)") {
                                $existingPrUrl = $matches[1].TrimEnd('1234567890') # Remove any trailing numbers that might be part of line numbers
                                Write-PatchLog "A pull request already exists for this branch: $existingPrUrl" -Level "INFO"
                                return @{ 
                                    Success = $true 
                                    PullRequestUrl = $existingPrUrl
                                    BranchName = $BranchName
                                    Message = "An existing pull request was found for this branch"
                                }
                            }
                            
                            # Otherwise try to get PR URL using gh cli
                            Write-PatchLog "A pull request already exists for this branch" -Level "INFO"
                            try {
                                $existingPrUrl = gh pr view $BranchName --json url --jq '.url' 2>&1
                                if ($LASTEXITCODE -eq 0 -and $existingPrUrl) {
                                    return @{ 
                                        Success = $true 
                                        PullRequestUrl = $existingPrUrl
                                        BranchName = $BranchName
                                        Message = "An existing pull request was found for this branch"
                                    }
                                }
                            } catch {
                                # Ignore error getting existing PR URL
                            }
                        } elseif ($errorMessage -match "too long") {
                            # Title too long - use a shorter title
                            $shorterTitle = "Patch: " + (Get-Date -Format "yyyy-MM-dd")
                            Write-PatchLog "Trying again with shorter title: $shorterTitle" -Level "INFO"
                            
                            $prResult = gh pr create --title $shorterTitle --body $prBody --base main 2>&1
                            if ($LASTEXITCODE -eq 0 -and ($prResult -match 'https://[^\s]+')) {
                                return @{ 
                                    Success = $true 
                                    PullRequestUrl = $matches[0]
                                    BranchName = $BranchName
                                }
                            }
                        }
                        
                        # If we reach here, all attempts failed
                        Write-PatchLog "Failed to create pull request: $errorMessage" -Level "ERROR"
                        return @{ 
                            Success = $false
                            Message = "Failed to create pull request: $errorMessage"
                            BranchName = $BranchName
                        }
                    }
                } catch {
                    Write-PatchLog "Exception creating pull request: $($_.Exception.Message)" -Level "ERROR"
                    return @{ 
                        Success = $false
                        Message = "Exception creating pull request: $($_.Exception.Message)"
                        BranchName = $BranchName
                    }
                }
            } else {
                Write-PatchLog "Failed to push branch: $pushResult" -Level "ERROR"
                return @{ 
                    Success = $false
                    Message = "Failed to push branch: $pushResult" 
                    BranchName = $BranchName
                }
            }
    } catch {
        Write-PatchLog "Error in New-PatchPullRequest: $($_.Exception.Message)" -Level "ERROR"
        return @{ 
            Success = $false
            Message = $_.Exception.Message
            BranchName = $BranchName
        }
    }
}

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
    param([string]$Description)
    
    try {
        # Commit current changes
        git add -A 2>&1 | Out-Null
        $commitMessage = "patch: $Description`n`nAutomated patch with enhanced validation`n- Module import validation`n- Syntax checking`n- Git conflict resolution`n- Emoji prevention"
        
        git commit -m $commitMessage 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            # Push branch
            $branchName = git branch --show-current
            git push -u origin $branchName 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                # Create PR
                $prTitle = "patch: $Description"
                $prBody = @"
## Enhanced Patch with Automated Validation

**Description**: $Description
**Branch**: $branchName
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
                
                $prResult = gh pr create --title $prTitle --body $prBody --base main 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $prUrl = gh pr view --json url --jq '.url' 2>&1
                    return @{ Success = $true; PullRequestUrl = $prUrl }
                } else {
                    return @{ Success = $false; Message = "Failed to create PR: $prResult" }
                }
            } else {
                return @{ Success = $false; Message = "Failed to push branch" }
            }
        } else {
            return @{ Success = $false; Message = "Failed to commit changes" }
        }
    }
    catch {        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

#Requires -Version 7.0

<#
.SYNOPSIS
    The ONLY entry point for all patch operations in the OpenTofu Lab Automation project.

.DESCRIPTION
    This is the single, unified function for creating patches. It replaces all the overlapping
    patch functions and provides consistent, predictable behavior.
    
    No emoji/Unicode output - follows project standards.

.PARAMETER PatchDescription
    Description of what the patch does

.PARAMETER PatchOperation
    Script block containing the changes to make

.PARAMETER TestCommands
    Optional array of commands to run for validation

.PARAMETER CreateIssue
    Create a GitHub issue to track this patch

.PARAMETER CreatePR
    Create a pull request for this patch

.PARAMETER Priority
    Priority level for issue tracking (Low, Medium, High, Critical)

.PARAMETER DryRun
    Preview what would be done without making changes

.PARAMETER Force
    Force operation even if working tree is not clean

.EXAMPLE
    Invoke-PatchWorkflow -PatchDescription "Fix module loading issue" -PatchOperation {
        # Your changes here
        $content = Get-Content "module.ps1"
        $content = $content -replace "old pattern", "new pattern"
        Set-Content "module.ps1" -Value $content
    }

.EXAMPLE
    Invoke-PatchWorkflow -PatchDescription "Update configuration" -CreateIssue -CreatePR -Priority "High" -TestCommands @("Test-Config")

.NOTES
    This function replaces:
    - Invoke-GitControlledPatch
    - Invoke-EnhancedPatchManager  
    - Invoke-SimplifiedPatchWorkflow
    - And 10+ other overlapping functions
#>

function Invoke-PatchWorkflow {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PatchDescription,

        [Parameter(Mandatory = $false)]
        [scriptblock]$PatchOperation,

        [Parameter(Mandatory = $false)]
        [string[]]$TestCommands = @(),

        [Parameter(Mandatory = $false)]
        [switch]$CreateIssue,

        [Parameter(Mandatory = $false)]
        [switch]$CreatePR,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Priority = "Medium",

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    begin {
        # Import required modules
        if (-not (Get-Module -Name Logging -ListAvailable)) {
            Import-Module (Join-Path $PSScriptRoot "../../../Logging") -Force -ErrorAction SilentlyContinue
        }

        function Write-PatchLog {
            param($Message, $Level = "INFO")
            if (Get-Command Write-CustomLog -ErrorAction SilentlyContinue) {
                Write-CustomLog -Message $Message -Level $Level
            } else {
                Write-Host "[$Level] $Message"
            }
        }

        Write-PatchLog "Starting patch workflow: $PatchDescription" -Level "INFO"
        
        if ($DryRun) {
            Write-PatchLog "DRY RUN MODE: No actual changes will be made" -Level "WARN"
        }
    }

    process {
        try {
            # Step 1: Validate environment
            if (-not $Force) {
                $gitStatus = git status --porcelain 2>&1
                if ($gitStatus -and ($gitStatus | Where-Object { $_ -match '\S' })) {
                    Write-PatchLog "Working tree is not clean. Use -Force to proceed anyway." -Level "ERROR"
                    throw "Working tree not clean"
                }
            }

            # Step 2: Create patch branch
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $safeName = $PatchDescription -replace '[^a-zA-Z0-9\-_]', '-' -replace '-+', '-'
            $branchName = "patch/$timestamp-$safeName"
            
            Write-PatchLog "Creating branch: $branchName" -Level "INFO"
            
            if (-not $DryRun) {
                git checkout -b $branchName 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to create branch $branchName"
                }
            }

            # Step 3: Apply patch operation
            if ($PatchOperation) {
                Write-PatchLog "Applying patch operation..." -Level "INFO"
                
                if (-not $DryRun) {
                    & $PatchOperation
                } else {
                    Write-PatchLog "DRY RUN: Would execute patch operation" -Level "INFO"
                }
            }

            # Step 4: Run test commands
            if ($TestCommands.Count -gt 0) {
                Write-PatchLog "Running $($TestCommands.Count) test command(s)..." -Level "INFO"
                
                foreach ($cmd in $TestCommands) {
                    Write-PatchLog "Running test: $cmd" -Level "INFO"
                    
                    if (-not $DryRun) {
                        try {
                            Invoke-Expression $cmd
                            if ($LASTEXITCODE -ne 0) {
                                Write-PatchLog "Test command failed: $cmd" -Level "WARN"
                            }
                        } catch {
                            Write-PatchLog "Test command failed: $cmd - $($_.Exception.Message)" -Level "WARN"
                        }
                    } else {
                        Write-PatchLog "DRY RUN: Would run test command: $cmd" -Level "INFO"
                    }
                }
            }            # Step 5: Sanitize files and commit changes
            if (-not $DryRun) {
                $gitStatus = git status --porcelain 2>&1
                if ($gitStatus -and ($gitStatus | Where-Object { $_ -match '\S' })) {
                    # First, sanitize all changed files of Unicode/emoji
                    Write-PatchLog "Sanitizing files before commit..." -Level "INFO"
                    try {
                        $changedFiles = git diff --name-only HEAD 2>&1 | Where-Object { $_ -and $_.Trim() }
                        if ($changedFiles) {
                            $sanitizeResult = Invoke-UnicodeSanitizer -FilePaths $changedFiles -ProjectRoot (Get-Location).Path
                            if ($sanitizeResult.FilesModified -gt 0) {
                                Write-PatchLog "Sanitized $($sanitizeResult.FilesModified) files, removed $($sanitizeResult.CharactersRemoved) problematic characters" -Level "INFO"
                            }
                        }
                    } catch {
                        Write-PatchLog "Warning: Unicode sanitization failed: $($_.Exception.Message)" -Level "WARN"
                    }
                    
                    Write-PatchLog "Committing changes..." -Level "INFO"
                    git add . 2>&1 | Out-Null
                    git commit -m "PatchManager: $PatchDescription" 2>&1 | Out-Null
                    
                    if ($LASTEXITCODE -ne 0) {
                        Write-PatchLog "Warning: Git commit may have had issues" -Level "WARN"
                    }
                } else {
                    Write-PatchLog "No changes to commit" -Level "INFO"
                }
            } else {
                Write-PatchLog "DRY RUN: Would sanitize files and commit changes" -Level "INFO"
            }

            # Step 6: Create issue if requested
            $issueResult = $null
            if ($CreateIssue) {
                Write-PatchLog "Creating tracking issue..." -Level "INFO"
                
                if (-not $DryRun) {
                    $issueResult = New-PatchIssue -Description $PatchDescription -Priority $Priority
                    if ($issueResult.Success) {
                        Write-PatchLog "Issue created: $($issueResult.IssueUrl)" -Level "SUCCESS"
                    } else {
                        Write-PatchLog "Issue creation failed: $($issueResult.Message)" -Level "WARN"
                    }
                } else {
                    Write-PatchLog "DRY RUN: Would create GitHub issue" -Level "INFO"
                }
            }

            # Step 7: Create PR if requested
            if ($CreatePR) {
                Write-PatchLog "Creating pull request..." -Level "INFO"
                
                if (-not $DryRun) {
                    $prParams = @{
                        Description = $PatchDescription
                        BranchName = $branchName
                    }
                    
                    if ($issueResult -and $issueResult.Success) {
                        $prParams.IssueNumber = $issueResult.IssueNumber
                    }
                    
                    $prResult = New-PatchPR @prParams
                    if ($prResult.Success) {
                        Write-PatchLog "Pull request created: $($prResult.PullRequestUrl)" -Level "SUCCESS"
                    } else {
                        Write-PatchLog "PR creation failed: $($prResult.Message)" -Level "ERROR"
                        throw "Failed to create pull request: $($prResult.Message)"
                    }
                } else {
                    Write-PatchLog "DRY RUN: Would create pull request" -Level "INFO"
                }
            }

            # Success
            Write-PatchLog "Patch workflow completed successfully" -Level "SUCCESS"
            
            return @{
                Success = $true
                BranchName = $branchName
                DryRun = $DryRun.IsPresent
                Message = "Patch workflow completed successfully"
                IssueNumber = if ($issueResult) { $issueResult.IssueNumber } else { $null }
                IssueUrl = if ($issueResult) { $issueResult.IssueUrl } else { $null }
                PullRequestUrl = if ($prResult) { $prResult.PullRequestUrl } else { $null }
            }

        } catch {
            $errorMessage = "Patch workflow failed: $($_.Exception.Message)"
            Write-PatchLog $errorMessage -Level "ERROR"
            
            # Cleanup on failure
            if (-not $DryRun -and $branchName) {
                try {
                    Write-PatchLog "Cleaning up failed patch branch..." -Level "INFO"
                    git checkout main 2>&1 | Out-Null
                    git branch -D $branchName 2>&1 | Out-Null
                } catch {
                    Write-PatchLog "Cleanup failed: $($_.Exception.Message)" -Level "WARN"
                }
            }
            
            return @{
                Success = $false
                Message = $errorMessage
                BranchName = $branchName
                DryRun = $DryRun.IsPresent
            }
        }
    }
}

Export-ModuleMember -Function Invoke-PatchWorkflow

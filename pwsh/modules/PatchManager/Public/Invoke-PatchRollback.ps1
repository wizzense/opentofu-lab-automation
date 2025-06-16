#Requires -Version 7.0
<#
.SYNOPSIS
    Advanced rollback functionality for PatchManager with multiple rollback strategies
    
.DESCRIPTION
    This function provides comprehensive rollback capabilities for PatchManager operations:
    1. Rollback to specific commit hash
    2. Rollback to previous working state
    3. Emergency rollback with automatic backup restoration
    4. Selective file rollback
    
.PARAMETER RollbackTarget
    The target to rollback to: 'LastCommit', 'LastWorkingState', 'SpecificCommit', 'Emergency'
    
.PARAMETER CommitHash
    Specific commit hash to rollback to (required when RollbackTarget is 'SpecificCommit')
    
.PARAMETER AffectedFiles
    Array of specific files to rollback (for selective rollback)
    
.PARAMETER CreateBackup
    Create a backup before performing rollback
    
.PARAMETER Force
    Force the rollback operation even if working tree is not clean
    
.PARAMETER RestoreFromBackup
    Restore from a specific backup directory
    
.PARAMETER ValidateAfterRollback
    Run validation checks after rollback to ensure system integrity
    
.EXAMPLE
    Invoke-PatchRollback -RollbackTarget "LastCommit" -Force
    
.EXAMPLE
    Invoke-PatchRollback -RollbackTarget "SpecificCommit" -CommitHash "abc123" -CreateBackup
    
.EXAMPLE
    Invoke-PatchRollback -RollbackTarget "Emergency" -Force -ValidateAfterRollback
    
.NOTES
    - Always creates audit trail of rollback operations
    - Integrates with PatchManager's backup system
    - Provides multiple safety checks before rollback
    - Can detect and prevent destructive rollbacks
#>

function Invoke-PatchRollback {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("LastCommit", "LastWorkingState", "SpecificCommit", "Emergency", "SelectiveFiles")]
        [string]$RollbackTarget,
        
        [Parameter(Mandatory = $false)]
        [string]$CommitHash,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [string]$RestoreFromBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateAfterRollback
    )
    
    begin {
        Write-Host "Starting PatchManager rollback operation..." -ForegroundColor Cyan
        Write-Host "Target: $RollbackTarget" -ForegroundColor Yellow
        
        # Validate we're in a Git repository
        if (-not (Test-Path ".git")) {
            throw "Not in a Git repository. Rollback requires version control."
        }
        
        # Ensure we have Git available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git command not found. Please install Git."
        }
        
        # Initialize rollback log
        $script:RollbackLog = @{
            StartTime = Get-Date
            Target = $RollbackTarget
            CommitHash = $CommitHash
            AffectedFiles = $AffectedFiles
            CreateBackup = $CreateBackup
            Operations = @()
            Errors = @()
        }
        
        # Validate rollback target
        if ($RollbackTarget -eq "SpecificCommit" -and -not $CommitHash) {
            throw "CommitHash parameter is required when RollbackTarget is 'SpecificCommit'"
        }
        
        if ($RollbackTarget -eq "SelectiveFiles" -and $AffectedFiles.Count -eq 0) {
            throw "AffectedFiles parameter is required when RollbackTarget is 'SelectiveFiles'"
        }
    }
    
    process {
        try {
            # Pre-rollback safety checks
            Write-Host "Running pre-rollback safety checks..." -ForegroundColor Blue
            $safetyResult = Test-RollbackSafety -Target $RollbackTarget -CommitHash $CommitHash -Files $AffectedFiles
            
            if (-not $safetyResult.Safe -and -not $Force) {
                throw "Rollback safety check failed: $($safetyResult.Reason). Use -Force to override."
            }
            
            if (-not $safetyResult.Safe) {
                Write-Warning "Safety check failed but proceeding due to -Force: $($safetyResult.Reason)"
            }
            
            # Create backup if requested
            if ($CreateBackup) {
                Write-Host "Creating pre-rollback backup..." -ForegroundColor Green
                $backupResult = New-PreRollbackBackup
                $script:RollbackLog.Operations += @{ 
                    Operation = "Backup Created"
                    Path = $backupResult.BackupPath
                    Timestamp = Get-Date
                }
            }
            
            # Handle uncommitted changes
            $stashCreated = $false
            $gitStatus = git status --porcelain
            if ($gitStatus) {
                if ($Force) {
                    Write-Host "Stashing uncommitted changes before rollback..." -ForegroundColor Yellow
                    git stash push -m "Pre-rollback stash: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                    $stashCreated = $true
                    $script:RollbackLog.Operations += @{ 
                        Operation = "Changes Stashed"
                        Timestamp = Get-Date
                    }
                } else {
                    throw "Working tree has uncommitted changes. Use -Force to auto-stash or commit changes manually."
                }
            }
            
            # Execute rollback based on target type
            switch ($RollbackTarget) {
                "LastCommit" {
                    $rollbackResult = Invoke-LastCommitRollback
                }
                "LastWorkingState" {
                    $rollbackResult = Invoke-LastWorkingStateRollback
                }
                "SpecificCommit" {
                    $rollbackResult = Invoke-SpecificCommitRollback -CommitHash $CommitHash
                }
                "Emergency" {
                    $rollbackResult = Invoke-EmergencyRollback
                }
                "SelectiveFiles" {
                    $rollbackResult = Invoke-SelectiveFileRollback -Files $AffectedFiles
                }
            }
            
            if (-not $rollbackResult.Success) {
                throw "Rollback operation failed: $($rollbackResult.Message)"
            }
            
            $script:RollbackLog.Operations += @{
                Operation = "Rollback Executed"
                Target = $RollbackTarget
                Result = $rollbackResult
                Timestamp = Get-Date
            }
            
            # Restore from backup if specified
            if ($RestoreFromBackup) {
                Write-Host "Restoring from backup: $RestoreFromBackup" -ForegroundColor Green
                $restoreResult = Restore-FromBackupDirectory -BackupPath $RestoreFromBackup
                $script:RollbackLog.Operations += @{
                    Operation = "Backup Restored"
                    Path = $RestoreFromBackup
                    Result = $restoreResult
                    Timestamp = Get-Date
                }
            }
            
            # Post-rollback validation
            if ($ValidateAfterRollback) {
                Write-Host "Running post-rollback validation..." -ForegroundColor Blue
                $validationResult = Test-PostRollbackIntegrity
                $script:RollbackLog.Operations += @{
                    Operation = "Post-Rollback Validation"
                    Result = $validationResult
                    Timestamp = Get-Date
                }
                
                if (-not $validationResult.Success) {
                    Write-Warning "Post-rollback validation failed: $($validationResult.Message)"
                }
            }
            
            # Generate rollback report
            $reportPath = New-RollbackReport
            
            $script:RollbackLog.EndTime = Get-Date
            $script:RollbackLog.Duration = $script:RollbackLog.EndTime - $script:RollbackLog.StartTime
            
            Write-Host "Rollback completed successfully!" -ForegroundColor Green
            Write-Host "Duration: $($script:RollbackLog.Duration.TotalSeconds) seconds" -ForegroundColor Cyan
            Write-Host "Report saved: $reportPath" -ForegroundColor Cyan
            
            return @{
                Success = $true
                Message = "Rollback completed successfully"
                Target = $RollbackTarget
                Duration = $script:RollbackLog.Duration
                ReportPath = $reportPath
                StashCreated = $stashCreated
                BackupCreated = $CreateBackup
            }
            
        } catch {
            $script:RollbackLog.Errors += $_.Exception.Message
            Write-Error "Rollback failed: $($_.Exception.Message)"
            
            # Attempt recovery if possible
            if ($stashCreated) {
                Write-Host "Attempting to restore stashed changes..." -ForegroundColor Yellow
                try {
                    git stash pop
                    Write-Host "Stashed changes restored" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to restore stashed changes: $($_.Exception.Message)"
                }
            }
            
            return @{
                Success = $false
                Message = $_.Exception.Message
                Errors = $script:RollbackLog.Errors
            }
        }
    }
}

function Test-RollbackSafety {
    param(
        [string]$Target,
        [string]$CommitHash,
        [string[]]$Files
    )
    
    $checks = @{
        Safe = $true
        Reason = ""
        Warnings = @()
    }
    
    # Check if we're on a protected branch
    $currentBranch = git branch --show-current
    $protectedBranches = @("main", "master", "production", "release")
    
    if ($currentBranch -in $protectedBranches -and $Target -eq "Emergency") {
        $checks.Safe = $false
        $checks.Reason = "Emergency rollback not allowed on protected branch: $currentBranch"
        return $checks
    }
      # Check if target commit exists (for specific commit rollback)
    if ($Target -eq "SpecificCommit") {
        git cat-file -e $CommitHash 2>$null
        if ($LASTEXITCODE -ne 0) {
            $checks.Safe = $false
            $checks.Reason = "Commit hash '$CommitHash' does not exist"
            return $checks
        }
        
        # Check if commit is recent enough (within last 30 days)
        $commitDate = git show -s --format=%ct $CommitHash
        $commitDateTime = [DateTimeOffset]::FromUnixTimeSeconds($commitDate).DateTime
        $daysSinceCommit = (Get-Date) - $commitDateTime
        
        if ($daysSinceCommit.TotalDays -gt 30) {
            $checks.Warnings += "Rolling back to commit older than 30 days: $($daysSinceCommit.TotalDays) days"
        }
    }
    
    # Check for uncommitted changes that would be lost
    $uncommittedChanges = git status --porcelain
    if ($uncommittedChanges -and $Target -ne "SelectiveFiles") {
        $checks.Warnings += "Uncommitted changes will be stashed"
    }
    
    # Check if critical files would be affected
    $criticalFiles = @("PROJECT-MANIFEST.json", ".vscode/settings.json", ".github/workflows/*")
    if ($Files.Count -gt 0) {
        foreach ($file in $Files) {
            foreach ($critical in $criticalFiles) {
                if ($file -like $critical) {
                    $checks.Warnings += "Critical file will be affected: $file"
                }
            }
        }
    }
    
    return $checks
}

function Invoke-LastCommitRollback {
    Write-Host "Rolling back to last commit..." -ForegroundColor Yellow
    
    try {
        # Soft reset to last commit (preserves working directory)
        git reset --soft HEAD~1
        
        return @{
            Success = $true
            Message = "Successfully rolled back to last commit"
            CommitHash = git rev-parse HEAD
        }
    } catch {
        return @{
            Success = $false
            Message = "Failed to rollback to last commit: $($_.Exception.Message)"
        }
    }
}

function Invoke-LastWorkingStateRollback {
    Write-Host "Rolling back to last working state..." -ForegroundColor Yellow
    
    try {
        # Find the last commit that passed validation
        $commits = git log --oneline -10 | ForEach-Object { $_.Split(' ')[0] }
        
        foreach ($commit in $commits) {
            # Check if this commit has a clean state indicator
            $commitMessage = git log --format=%B -n 1 $commit
            if ($commitMessage -match "validation.*passed|tests.*passed|build.*success") {
                Write-Host "Found last working state at commit: $commit" -ForegroundColor Green
                git reset --hard $commit
                
                return @{
                    Success = $true
                    Message = "Successfully rolled back to last working state"
                    CommitHash = $commit
                }
            }
        }
        
        # If no validated commit found, rollback to HEAD~1
        Write-Warning "No validated commit found, rolling back to HEAD~1"
        git reset --hard HEAD~1
        
        return @{
            Success = $true
            Message = "Rolled back to HEAD~1 (no validated commit found)"
            CommitHash = git rev-parse HEAD
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Failed to rollback to last working state: $($_.Exception.Message)"
        }
    }
}

function Invoke-SpecificCommitRollback {
    param([string]$CommitHash)
    
    Write-Host "Rolling back to specific commit: $CommitHash" -ForegroundColor Yellow
    
    try {
        git reset --hard $CommitHash
        
        return @{
            Success = $true
            Message = "Successfully rolled back to commit: $CommitHash"
            CommitHash = $CommitHash
        }
    } catch {
        return @{
            Success = $false
            Message = "Failed to rollback to commit $CommitHash`: $($_.Exception.Message)"
        }
    }
}

function Invoke-EmergencyRollback {
    Write-Host "Performing emergency rollback..." -ForegroundColor Red
    
    try {
        # Emergency rollback: reset to last known good state and clean everything
        $lastGoodCommit = git log --grep="Auto-generated by PatchManager" --oneline -1 | ForEach-Object { $_.Split(' ')[0] }
        
        if ($lastGoodCommit) {
            Write-Host "Emergency rollback to last PatchManager commit: $lastGoodCommit" -ForegroundColor Yellow
            git reset --hard $lastGoodCommit
        } else {
            Write-Host "Emergency rollback to HEAD~5" -ForegroundColor Yellow
            git reset --hard HEAD~5
        }
        
        # Clean all untracked files
        git clean -fd
        
        # Remove any problematic directories
        @('node_modules', '.vs', 'build', 'coverage') | ForEach-Object {
            if (Test-Path $_) {
                Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        return @{
            Success = $true
            Message = "Emergency rollback completed"
            CommitHash = git rev-parse HEAD
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Emergency rollback failed: $($_.Exception.Message)"
        }
    }
}

function Invoke-SelectiveFileRollback {
    param([string[]]$Files)
    
    Write-Host "Rolling back selective files..." -ForegroundColor Yellow
    
    try {
        $successfulRollbacks = @()
        $failedRollbacks = @()
        
        foreach ($file in $Files) {
            try {
                if (Test-Path $file) {
                    git checkout HEAD -- $file
                    $successfulRollbacks += $file
                    Write-Host "  Rolled back: $file" -ForegroundColor Green
                } else {
                    Write-Warning "  File not found: $file"
                    $failedRollbacks += $file
                }
            } catch {
                Write-Warning "  Failed to rollback: $file - $($_.Exception.Message)"
                $failedRollbacks += $file
            }
        }
        
        return @{
            Success = $failedRollbacks.Count -eq 0
            Message = "Selective rollback: $($successfulRollbacks.Count) succeeded, $($failedRollbacks.Count) failed"
            SuccessfulFiles = $successfulRollbacks
            FailedFiles = $failedRollbacks
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Selective file rollback failed: $($_.Exception.Message)"
        }
    }
}

function New-PreRollbackBackup {
    $backupPath = "./backups/pre-rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    # Backup critical files
    $criticalFiles = @(
        "PROJECT-MANIFEST.json"
        ".vscode/settings.json"
        "pyproject.toml"
        "mkdocs.yml"
    )
    
    foreach ($file in $criticalFiles) {
        if (Test-Path $file) {
            Copy-Item $file -Destination $backupPath -Force
        }
    }
    
    # Backup current Git state
    git log --oneline -5 > "$backupPath/git-log.txt"
    git status > "$backupPath/git-status.txt"
    git diff > "$backupPath/git-diff.txt"
    
    return @{
        Success = $true
        BackupPath = $backupPath
        Message = "Pre-rollback backup created"
    }
}

function Test-PostRollbackIntegrity {
    $checks = @{
        Success = $true
        Issues = @()
        Message = ""
    }
    
    # Check that critical files exist
    $criticalFiles = @("PROJECT-MANIFEST.json", "README.md", ".vscode/settings.json")
    foreach ($file in $criticalFiles) {
        if (-not (Test-Path $file)) {
            $checks.Issues += "Critical file missing: $file"
            $checks.Success = $false
        }
    }
    
    # Check that modules can be loaded
    try {
        Import-Module "/pwsh/modules/LabRunner/" -Force -ErrorAction Stop
        Import-Module "/pwsh/modules/PatchManager/" -Force -ErrorAction Stop
    } catch {
        $checks.Issues += "Module loading failed: $($_.Exception.Message)"
        $checks.Success = $false
    }
    
    # Check Git repository state
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        $checks.Issues += "Working tree not clean after rollback"
    }
    
    $checks.Message = if ($checks.Success) { 
        "Post-rollback integrity check passed" 
    } else { 
        "Integrity issues found: $($checks.Issues -join '; ')" 
    }
    
    return $checks
}

function New-RollbackReport {
    $reportPath = "./ROLLBACK-REPORT-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    
    $report = @"
# PatchManager Rollback Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
**Target**: $($script:RollbackLog.Target)
**Duration**: $($script:RollbackLog.Duration.TotalSeconds) seconds

## Rollback Details

- **Target Type**: $($script:RollbackLog.Target)
- **Commit Hash**: $($script:RollbackLog.CommitHash)
- **Affected Files**: $($script:RollbackLog.AffectedFiles.Count)
- **Backup Created**: $($script:RollbackLog.CreateBackup)

## Operations Performed

$($script:RollbackLog.Operations | ForEach-Object { "- **$($_.Operation)** at $($_.Timestamp)" } | Out-String)

## Affected Files

$($script:RollbackLog.AffectedFiles | ForEach-Object { "- $_" } | Out-String)

## Errors

$($script:RollbackLog.Errors | ForEach-Object { "- $_" } | Out-String)

## Recovery Instructions

If this rollback caused issues:
1. Check the pre-rollback backup (if created)
2. Review the Git log: \`git log --oneline -10\`
3. Use \`git reflog\` to find previous states
4. Consider using \`Invoke-PatchRollback -RollbackTarget Emergency\` for critical issues

---
*Generated by PatchManager Rollback System v2.0*
"@

    Set-Content -Path $reportPath -Value $report
    return $reportPath
}

function Restore-FromBackupDirectory {
    param([string]$BackupPath)
    
    if (-not (Test-Path $BackupPath)) {
        return @{
            Success = $false
            Message = "Backup directory not found: $BackupPath"
        }
    }
    
    try {
        $restoredFiles = @()
        $backupFiles = Get-ChildItem -Path $BackupPath -File
        
        foreach ($backupFile in $backupFiles) {
            $originalPath = $backupFile.Name
            if (Test-Path $originalPath) {
                Copy-Item $backupFile.FullName -Destination $originalPath -Force
                $restoredFiles += $originalPath
            }
        }
        
        return @{
            Success = $true
            Message = "Restored $($restoredFiles.Count) files from backup"
            RestoredFiles = $restoredFiles
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Failed to restore from backup: $($_.Exception.Message)"
        }
    }
}

# Export the function for use by PatchManager
Export-ModuleMember -Function Invoke-PatchRollback

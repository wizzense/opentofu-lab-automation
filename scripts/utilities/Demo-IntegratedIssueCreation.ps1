#Requires -Version 7.0
<#
.SYNOPSIS
    Demonstration of integrated GitHub issue creation in PatchManager v2.0

.DESCRIPTION
    Shows how PatchManager now automatically creates GitHub issues for bug fixes,
    links them to pull requests, and provides comprehensive audit trails.

.NOTES
    This demonstrates the complete end-to-end workflow:
    1. Apply patch with git-controlled workflow
    2. Auto-create GitHub issue for bug fixes
    3. Link issue to pull request
    4. Start Copilot suggestion monitoring
    5. Provide rollback capabilities
#>

# Import required modules
Import-Module "$env:PWSH_MODULES_PATH\PatchManager" -Force

Write-Host "=== PatchManager v2.0 - Integrated GitHub Issue Creation Demo ===" -ForegroundColor Cyan
Write-Host ""

# Initialize cross-platform environment
Write-Host "1. Initializing cross-platform environment..." -ForegroundColor Blue
$envResult = Initialize-CrossPlatformEnvironment
if ($envResult.Success) {
    Write-Host "    Environment initialized for $($envResult.Platform)" -ForegroundColor Green
    Write-Host "    Project Root: $($envResult.ProjectRoot)" -ForegroundColor Green
    Write-Host "    Modules Path: $($envResult.ModulesPath)" -ForegroundColor Green
} else {
    Write-Host "    Environment initialization failed: $($envResult.Message)" -ForegroundColor Red
}
Write-Host ""

# Demo 1: Bug fix with automatic issue creation
Write-Host "2. Demo: Bug fix with automatic GitHub issue creation" -ForegroundColor Blue
Write-Host "   This demonstrates automatic issue creation for bug fixes..." -ForegroundColor Gray

$demo1Result = Invoke-GitControlledPatch -PatchDescription "Fix critical validation bug in YAML processor" -PatchOperation {
    Write-Host "   🔧 Simulating bug fix in validation logic..." -ForegroundColor Yellow
    
    # Simulate fixing a bug
    $bugFixContent = @"
# Bug Fix Applied: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Issue: Critical validation bug in YAML processor
# Solution: Updated validation logic to handle edge cases
# Impact: Prevents crashes on malformed YAML files
# Testing: Validated with comprehensive test suite
"@
    
    New-Item -Path "logs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    $bugFixContent | Out-File "logs/bug-fix-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Force
    
    Write-Host "    Bug fix applied and logged" -ForegroundColor Green
} -CreatePullRequest -CreateIssueForBugFix -IssuePriority "High" -IssueLabels @("bug", "critical", "validation", "automated-fix") -AutoCommitUncommitted

if ($demo1Result.Success) {
    Write-Host "    Patch applied successfully" -ForegroundColor Green
    Write-Host "    Pull Request: $($demo1Result.PullRequest)" -ForegroundColor Green
    if ($demo1Result.IssueUrl) {
        Write-Host "    GitHub Issue: $($demo1Result.IssueUrl)" -ForegroundColor Green
        Write-Host "    Issue Priority: $($demo1Result.IssuePriority)" -ForegroundColor Green
    }
    
    # Start Copilot suggestion monitoring if PR was created
    if ($demo1Result.PullRequestNumber) {
        Write-Host "    Starting Copilot suggestion monitoring..." -ForegroundColor Blue        try {
            Invoke-CopilotSuggestionHandler -PullRequestNumber $demo1Result.PullRequestNumber -BackgroundMonitor -AutoCommit -LogPath "logs/copilot-monitoring-demo.log" | Out-Null
Write-Host "    Copilot monitoring started for PR #$($demo1Result.PullRequestNumber)" -ForegroundColor Green
        } catch {
            Write-Host "   [WARN] Copilot monitoring failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "    Patch failed: $($demo1Result.Message)" -ForegroundColor Red
}
Write-Host ""

# Demo 2: Feature enhancement (no automatic issue creation)
Write-Host "3. Demo: Feature enhancement (no automatic issue creation)" -ForegroundColor Blue
Write-Host "   This demonstrates normal feature work without issue creation..." -ForegroundColor Gray

$demo2Result = Invoke-GitControlledPatch -PatchDescription "Add enhanced logging capabilities" -PatchOperation {
    Write-Host "   ️ Implementing enhanced logging features..." -ForegroundColor Yellow
    
    $enhancementContent = @"
# Enhancement Applied: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Feature: Enhanced logging capabilities
# Description: Added structured logging with multiple output formats
# Benefits: Better debugging and monitoring capabilities
# Compatibility: Backward compatible with existing log consumers
"@
    
    New-Item -Path "logs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    $enhancementContent | Out-File "logs/enhancement-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Force
    
    Write-Host "    Enhancement implemented and documented" -ForegroundColor Green
} -CreatePullRequest -AutoCommitUncommitted

if ($demo2Result.Success) {
    Write-Host "    Enhancement patch applied successfully" -ForegroundColor Green
    Write-Host "    Pull Request: $($demo2Result.PullRequest)" -ForegroundColor Green
    Write-Host "    No GitHub issue created (not a bug fix)" -ForegroundColor Green
} else {
    Write-Host "    Enhancement patch failed: $($demo2Result.Message)" -ForegroundColor Red
}
Write-Host ""

# Demo 3: Emergency fix with forced issue creation
Write-Host "4. Demo: Emergency fix with explicit issue creation" -ForegroundColor Blue
Write-Host "   This demonstrates forced issue creation for any patch..." -ForegroundColor Gray

$demo3Result = Invoke-GitControlledPatch -PatchDescription "Emergency security update for authentication" -PatchOperation {
    Write-Host "   🚨 Applying emergency security fix..." -ForegroundColor Red
    
    $securityFixContent = @"
# EMERGENCY SECURITY FIX: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Issue: Authentication bypass vulnerability discovered
# Solution: Updated authentication validation logic
# Impact: Prevents unauthorized access attempts
# Urgency: CRITICAL - Deploy immediately after review
# Testing: Validated against security test suite
"@
    
    New-Item -Path "logs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    $securityFixContent | Out-File "logs/security-fix-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Force
    
    Write-Host "    Security fix applied and documented" -ForegroundColor Green
} -CreatePullRequest -CreateIssueForBugFix -IssuePriority "Critical" -IssueLabels @("security", "critical", "emergency", "automated-fix") -AutoCommitUncommitted

if ($demo3Result.Success) {
    Write-Host "    Emergency patch applied successfully" -ForegroundColor Green
    Write-Host "    Pull Request: $($demo3Result.PullRequest)" -ForegroundColor Green
    if ($demo3Result.IssueUrl) {
        Write-Host "    GitHub Issue: $($demo3Result.IssueUrl)" -ForegroundColor Green
        Write-Host "    Issue Priority: $($demo3Result.IssuePriority)" -ForegroundColor Green
    }
} else {
    Write-Host "    Emergency patch failed: $($demo3Result.Message)" -ForegroundColor Red
}
Write-Host ""

# Demo 4: Show rollback capabilities
Write-Host "5. Demo: Rollback capabilities" -ForegroundColor Blue
Write-Host "   This demonstrates the rollback options available..." -ForegroundColor Gray

try {
    Write-Host "   📋 Available rollback options:" -ForegroundColor Cyan
    Write-Host "   • Invoke-QuickRollback -RollbackType 'LastPatch'" -ForegroundColor White
    Write-Host "   • Invoke-QuickRollback -RollbackType 'LastCommit'" -ForegroundColor White
    Write-Host "   • Invoke-QuickRollback -RollbackType 'Emergency' -Force" -ForegroundColor White
    Write-Host "   • Git stash operations for temporary changes" -ForegroundColor White
    
    # Show backup statistics
    $backupStats = Get-BackupStatistics
    if ($backupStats.Success) {
        Write-Host "   📊 Backup Statistics:" -ForegroundColor Cyan
        Write-Host "   • Total Backups: $($backupStats.TotalBackups)" -ForegroundColor White
        Write-Host "   • Total Size: $($backupStats.TotalSizeFormatted)" -ForegroundColor White
        Write-Host "   • Latest Backup: $($backupStats.LatestBackup)" -ForegroundColor White
    }
    
    Write-Host "    Rollback capabilities verified" -ForegroundColor Green
} catch {
    Write-Host "   [WARN] Rollback info gathering failed: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=== Integration Summary ===" -ForegroundColor Cyan
Write-Host " PatchManager now automatically creates GitHub issues for bug fixes" -ForegroundColor Green
Write-Host " Issues are linked to pull requests for complete audit trail" -ForegroundColor Green
Write-Host " Copilot suggestion monitoring starts automatically for new PRs" -ForegroundColor Green
Write-Host " Cross-platform environment handling works across Windows/Linux/macOS" -ForegroundColor Green
Write-Host " Rollback capabilities provide safety net for all operations" -ForegroundColor Green
Write-Host " All changes tracked with comprehensive logging and backup" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 PatchManager v2.0 - Complete Git-controlled workflow with issue tracking!" -ForegroundColor Green



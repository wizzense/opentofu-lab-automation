#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Demonstration of enhanced PatchManager with DirectCommit and Rollback capabilities
    
.DESCRIPTION
    This script demonstrates the advanced PatchManager features including:
    - DirectCommit for quick fixes without branch creation
    - Comprehensive rollback capabilities for emergency recovery
    - Integration with cleanup and validation systems
    - Reduced dependency on traditional backup systems
    
.PARAMETER Mode
    Operation mode: 'DirectCommit', 'Rollback', 'Emergency', 'Demo'
    
.PARAMETER RollbackTarget
    Rollback target when Mode is 'Rollback'
    
.PARAMETER CommitHash
    Specific commit hash for rollback operations
    
.EXAMPLE
    .\Demo-EnhancedPatchManager.ps1 -Mode "DirectCommit"
    
.EXAMPLE
    .\Demo-EnhancedPatchManager.ps1 -Mode "Rollback" -RollbackTarget "LastCommit"
    
.EXAMPLE
    .\Demo-EnhancedPatchManager.ps1 -Mode "Emergency"
    
.NOTES
    - Demonstrates modern change control practices
    - Shows how PatchManager reduces backup requirements
    - Includes comprehensive error handling and rollback
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("DirectCommit", "Rollback", "Emergency", "Demo")]
    [string]$Mode = "Demo",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("LastCommit", "LastWorkingState", "SpecificCommit", "Emergency", "SelectiveFiles")]
    [string]$RollbackTarget = "LastCommit",
    
    [Parameter(Mandatory = $false)]
    [string]$CommitHash
)

$ErrorActionPreference = "Stop"

# Import PatchManager module
Write-Host "Importing enhanced PatchManager module..." -ForegroundColor Cyan
Import-Module "/pwsh/modules/PatchManager/" -Force

# Validate we're in the correct project directory
if (-not (Test-Path "PROJECT-MANIFEST.json")) {
    throw "This script must be run from the project root directory"
}

Write-Host "Enhanced PatchManager Demonstration" -ForegroundColor Green
Write-Host "Mode: $Mode" -ForegroundColor Yellow

switch ($Mode) {
    "DirectCommit" {
        Write-Host "`n=== DirectCommit Demonstration ===" -ForegroundColor Cyan
        
        try {
            # Demonstrate DirectCommit for quick maintenance
            $result = Invoke-GitControlledPatch `
                -PatchDescription "demo: update project manifest timestamp" `
                -PatchOperation {
                    Write-Host "Updating project manifest..." -ForegroundColor Blue
                    
                    if (Test-Path "PROJECT-MANIFEST.json") {
                        $manifest = Get-Content "PROJECT-MANIFEST.json" | ConvertFrom-Json
                        $manifest.project.lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $manifest.project.lastDemo = "Enhanced PatchManager DirectCommit Demo"
                        $manifest | ConvertTo-Json -Depth 10 | Set-Content "PROJECT-MANIFEST.json"
                        Write-Host "Project manifest updated successfully" -ForegroundColor Green
                    } else {
                        Write-Warning "PROJECT-MANIFEST.json not found"
                    }
                } `
                -DirectCommit `
                -Force `
                -CleanupMode "Safe"
            
            if ($result.Success) {
                Write-Host "`nDirectCommit SUCCESS!" -ForegroundColor Green
                Write-Host "Branch: $($result.Branch)" -ForegroundColor Cyan
                Write-Host "Files Changed: $($result.ChangedFiles.Count)" -ForegroundColor Cyan
                Write-Host "Commit Hash: $($result.CommitHash)" -ForegroundColor Cyan
                
                Write-Host "`nBenefits of DirectCommit:" -ForegroundColor Yellow
                Write-Host "- No branch creation overhead" -ForegroundColor White
                Write-Host "- Immediate commit with full audit trail" -ForegroundColor White
                Write-Host "- Integrated cleanup and validation" -ForegroundColor White
                Write-Host "- Perfect for maintenance tasks" -ForegroundColor White
            } else {
                Write-Error "DirectCommit failed: $($result.Message)"
            }
            
        } catch {
            Write-Error "DirectCommit demonstration failed: $($_.Exception.Message)"
        }
    }
    
    "Rollback" {
        Write-Host "`n=== Rollback Demonstration ===" -ForegroundColor Cyan
        
        try {
            # Demonstrate rollback capabilities
            $rollbackParams = @{
                RollbackTarget = $RollbackTarget
                Force = $true
                CreateBackup = $true
                ValidateAfterRollback = $true
            }
            
            if ($CommitHash -and $RollbackTarget -eq "SpecificCommit") {
                $rollbackParams.CommitHash = $CommitHash
            }
            
            Write-Host "Performing rollback with target: $RollbackTarget" -ForegroundColor Yellow
            
            $result = Invoke-PatchRollback @rollbackParams
            
            if ($result.Success) {
                Write-Host "`nRollback SUCCESS!" -ForegroundColor Green
                Write-Host "Target: $($result.Target)" -ForegroundColor Cyan
                Write-Host "Duration: $($result.Duration.TotalSeconds) seconds" -ForegroundColor Cyan
                Write-Host "Report: $($result.ReportPath)" -ForegroundColor Cyan
                
                Write-Host "`nRollback Benefits:" -ForegroundColor Yellow
                Write-Host "- Instant recovery from breaking changes" -ForegroundColor White
                Write-Host "- Multiple rollback strategies available" -ForegroundColor White
                Write-Host "- Automatic safety checks and validation" -ForegroundColor White
                Write-Host "- Complete audit trail of operations" -ForegroundColor White
                Write-Host "- Reduces need for frequent backups" -ForegroundColor White
            } else {
                Write-Error "Rollback failed: $($result.Message)"
            }
            
        } catch {
            Write-Error "Rollback demonstration failed: $($_.Exception.Message)"
        }
    }
    
    "Emergency" {
        Write-Host "`n=== Emergency Recovery Demonstration ===" -ForegroundColor Red
        
        Write-Host "WARNING: This demonstrates emergency recovery procedures" -ForegroundColor Red
        Write-Host "In a real scenario, use this when system is in critical state" -ForegroundColor Yellow
        
        try {
            # Demonstrate emergency recovery workflow
            Write-Host "`nStep 1: Assess current system state..." -ForegroundColor Blue
            $gitStatus = git status --porcelain
            $currentBranch = git branch --show-current
            $lastCommits = git log --oneline -5
            
            Write-Host "Current branch: $currentBranch" -ForegroundColor White
            Write-Host "Uncommitted changes: $($gitStatus.Count) files" -ForegroundColor White
            Write-Host "Recent commits available for rollback" -ForegroundColor White
            
            Write-Host "`nStep 2: Emergency rollback..." -ForegroundColor Blue
            $emergencyResult = Invoke-PatchRollback `
                -RollbackTarget "Emergency" `
                -Force `
                -CreateBackup `
                -ValidateAfterRollback
            
            if ($emergencyResult.Success) {
                Write-Host "`nEMERGENCY RECOVERY SUCCESS!" -ForegroundColor Green
                Write-Host "System reset to last known good state" -ForegroundColor Cyan
                Write-Host "Duration: $($emergencyResult.Duration.TotalSeconds) seconds" -ForegroundColor Cyan
                
                Write-Host "`nEmergency Recovery Benefits:" -ForegroundColor Yellow
                Write-Host "- Immediate system stabilization" -ForegroundColor White
                Write-Host "- Automatic cleanup of problematic files" -ForegroundColor White
                Write-Host "- Reset to last PatchManager-verified state" -ForegroundColor White
                Write-Host "- Full backup created before operation" -ForegroundColor White
                Write-Host "- Post-recovery validation ensures integrity" -ForegroundColor White
                
                Write-Host "`nTraditional vs PatchManager Recovery:" -ForegroundColor Yellow
                Write-Host "Traditional: Hours to restore from backup" -ForegroundColor Red
                Write-Host "PatchManager: Seconds with instant rollback" -ForegroundColor Green
            } else {
                Write-Error "Emergency recovery failed: $($emergencyResult.Message)"
            }
            
        } catch {
            Write-Error "Emergency recovery demonstration failed: $($_.Exception.Message)"
        }
    }
    
    "Demo" {
        Write-Host "`n=== Complete PatchManager Feature Demo ===" -ForegroundColor Cyan
        
        Write-Host "`n1. Modern Change Control Benefits:" -ForegroundColor Yellow
        Write-Host "    Git-based versioning eliminates backup dependencies" -ForegroundColor Green
        Write-Host "    Instant rollback capabilities" -ForegroundColor Green
        Write-Host "    Complete audit trail of all changes" -ForegroundColor Green
        Write-Host "    Automated safety checks and validation" -ForegroundColor Green
        Write-Host "    DirectCommit for quick fixes" -ForegroundColor Green
        Write-Host "    Emergency recovery procedures" -ForegroundColor Green
        
        Write-Host "`n2. Available Operations:" -ForegroundColor Yellow
        Write-Host "   • DirectCommit: Quick fixes without branch overhead" -ForegroundColor White
        Write-Host "   • Branch Workflow: Full PR process for major changes" -ForegroundColor White
        Write-Host "   • Comprehensive Cleanup: Integrated file organization" -ForegroundColor White
        Write-Host "   • Emergency Rollback: Instant recovery from critical issues" -ForegroundColor White
        Write-Host "   • Selective Rollback: Targeted file recovery" -ForegroundColor White
        Write-Host "   • Validation Integration: Automatic integrity checks" -ForegroundColor White
        
        Write-Host "`n3. Backup Strategy Evolution:" -ForegroundColor Yellow
        Write-Host "   Traditional: Daily full backups (slow, error-prone)" -ForegroundColor Red
        Write-Host "   PatchManager: Weekly config backups + instant Git rollback" -ForegroundColor Green
        Write-Host "   Recovery Time: Hours → Seconds" -ForegroundColor Green
        Write-Host "   Storage Requirements: High → Minimal" -ForegroundColor Green
        Write-Host "   Accuracy: Manual → Automated" -ForegroundColor Green
        
        Write-Host "`n4. Example Workflows:" -ForegroundColor Yellow
        
        Write-Host "`n   Quick Fix Example:" -ForegroundColor White
        Write-Host "   Invoke-GitControlledPatch -DirectCommit -Force \" -ForegroundColor Gray
        Write-Host "       -PatchDescription 'fix: update hardcoded paths' \" -ForegroundColor Gray
        Write-Host "       -PatchOperation { Fix-HardcodedPaths }" -ForegroundColor Gray
        
        Write-Host "`n   Emergency Recovery Example:" -ForegroundColor White
        Write-Host "   Invoke-PatchRollback -RollbackTarget Emergency -Force" -ForegroundColor Gray
        
        Write-Host "`n   Comprehensive Cleanup Example:" -ForegroundColor White
        Write-Host "   Invoke-GitControlledPatch -CleanupMode Aggressive \" -ForegroundColor Gray
        Write-Host "       -PatchDescription 'chore: comprehensive cleanup' \" -ForegroundColor Gray
        Write-Host "       -PatchOperation { Remove-UnnecessaryFiles }" -ForegroundColor Gray
        
        Write-Host "`n5. Safety Features:" -ForegroundColor Yellow
        Write-Host "    Pre-operation safety checks" -ForegroundColor Green
        Write-Host "    Automatic stash management" -ForegroundColor Green
        Write-Host "    Protected branch detection" -ForegroundColor Green
        Write-Host "    Post-operation validation" -ForegroundColor Green
        Write-Host "    Complete operation logging" -ForegroundColor Green
        Write-Host "    Multiple rollback strategies" -ForegroundColor Green
        
        Write-Host "`nTo see specific demonstrations:" -ForegroundColor Cyan
        Write-Host "  .\Demo-EnhancedPatchManager.ps1 -Mode DirectCommit" -ForegroundColor White
        Write-Host "  .\Demo-EnhancedPatchManager.ps1 -Mode Rollback -RollbackTarget LastCommit" -ForegroundColor White
        Write-Host "  .\Demo-EnhancedPatchManager.ps1 -Mode Emergency" -ForegroundColor White
    }
}

Write-Host "`n=== Enhanced PatchManager Demo Complete ===" -ForegroundColor Green
Write-Host "Modern change control reduces backup dependencies while improving reliability!" -ForegroundColor Cyan

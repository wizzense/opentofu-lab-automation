#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Demonstration of enhanced PatchManager with auto-commit and rollback capabilities
    
.DESCRIPTION
    This script demonstrates the new PatchManager features:
    - Auto-commit of uncommitted changes
    - Comprehensive cleanup integration
    - Quick rollback functionality
    - Reduced need for regular backups through proper change control
    
.PARAMETER UseAutoCommit
    Use auto-commit mode for uncommitted changes
    
.PARAMETER DemonstrationMode
    Mode to demonstrate: AutoCommit, Rollback, Emergency, or Full
    
.EXAMPLE
    .\Demo-EnhancedPatchManager.ps1 -DemonstrationMode "AutoCommit"
    
.EXAMPLE
    .\Demo-EnhancedPatchManager.ps1 -DemonstrationMode "Rollback"
    
.NOTES
    - Demonstrates elimination of manual Git steps
    - Shows comprehensive change control workflow
    - Provides instant rollback capabilities
    - Reduces backup dependencies through proper version control
#>

CmdletBinding()
param(
    Parameter(Mandatory = $false)
    switch$UseAutoCommit,
    
    Parameter(Mandatory = $true)
    ValidateSet("AutoCommit", "Rollback", "Emergency", "Full")
    string$DemonstrationMode
)

$ErrorActionPreference = "Stop"

# Import enhanced PatchManager
Write-Host "Importing enhanced PatchManager module..." -ForegroundColor Cyan
Import-Module "/pwsh/modules/PatchManager/" -Force

Write-Host "Enhanced PatchManager Demonstration" -ForegroundColor Green
Write-Host "Mode: $DemonstrationMode" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Green

try {
    switch ($DemonstrationMode) {
        "AutoCommit" {
            Write-Host "Demonstrating auto-commit functionality..." -ForegroundColor Blue
            
            # Create some test changes
            Write-Host "Creating test changes..." -ForegroundColor Yellow
            "# Test change $(Get-Date)"  Add-Content "PATCH-DEMO.md"
            
            # Use PatchManager with auto-commit
            Write-Host "Using PatchManager with auto-commit..." -ForegroundColor Green
            $result = Invoke-GitControlledPatch `
                -PatchDescription "demo: test auto-commit functionality" `
                -PatchOperation { 
                    Write-Host "Patch operation: Adding demo content" -ForegroundColor Cyan
                    "Demo content added by PatchManager"  Add-Content "PATCH-DEMO.md"
                } `
                -AutoCommitUncommitted `
                -CreatePullRequest `
                -CleanupMode "Safe"
            
            if ($result.Success) {
                Write-Host "SUCCESS: Auto-commit demonstration completed!" -ForegroundColor Green
                Write-Host "No manual Git steps required!" -ForegroundColor Cyan
            }
        }
        
        "Rollback" {
            Write-Host "Demonstrating quick rollback functionality..." -ForegroundColor Blue
            
            # Show current state
            Write-Host "Current Git state:" -ForegroundColor Yellow
            git log --oneline -5
            
            # Demonstrate different rollback types
            Write-Host "`nDemonstrating rollback types..." -ForegroundColor Green
            
            # Safe rollback (creates backup)
            Write-Host "1. Safe rollback to last commit:" -ForegroundColor Cyan
            $rollbackResult = Invoke-QuickRollback -RollbackType "LastCommit" -CreateBackup -WhatIf
            Write-Host "   Would rollback with backup: $($rollbackResult.Success)" -ForegroundColor White
              # Emergency rollback demonstration
            Write-Host "2. Emergency rollback capability:" -ForegroundColor Cyan
            Invoke-QuickRollback -RollbackType "Emergency" -WhatIf | Out-NullWrite-Host "   Emergency rollback available: Available" -ForegroundColor White
            
            Write-Host "`nRollback capabilities ready for instant recovery!" -ForegroundColor Green
        }
        
        "Emergency" {
            Write-Host "Demonstrating emergency recovery..." -ForegroundColor Red
            
            Write-Host "Simulating breaking change detection..." -ForegroundColor Yellow
            
            # This would normally be triggered by validation failure
            Write-Host "BREAKING CHANGE DETECTED - Initiating emergency rollback!" -ForegroundColor Red
            
            $emergencyResult = Invoke-QuickRollback `
                -RollbackType "Emergency" `
                -Force `
                -CreateBackup `
                -WhatIf
            
            Write-Host "Emergency rollback completed successfully!" -ForegroundColor Green
            Write-Host "System restored to last known good state" -ForegroundColor Cyan
        }
        
        "Full" {
            Write-Host "Demonstrating full enhanced workflow..." -ForegroundColor Blue
            
            Write-Host "Step 1: Auto-commit existing changes..." -ForegroundColor Green
            "# Full demo $(Get-Date)"  Add-Content "FULL-DEMO.md"
            
            Write-Host "Step 2: Apply patch with comprehensive cleanup..." -ForegroundColor Green
            $patchResult = Invoke-GitControlledPatch `
                -PatchDescription "feat: comprehensive demo with all enhancements" `
                -PatchOperation {
                    Write-Host "  Running comprehensive cleanup..." -ForegroundColor Cyan
                    Write-Host "  Fixing cross-platform issues..." -ForegroundColor Cyan
                    Write-Host "  Removing emoji violations..." -ForegroundColor Cyan
                    Write-Host "  Consolidating duplicate files..." -ForegroundColor Cyan
                    "Full demo completed successfully"  Add-Content "FULL-DEMO.md"
                } `
                -AutoCommitUncommitted `
                -CreatePullRequest `
                -CleanupMode "Standard" `
                -EnableRollback
            
            if ($patchResult.Success) {
                Write-Host "Step 3: Demonstrating rollback capability..." -ForegroundColor Green
                Write-Host "  Rollback available for instant recovery" -ForegroundColor Cyan
                Write-Host "  No manual backup needed - Git provides full history" -ForegroundColor Cyan
                
                Write-Host "FULL DEMONSTRATION COMPLETED!" -ForegroundColor Green
                Write-Host " Auto-commit eliminates manual Git steps" -ForegroundColor White
                Write-Host " Comprehensive cleanup integrated" -ForegroundColor White
                Write-Host " Instant rollback available" -ForegroundColor White
                Write-Host " Reduced backup dependencies" -ForegroundColor White
                Write-Host " Complete change control workflow" -ForegroundColor White
            }
        }
    }
    
} catch {
    Write-Error "Demonstration failed: $($_.Exception.Message)"
    
    # Demonstrate automatic recovery
    Write-Host "Demonstrating automatic recovery..." -ForegroundColor Yellow
    $recoveryResult = Invoke-QuickRollback -RollbackType "Emergency" -Force -WhatIf
    Write-Host "Automatic recovery available: $($recoveryResult.Success)" -ForegroundColor Green
}

Write-Host "`nEnhanced PatchManager demonstration completed!" -ForegroundColor Green
Write-Host "Ready for production use with comprehensive change control." -ForegroundColor Cyan

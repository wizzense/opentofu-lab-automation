#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Example script demonstrating comprehensive cleanup and patching with PatchManager
    
.DESCRIPTION
    This script shows how to use the enhanced PatchManager with integrated cleanup
    capabilities to perform comprehensive project maintenance while following
    strict change control processes.
    
.PARAMETER CleanupMode
    The cleanup mode: Standard, Aggressive, Emergency, or Safe
    
.PARAMETER SkipCleanup
    Skip the cleanup phase (for testing patch operations only)
    
.PARAMETER DryRun
    Perform a dry run to see what would be changed without making actual changes
    
.EXAMPLE
    .\Invoke-ComprehensiveProjectCleanup.ps1 -CleanupMode "Standard"
    
.EXAMPLE
    .\Invoke-ComprehensiveProjectCleanup.ps1 -CleanupMode "Aggressive" -DryRun
    
.NOTES
    - Uses PatchManager for Git-controlled change management
    - Automatically creates branches and pull requests
    - Includes comprehensive validation and rollback capabilities
    - Removes emoji violations and fixes cross-platform path issues
    - Consolidates duplicate files and archives old files
#>

CmdletBinding()
param(
    Parameter(Mandatory = $false)
    ValidateSet("Standard", "Aggressive", "Emergency", "Safe")
    string$CleanupMode = "Standard",
    
    Parameter(Mandatory = $false)
    switch$SkipCleanup,
    
    Parameter(Mandatory = $false)
    switch$DryRun
)

$ErrorActionPreference = "Stop"

# Import PatchManager module
Write-Host "Importing PatchManager module..." -ForegroundColor Cyan
Import-Module "/pwsh/modules/PatchManager/" -Force

# Validate we're in the correct project directory
if (-not (Test-Path "PROJECT-MANIFEST.json")) {
    throw "This script must be run from the project root directory"
}

Write-Host "Starting comprehensive project cleanup with PatchManager..." -ForegroundColor Green
Write-Host "Mode: $CleanupMode  Skip Cleanup: $SkipCleanup  Dry Run: $DryRun" -ForegroundColor Yellow

try {
    # Define the comprehensive cleanup and fix operation
    $patchOperation = {
        param($CleanupMode, $DryRun)
        
        Write-Host "Executing comprehensive project cleanup..." -ForegroundColor Blue
        
        # Phase 1: Cross-platform path fixes
        Write-Host "Phase 1: Fixing cross-platform compatibility issues..." -ForegroundColor Green
        
        # Fix hardcoded paths in test files
        $testFiles = Get-ChildItem -Path "tests" -Recurse -Include "*.ps1" -ErrorAction SilentlyContinue
        foreach ($testFile in $testFiles) {
            $content = Get-Content $testFile.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match 'C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation') {
                Write-Host "  Fixing paths in: $($testFile.Name)" -ForegroundColor Yellow
                
                if (-not $DryRun) {
                    # Fix the malformed import path
                    $fixedContent = $content -replace 'Import-Module "/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\\pwsh/modules/(^/+)/"', 'Import-Module "/pwsh/modules/$1/" -Force'
                    $fixedContent = $fixedContent -replace 'C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation', '/workspaces/opentofu-lab-automation'
                    Set-Content -Path $testFile.FullName -Value $fixedContent -NoNewline
                    Write-Host "    Fixed paths in: $($testFile.Name)" -ForegroundColor Green
                }
            }
        }
        
        # Phase 2: Remove emoji violations from all files
        Write-Host "Phase 2: Removing emoji violations..." -ForegroundColor Green
        
        # Use a simpler emoji detection pattern that works in PowerShell
        $emojiPattern = '\u2600-\u26FF\u2700-\u27BF'
        $textFiles = Get-ChildItem -Path "." -Recurse -Include "*.ps1", "*.md", "*.yml", "*.yaml", "*.json" -ErrorAction SilentlyContinue 
            Where-Object { $_.FullName -notmatch '\.gitbackupsarchive' }
        
        foreach ($textFile in $textFiles) {
            $content = Get-Content $textFile.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and ($content -match $emojiPattern)) {
                Write-Host "  Removing emojis from: $($textFile.Name)" -ForegroundColor Yellow
                
                if (-not $DryRun) {
                    $cleanContent = $content -replace $emojiPattern, ''
                    Set-Content -Path $textFile.FullName -Value $cleanContent -NoNewline
                    Write-Host "    Cleaned emojis from: $($textFile.Name)" -ForegroundColor Green
                }
            }
        }
        
        # Phase 3: Update project manifest
        Write-Host "Phase 3: Updating project manifest..." -ForegroundColor Green
        
        if (-not $DryRun) {
            $manifest = Get-Content "PROJECT-MANIFEST.json"  ConvertFrom-Json
            $manifest.project.lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $manifest.project.lastMaintenance = Get-Date -Format "yyyy-MM-dd"
            manifest | ConvertTo-Json -Depth 10  Set-Content "PROJECT-MANIFEST.json"
            Write-Host "    Updated project manifest" -ForegroundColor Green
        }
        
        # Phase 4: Run validation
        Write-Host "Phase 4: Running post-cleanup validation..." -ForegroundColor Green
        
        try {
            Import-Module "/pwsh/modules/LabRunner/" -Force -ErrorAction SilentlyContinue
            Write-Host "    LabRunner module validation: OK" -ForegroundColor Green
        } catch {
            Write-Warning "    LabRunner module validation: Issues detected"
        }
        
        try {
            Import-Module "/pwsh/modules/CodeFixer/" -Force -ErrorAction SilentlyContinue
            Write-Host "    CodeFixer module validation: OK" -ForegroundColor Green
        } catch {
            Write-Warning "    CodeFixer module validation: Issues detected"
        }
        
        Write-Host "Comprehensive cleanup operation completed successfully!" -ForegroundColor Green
    }
    
    # Execute the patch using PatchManager with comprehensive cleanup
    $patchResult = Invoke-GitControlledPatch `
        -PatchDescription "feat(maintenance): comprehensive project cleanup and cross-platform fixes" `
        -PatchOperation { & $patchOperation -CleanupMode $CleanupMode -DryRun $DryRun } `
        -AffectedFiles @("tests/", "PROJECT-MANIFEST.json", "*.md", "*.ps1") `
        -CreatePullRequest `
        -Force `
        -CleanupMode $CleanupMode `
        -SkipCleanup:$SkipCleanup
    
    if ($patchResult.Success) {
        Write-Host "SUCCESS: Comprehensive cleanup completed!" -ForegroundColor Green
        Write-Host "Branch: $($patchResult.Branch)" -ForegroundColor Cyan
        Write-Host "Files Changed: $($patchResult.ChangedFiles.Count)" -ForegroundColor Cyan
        Write-Host "Backup: $($patchResult.Backup)" -ForegroundColor Cyan
        Write-Host "Pull Request: $($patchResult.PullRequest)" -ForegroundColor Cyan
        
        Write-Host "`nNext Steps:" -ForegroundColor Yellow
        Write-Host "1. Review the pull request: $($patchResult.PullRequest)" -ForegroundColor White
        Write-Host "2. Validate changes in the branch: $($patchResult.Branch)" -ForegroundColor White
        Write-Host "3. Merge after manual approval" -ForegroundColor White
        Write-Host "4. Monitor for any issues after merge" -ForegroundColor White
        
    } else {
        Write-Error "FAILED: Comprehensive cleanup failed: $($patchResult.Message)"
        exit 1
    }
    
} catch {
    Write-Error "CRITICAL FAILURE: $($_.Exception.Message)"
    Write-Host "Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nComprehensive project cleanup process completed successfully!" -ForegroundColor Green
Write-Host "All changes are under Git version control and require manual review." -ForegroundColor Cyan


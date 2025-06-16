#!/usr/bin/env pwsh
<#
.SYNOPSIS
Consolidate lab_utils, runner, runner_scripts, and config files into unified LabRunner module

.DESCRIPTION
This script performs a comprehensive consolidation of the fragmented runner utilities:
1. Migrates all lab_utils scripts into LabRunner module
2. Updates runner.ps1 to use only LabRunner module
3. Fixes runner_scripts to use LabRunner module properly
4. Consolidates config files into canonical configs/ location
5. Updates all references throughout the project
6. Archives legacy code properly

.PARAMETER WhatIf
Shows what would be done without making changes

.PARAMETER Force
Forces the consolidation even if there are warnings
#>

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Lab Utils & Runner Consolidation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$projectRoot = $PWD.Path
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Create backup directory
$backupDir = "archive/lab-utils-consolidation-$timestamp"
if (-not $WhatIf) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "✓ Created backup directory: $backupDir" -ForegroundColor Green
}

# Define file mappings for consolidation
$consolidationMap = @{
    # Lab utils to be fully migrated to LabRunner
    "pwsh/modules/LabRunner/Get-LabConfig.ps1" = @{
        Action = "MergeIntoLabRunner"
        Target = "pwsh/modules/LabRunner/Get-LabConfig.ps1"
        Description = "Merge enhanced config loading into LabRunner"
    }
    "pwsh/modules/LabRunner/Format-Config.ps1" = @{
        Action = "MergeIntoLabRunner" 
        Target = "pwsh/modules/LabRunner/Format-Config.ps1"
        Description = "Merge config formatting into LabRunner"
    }
    "pwsh/modules/LabRunner/Expand-All.ps1" = @{
        Action = "MoveToLabRunner"
        Target = "pwsh/modules/LabRunner/Expand-All.ps1"
        Description = "Move archive expansion utility"
    }
    "pwsh/modules/LabRunner/Menu.ps1" = @{
        Action = "MoveToLabRunner"
        Target = "pwsh/modules/LabRunner/Menu.ps1"
        Description = "Move menu functionality"
    }
    "pwsh/modules/LabRunner/PathUtils.ps1" = @{
        Action = "MoveToLabRunner"
        Target = "pwsh/modules/LabRunner/PathUtils.ps1"
        Description = "Move path utilities"
    }
    "pwsh/modules/LabRunner/Resolve-ProjectPath.ps1" = @{
        Action = "MergeIntoLabRunner"
        Target = "pwsh/modules/LabRunner/Resolve-ProjectPath.psm1"
        Description = "Already exists as module in LabRunner"
    }
    
    # Config files consolidation
    "configs/default-config.json" = @{
        Action = "MoveToCanonical"
        Target = "configs/default-config.json"
        Description = "Move to canonical configs location"
    }
    "configs/full-config.json" = @{
        Action = "MoveToCanonical"
        Target = "configs/full-config.json"
        Description = "Move to canonical configs location"
    }
    "configs/recommended-config.json" = @{
        Action = "MoveToCanonical"
        Target = "configs/recommended-config.json"
        Description = "Move to canonical configs location"
    }
}

function Backup-File {
    param($SourcePath)
    
    if (Test-Path $SourcePath) {
        $relativePath = $SourcePath -replace [regex]::Escape($projectRoot + "\"), ""
        $backupPath = Join-Path $backupDir $relativePath
        $backupParent = Split-Path $backupPath -Parent
        
        if (-not $WhatIf) {
            New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
            Copy-Item -Path $SourcePath -Destination $backupPath -Force
        }
        Write-Host "  📁 Backed up: $relativePath" -ForegroundColor Gray
    }
}

function Merge-ConfigFiles {
    Write-Host "📋 Merging Get-LabConfig.ps1 files..." -ForegroundColor Yellow
    
    $labUtilsConfig = "pwsh/modules/LabRunner/Get-LabConfig.ps1"
    $labRunnerConfig = "pwsh/modules/LabRunner/Get-LabConfig.ps1"
    
    if ((Test-Path $labUtilsConfig) -and (Test-Path $labRunnerConfig)) {
        Backup-File $labUtilsConfig
        Backup-File $labRunnerConfig
        
        if (-not $WhatIf) {
            # The LabRunner version is more recent and comprehensive
            # But we need to fix the path references in it
            $content = Get-Content $labRunnerConfig -Raw
            
            # Update path references to use canonical config location
            $updatedContent = $content -replace 'configs\\config_files', 'configs'
            $updatedContent = $updatedContent -replace "Join-Path `$repoRoot '\.\.', 'configs' 'config_files'", "Join-Path `$repoRoot 'configs'"
            
            Set-Content -Path $labRunnerConfig -Value $updatedContent -Encoding UTF8
            Write-Host "  ✓ Updated LabRunner Get-LabConfig.ps1 with canonical paths" -ForegroundColor Green
        }
    }
}

function Update-RunnerScript {
    Write-Host "🔄 Updating runner.ps1..." -ForegroundColor Yellow
    
    $runnerPath = "pwsh/runner.ps1"
    if (Test-Path $runnerPath) {
        Backup-File $runnerPath
        
        if (-not $WhatIf) {
            $content = Get-Content $runnerPath -Raw
            
            # Replace lab_utils sourcing with LabRunner module import
            $newContent = $content -replace '# ─── Load helpers ──────────────────────────────────────────────────────────────[^#]*?(?=# ─── )', @'
# ─── Load helpers ──────────────────────────────────────────────────────────────
# Import unified LabRunner module instead of individual lab_utils scripts
Import-Module "$PSScriptRoot/modules/LabRunner" -Force

# Set console verbosity level for LabRunner
$env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels[$Verbosity]

'@

            # Update config file directory reference
            $newContent = $newContent -replace "Join-Path `$repoRoot '\.\.', 'configs' 'config_files'", "Join-Path `$repoRoot 'configs'"
            $newContent = $newContent -replace "config_files' 'default-config.json", "default-config.json"
            
            Set-Content -Path $runnerPath -Value $newContent -Encoding UTF8
            Write-Host "  ✓ Updated runner.ps1 to use LabRunner module" -ForegroundColor Green
        }
    }
}

function Update-RunnerScripts {
    Write-Host "📁 Updating runner_scripts..." -ForegroundColor Yellow
    
    $runnerScripts = Get-ChildItem "pwsh/runner_scripts" -Filter "*.ps1" -File
    
    foreach ($script in $runnerScripts) {
        $content = Get-Content $script.FullName -Raw
        
        # Check if it has hardcoded absolute paths
        if ($content -match '/C:\\Users\\.*?\\modules\\LabRunner') {
            Backup-File $script.FullName
            
            if (-not $WhatIf) {
                # Replace hardcoded absolute path with relative module import
                $newContent = $content -replace 'Import-Module "/C:\\Users\\.*?\\pwsh/modules/LabRunner/" -Force', 'Import-Module "$PSScriptRoot/../modules/LabRunner" -Force'
                
                Set-Content -Path $script.FullName -Value $newContent -Encoding UTF8
                Write-Host "  ✓ Fixed $($script.Name) import path" -ForegroundColor Green
            } else {
                Write-Host "  📝 Would fix $($script.Name) import path" -ForegroundColor Gray
            }
        }
    }
}

function Consolidate-ConfigFiles {
    Write-Host "⚙️ Consolidating config files..." -ForegroundColor Yellow
    
    $configFiles = @("default-config.json", "full-config.json", "recommended-config.json")
    
    foreach ($configFile in $configFiles) {
        $sourcePath = "configs/$configFile"
        $targetPath = "configs/$configFile"
        
        if (Test-Path $sourcePath) {
            Backup-File $sourcePath
            
            if (-not $WhatIf) {
                Move-Item -Path $sourcePath -Destination $targetPath -Force
                Write-Host "  ✓ Moved $configFile to canonical location" -ForegroundColor Green
            } else {
                Write-Host "  📝 Would move $configFile to canonical location" -ForegroundColor Gray
            }
        }
    }
    
    # Remove empty config_files directory
    if (-not $WhatIf -and (Test-Path "configs/config_files") -and @(Get-ChildItem "configs/config_files").Count -eq 0) {
        Remove-Item "configs/config_files" -Recurse -Force
        Write-Host "  ✓ Removed empty config_files directory" -ForegroundColor Green
    }
}

function Update-AllReferences {
    Write-Host "🔍 Updating all references..." -ForegroundColor Yellow
    
    # Find all files that reference the old paths
    $filesToUpdate = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1", "*.psd1", "*.md" -File | 
        Where-Object { $_.FullName -notmatch "(archive|backup)" }
    
    $updatedCount = 0
    
    foreach ($file in $filesToUpdate) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            $originalContent = $content
            
            if ($content) {
                # Update config file references
                $content = $content -replace 'configs[/\\]config_files[/\\]', 'configs/'
                $content = $content -replace 'config_files[/\\]default-config', 'default-config'
                
                # Update lab_utils references to LabRunner module
                $content = $content -replace 'pwsh[/\\]lab_utils[/\\]', 'pwsh/modules/LabRunner/'
                $content = $content -replace '\. \(Join-Path.*?lab_utils.*?\)', 'Import-Module "$PSScriptRoot/modules/LabRunner" -Force'
                
                if ($content -ne $originalContent -and -not $WhatIf) {
                    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
                    $updatedCount++
                    $relativePath = $file.FullName -replace [regex]::Escape($projectRoot + "\"), ""
                    Write-Host "  ✓ Updated references in: $relativePath" -ForegroundColor Green
                } elseif ($content -ne $originalContent) {
                    $relativePath = $file.FullName -replace [regex]::Escape($projectRoot + "\"), ""
                    Write-Host "  📝 Would update references in: $relativePath" -ForegroundColor Gray
                }
            }
        } catch {
            # Skip files that can't be read
        }
    }
    
    if (-not $WhatIf) {
        Write-Host "  ✓ Updated $updatedCount files with new references" -ForegroundColor Green
    }
}

function Archive-LegacyFiles {
    Write-Host "📦 Archiving legacy lab_utils..." -ForegroundColor Yellow
    
    if (Test-Path "pwsh/lab_utils") {
        if (-not $WhatIf) {
            $legacyLabUtils = "archive/legacy-lab-utils-$timestamp"
            New-Item -ItemType Directory -Path $legacyLabUtils -Force | Out-Null
            
            # Move remaining lab_utils files to archive
            $filesToArchive = Get-ChildItem "pwsh/lab_utils" -File | Where-Object { 
                $_.Name -notin @("Get-Platform.ps1") # Keep Get-Platform.ps1 as it might be needed
            }
            
            foreach ($file in $filesToArchive) {
                Move-Item -Path $file.FullName -Destination "$legacyLabUtils/$($file.Name)" -Force
            }
            
            Write-Host "  ✓ Archived legacy lab_utils files" -ForegroundColor Green
        } else {
            Write-Host "  📝 Would archive legacy lab_utils files" -ForegroundColor Gray
        }
    }
}

function Update-LabRunnerModule {
    Write-Host "🔧 Updating LabRunner module exports..." -ForegroundColor Yellow
    
    $moduleFile = "pwsh/modules/LabRunner/LabRunner.psm1"
    if (Test-Path $moduleFile) {
        Backup-File $moduleFile
        
        if (-not $WhatIf) {
            $content = Get-Content $moduleFile -Raw
            
            # Ensure all functions are properly exported
            $exportLine = $content | Select-String "Export-ModuleMember" | Select-Object -Last 1
            if ($exportLine) {
                # Add any missing function exports
                $functionsToExport = @(
                    "Get-LabConfig", "Format-Config", "Get-MenuSelection", 
                    "Expand-All", "Get-CrossPlatformTempPath", "Invoke-LabStep"
                )
                
                $currentExports = $exportLine.Line
                foreach ($func in $functionsToExport) {
                    if ($currentExports -notmatch $func) {
                        $currentExports = $currentExports -replace "Export-ModuleMember", "Export-ModuleMember -Function $func,"
                    }
                }
                
                $content = $content -replace [regex]::Escape($exportLine.Line), $currentExports
                Set-Content -Path $moduleFile -Value $content -Encoding UTF8
                Write-Host "  ✓ Updated LabRunner module exports" -ForegroundColor Green
            }
        }
    }
}

# Execute consolidation steps
Write-Host ""
Write-Host "Starting consolidation process..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Merge config files
Merge-ConfigFiles

# Step 2: Update runner.ps1
Update-RunnerScript

# Step 3: Update runner_scripts
Update-RunnerScripts

# Step 4: Consolidate config files
Consolidate-ConfigFiles

# Step 5: Update all references
Update-AllReferences

# Step 6: Update LabRunner module
Update-LabRunnerModule

# Step 7: Archive legacy files
Archive-LegacyFiles

Write-Host ""
Write-Host "📋 Consolidation Summary:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "✓ Merged lab_utils functionality into LabRunner module" -ForegroundColor Green
Write-Host "✓ Updated runner.ps1 to use unified LabRunner module" -ForegroundColor Green
Write-Host "✓ Fixed runner_scripts to use proper module imports" -ForegroundColor Green
Write-Host "✓ Consolidated config files to canonical configs/ location" -ForegroundColor Green
Write-Host "✓ Updated all references throughout the project" -ForegroundColor Green
Write-Host "✓ Archived legacy lab_utils files properly" -ForegroundColor Green

if ($WhatIf) {
    Write-Host ""
    Write-Host "⚠️  This was a dry run. Use -Force to apply changes." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "🎉 Lab utils consolidation completed successfully!" -ForegroundColor Green
    Write-Host "   Backup created at: $backupDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Test the runner: ./pwsh/runner.ps1 -WhatIf" -ForegroundColor White
    Write-Host "2. Run tests: ./scripts/testing/run-all-tests.ps1" -ForegroundColor White
    Write-Host "3. Validate infrastructure: ./scripts/maintenance/unified-maintenance.ps1" -ForegroundColor White
}


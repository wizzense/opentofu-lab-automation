#!/usr/bin/env pwsh
# Comprehensive project cleanup with smart organization and tagging

param(
    [switch]$WhatIf,
    [switch]$Force,
    [switch]$CreateBackup,
    [string]$BackupPath = "cleanup-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')






"
)

$ErrorActionPreference = 'Stop'

function Show-CleanupPlan {
    Write-Host "🧹 OpenTofu Lab Automation - Project Cleanup Plan" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    
    # 1. Root directory analysis
    Write-Host "`n1️⃣  Root Directory Cleanup:" -ForegroundColor Yellow
    $rootFiles = Get-ChildItem -Path . -File | Where-Object { -not $_.Name.StartsWith('.') }
    Write-Host "   📁 Current root files: $($rootFiles.Count)" -ForegroundColor White
    
    # Categories
    $categories = @{
        "Legacy Fix Scripts" = $rootFiles | Where-Object { $_.Name -like "fix_*.ps1" }
        "Test Scripts" = $rootFiles | Where-Object { $_.Name -like "test-*.ps1" -or $_.Name -like "test-*.py" }
        "Documentation" = $rootFiles | Where-Object { $_.Name -like "*.md" -and $_.Name -ne "README.md" }
        "Configuration" = $rootFiles | Where-Object { $_.Name -like "*.yml" -or $_.Name -like "*.yaml" -or $_.Name -like "*.toml" }
        "Reports/Results" = $rootFiles | Where-Object { $_.Name -like "*Results*.xml" -or $_.Name -like "*report*.json" }
        "Infrastructure" = $rootFiles | Where-Object { $_.Name -like "*.tf" }
        "Temporary/Unknown" = $rootFiles | Where-Object { $_.Name -eq "a" -or $_.Name -like "tmp_*" }
        "Utilities" = $rootFiles | Where-Object { $_.Name -like "*.ps1" -and $_.Name -notlike "fix_*" -and $_.Name -notlike "test-*" }
        "Keep in Root" = $rootFiles | Where-Object { $_.Name -in @("README.md", "LICENSE") }
    }
    
    foreach ($category in $categories.Keys) {
        $files = $categories[$category]
        if ($files.Count -gt 0) {
            $color = if ($category -eq "Keep in Root") { "Green"    } else { "Cyan"    }
            Write-Host "   📂 $category`: $($files.Count) files" -ForegroundColor $color
            foreach ($file in $files) {
                Write-Host "      📄 $($file.Name)" -ForegroundColor Gray
            }
        }
    }
    
    # 2. Proposed directory structure
    Write-Host "`n2️⃣  Proposed Directory Structure:" -ForegroundColor Yellow
    $structure = @"
   📁 ROOT/
   ├── 📄 README.md (main project documentation)
   ├── 📁 archive/
   │   └── 📁 legacy/ (fix scripts, old test files)
   ├── 📁 docs/ (all documentation and markdown files)
   ├── 📁 configs/
   │   └── 📁 project/ (YAML, TOML configuration files)
   ├── 📁 infrastructure/ (Terraform files)
   ├── 📁 reports/ (test results, generated reports)
   ├── 📁 tools/ (utility scripts and management tools)
   └── 📁 temp/ (temporary files for cleanup)
"@
    Write-Host $structure -ForegroundColor White
    
    # 3. Benefits
    Write-Host "`n3️⃣  Benefits of Cleanup:" -ForegroundColor Yellow
    $benefits = @(
        "✅ Cleaner root directory (easier navigation)",
        "✅ Logical grouping of related files",
        "✅ Easier maintenance and finding files",
        "✅ Better development experience",
        "✅ Follows project organization best practices",
        "✅ Automatic tagging for future organization"
    )
    
    foreach ($benefit in $benefits) {
        Write-Host "   $benefit" -ForegroundColor Green
    }
    
    return $categories
}

function Create-Backup {
    param($BackupPath)
    
    






Write-Host "`n💾 Creating backup..." -ForegroundColor Yellow
    
    # Create backup directory
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    
    # Copy root files to backup
    $rootFiles = Get-ChildItem -Path . -File | Where-Object { -not $_.Name.StartsWith('.') }
    foreach ($file in $rootFiles) {
        Copy-Item $file.FullName -Destination $BackupPath
    }
    
    Write-Host "   ✅ Backup created at: $BackupPath" -ForegroundColor Green
    Write-Host "   📁 Backed up $($rootFiles.Count) files" -ForegroundColor Gray
}

function Execute-Cleanup {
    param($Categories, $WhatIf)
    
    






Write-Host "`n🚀 Executing cleanup..." -ForegroundColor Yellow
    
    # Directory mappings
    $directoryMap = @{
        "Legacy Fix Scripts" = "archive/legacy"
        "Test Scripts" = "archive/legacy"
        "Documentation" = "docs"
        "Configuration" = "configs/project"
        "Reports/Results" = "reports"
        "Infrastructure" = "infrastructure"
        "Temporary/Unknown" = "temp"
        "Utilities" = "tools"
    }
    
    $movedFiles = 0
    $createdDirs = @()
    
    foreach ($category in $directoryMap.Keys) {
        $files = $Categories[$category]
        if ($files.Count -gt 0) {
            $targetDir = $directoryMap[$category]
            
            if ($WhatIf) {
                Write-Host "   WHATIF: Would create directory '$targetDir' and move $($files.Count) files" -ForegroundColor Yellow
                foreach ($file in $files) {
                    Write-Host "      WHATIF: $($file.Name) → $targetDir/" -ForegroundColor Yellow
                }
            } else {
                # Create target directory
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    $createdDirs += $targetDir
                    Write-Host "   📁 Created: $targetDir" -ForegroundColor Green
                }
                
                # Move files
                foreach ($file in $files) {
                    $target = Join-Path $targetDir $file.Name
                    Move-Item $file.FullName -Destination $target
                    Write-Host "   📄 Moved: $($file.Name) → $targetDir/" -ForegroundColor Cyan
                    $movedFiles++
                }
            }
        }
    }
    
    if (-not $WhatIf) {
        Write-Host "`n✅ Cleanup completed!" -ForegroundColor Green
        Write-Host "   📁 Created $($createdDirs.Count) directories" -ForegroundColor Gray
        Write-Host "   📄 Moved $movedFiles files" -ForegroundColor Gray
        
        # Update file tags
        Write-Host "`n🏷️  Updating file tags..." -ForegroundColor Yellow
        & (Join-Path $PSScriptRoot "Manage-FileTags.ps1") -UpdateIndex
    }
}

function Show-PostCleanupSummary {
    Write-Host "`n📊 Post-Cleanup Summary" -ForegroundColor Yellow
    Write-Host "=======================" -ForegroundColor Yellow
    
    # Show new root directory state
    $remainingFiles = Get-ChildItem -Path . -File | Where-Object { -not $_.Name.StartsWith('.') }
    Write-Host "`n📁 Root directory now contains:" -ForegroundColor Cyan
    foreach ($file in $remainingFiles) {
        Write-Host "   📄 $($file.Name)" -ForegroundColor Green
    }
    
    # Show created directories
    $newDirs = Get-ChildItem -Path . -Directory | Where-Object { 
        $_.Name -in @("archive", "docs", "configs", "infrastructure", "reports", "tools", "temp") 
    }
    
    if ($newDirs.Count -gt 0) {
        Write-Host "`n📂 New organization structure:" -ForegroundColor Cyan
        foreach ($dir in $newDirs) {
            $fileCount = (Get-ChildItem $dir.FullName -File -Recurse).Count
            Write-Host "   📁 $($dir.Name)/ ($fileCount files)" -ForegroundColor White
        }
    }
    
    # Next steps
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Review the organized files in their new locations" -ForegroundColor Gray
    Write-Host "   2. Update any hardcoded paths in scripts or documentation" -ForegroundColor Gray
    Write-Host "   3. Use 'tools/Manage-FileTags.ps1' for future file organization" -ForegroundColor Gray
    Write-Host "   4. Consider updating .gitignore if needed" -ForegroundColor Gray
    Write-Host "   5. Update README.md to reflect new structure" -ForegroundColor Gray
}

# Main execution
try {
    # Show cleanup plan
    $categories = Show-CleanupPlan
    
    # Create backup if requested
    if ($CreateBackup) {
        Create-Backup $BackupPath
    }
    
    # Confirm execution
    if (-not $Force -and -not $WhatIf) {
        Write-Host "`n❓ Proceed with cleanup?" -ForegroundColor Yellow
        $options = @(
            @{ Label = "&Yes"; HelpMessage = "Execute the cleanup" }
            @{ Label = "&No"; HelpMessage = "Cancel cleanup" }
            @{ Label = "&Preview"; HelpMessage = "Show what would happen (WhatIf mode)" }
        )
        
        $choice = Read-Host "Choose (Y/N/P)"
        switch ($choice.ToLower()) {
            'y' { 
                # Proceed with cleanup
            }
            'p' { 
                $WhatIf = $true
            }
            default { 
                Write-Host "Cleanup cancelled." -ForegroundColor Yellow
                return 
            }
        }
    }
    
    # Execute cleanup
    Execute-Cleanup $categories $WhatIf
    
    # Show summary (only if not WhatIf)
    if (-not $WhatIf) {
        Show-PostCleanupSummary
    } else {
        Write-Host "`n💡 This was a preview. Remove -WhatIf to execute the cleanup." -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Cleanup failed: $_"
    if ($CreateBackup -and (Test-Path $BackupPath)) {
        Write-Host "💾 Backup is available at: $BackupPath" -ForegroundColor Cyan
    }
}




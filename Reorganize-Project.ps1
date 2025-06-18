#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
Complete project reorganization into 5 clean root folders

.DESCRIPTION
Reorganizes the entire project structure into exactly 5 root folders:
- src/     (all source code)
- tests/   (all test files) 
- docs/    (all documentation)
- configs/ (all configuration files)
- scripts/ (utility and maintenance scripts)

Removes all backup files since we're using git for version control.
#>

[CmdletBinding()]

$ErrorActionPreference = 'Stop'

Write-Host "[SYMBOL] COMPLETE PROJECT REORGANIZATION" -ForegroundColor Cyan
Write-Host "Target: 5 clean root folders only" -ForegroundColor Yellow

# Define the target 5-folder structure
$targetStructure = @{
    'src' = 'All source code (PowerShell modules, Python, OpenTofu)'
    'tests' = 'All test files (Pester, pytest, integration tests)'
    'docs' = 'All documentation (README, guides, plans)'
    'configs' = 'All configuration files (JSON, YAML, settings)'
    'scripts' = 'Utility and maintenance scripts'
}

Write-Host "`nTarget structure:" -ForegroundColor Green
$targetStructure.GetEnumerator() | ForEach-Object {
    Write-Host "  [SYMBOL] $($_.Key)/ - $($_.Value)" -ForegroundColor White
}

# Step 1: Remove all backup files and temporary directories
Write-Host "`n[SYMBOL]️  STEP 1: Removing backup files and temp directories..." -ForegroundColor Yellow

$backupPatterns = @(
    "*.backup-*",
    "*-20250*",
    "temp-*",
    "broken-*",
    "cleanup-*",
    "excess-*",
    "duplicate-*",
    "legacy-*",
    "summary-*"
)

foreach ($pattern in $backupPatterns) {
    Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -like $pattern } | 
        ForEach-Object {
            Write-Host "  Removing: $($_.Name)" -ForegroundColor Gray
            Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
}

# Remove specific backup/temp files from archive
$archiveCleanup = @(
    "archive/backups",
    "archive/broken-syntax-files-backup-20250614-120252",
    "archive/broken-workflows-20250614-104411", 
    "archive/cleanup-20250614-030528",
    "archive/cleanup-20250616-030617",
    "archive/LabRunner-removal-20250616",
    "archive/duplicate-labrunner-20250613",
    "archive/excess-installers-20250613",
    "archive/excess-readme-files-20250613",
    "archive/lab-utils-consolidation-20250616-052525",
    "archive/legacy-lab-utils-20250616-052525",
    "archive/legacy-path-fixers-20250616",
    "archive/summary-files-20250613",
    "archive/temp-patch-manager.ps1",
    "archive/temp-vscode-tasks-patch.ps1",
    "archive/*.xml",
    "archive/*.deb*",
    "archive/*.txt",
    "archive/*.py"
)

foreach ($path in $archiveCleanup) {
    if (Test-Path $path) {
        Write-Host "  Removing: $path" -ForegroundColor Gray
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Step 2: Create clean target structure
Write-Host "`n[SYMBOL] STEP 2: Creating clean target structure..." -ForegroundColor Yellow

$rootFolders = @('src', 'tests', 'docs', 'configs', 'scripts')
foreach ($folder in $rootFolders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  Created: $folder/" -ForegroundColor Green
    }
}

# Step 3: Reorganize source code
Write-Host "`nPACKAGE STEP 3: Organizing source code..." -ForegroundColor Yellow

# Move PowerShell modules
if (Test-Path "src/pwsh") {
    Write-Host "  PASS PowerShell modules already in src/pwsh/" -ForegroundColor Green
} else {
    Write-Host "  WARNING  PowerShell modules not found in expected location" -ForegroundColor Yellow
}

# Move Python code
if (Test-Path "src/python") {
    Write-Host "  PASS Python code already in src/python/" -ForegroundColor Green
} else {
    Write-Host "  WARNING  Python code not found in expected location" -ForegroundColor Yellow
}

# Move OpenTofu code
if (Test-Path "src/opentofu") {
    Write-Host "  PASS OpenTofu code already in src/opentofu/" -ForegroundColor Green
} else {
    Write-Host "  WARNING  OpenTofu code not found in expected location" -ForegroundColor Yellow
}

# Step 4: Consolidate test files
Write-Host "`n[SYMBOL] STEP 4: Consolidating test files..." -ForegroundColor Yellow

# Create test structure
$testFolders = @('tests/unit', 'tests/integration', 'tests/helpers')
foreach ($folder in $testFolders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  Created: $folder/" -ForegroundColor Green
    }
}

# Count and categorize existing test files
$testFiles = Get-ChildItem "tests/" -Filter "*.Tests.ps1" -ErrorAction SilentlyContinue
$numberedTests = $testFiles | Where-Object { $_.Name -match '^\d{4}_' }
$regularTests = $testFiles | Where-Object { $_.Name -notmatch '^\d{4}_' }

Write-Host "  Found $($testFiles.Count) test files:" -ForegroundColor White
Write-Host "    - $($numberedTests.Count) numbered tests (0000-9999)" -ForegroundColor Cyan
Write-Host "    - $($regularTests.Count) regular tests" -ForegroundColor Cyan

# Move numbered tests to integration folder
if ($numberedTests.Count -gt 0) {
    foreach ($test in $numberedTests) {
        $newPath = Join-Path "tests/integration" $test.Name
        if ($test.FullName -ne $newPath) {
            Move-Item $test.FullName $newPath -Force
            Write-Host "  Moved: $($test.Name) → integration/" -ForegroundColor Gray
        }
    }
}

# Move regular tests to unit folder
if ($regularTests.Count -gt 0) {
    foreach ($test in $regularTests) {
        $newPath = Join-Path "tests/unit" $test.Name
        if ($test.FullName -ne $newPath) {
            Move-Item $test.FullName $newPath -Force
            Write-Host "  Moved: $($test.Name) → unit/" -ForegroundColor Gray
        }
    }
}

# Step 5: Organize configuration files
Write-Host "`n[SYMBOL]️  STEP 5: Organizing configuration files..." -ForegroundColor Yellow

# Move configs from src to root configs folder
if (Test-Path "src/configs") {
    Get-ChildItem "src/configs" -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Replace((Resolve-Path "src/configs").Path, "").TrimStart('\')
        $newPath = Join-Path "configs" $relativePath
        $newDir = Split-Path $newPath -Parent
        if (-not (Test-Path $newDir)) {
            New-Item -ItemType Directory -Path $newDir -Force | Out-Null
        }
        if ($_.PSIsContainer) {
            if (-not (Test-Path $newPath)) {
                New-Item -ItemType Directory -Path $newPath -Force | Out-Null
            }
        } else {
            Copy-Item $_.FullName $newPath -Force
            Write-Host "  Moved: $relativePath → configs/" -ForegroundColor Gray
        }
    }
    Remove-Item "src/configs" -Recurse -Force
}

# Move other config files to configs folder
$configFiles = @(
    "PROJECT-MANIFEST.json",
    "opentofu-lab-automation.code-workspace",
    ".vscode",
    ".github"
)

foreach ($configPath in $configFiles) {
    if (Test-Path $configPath) {
        $targetPath = Join-Path "configs" (Split-Path $configPath -Leaf)
        if ($configPath -ne $targetPath) {
            if (Test-Path $targetPath) {
                Remove-Item $targetPath -Recurse -Force
            }
            Move-Item $configPath $targetPath -Force
            Write-Host "  Moved: $configPath → configs/" -ForegroundColor Gray
        }
    }
}

# Step 6: Organize documentation
Write-Host "`n[SYMBOL] STEP 6: Organizing documentation..." -ForegroundColor Yellow

# Move existing docs and documentation files
$docFiles = @(
    "README.md",
    "REORGANIZATION-PLAN.md",
    "VALIDATION-ONLY-CONVERSION-COMPLETE.md"
)

# Move docs files that aren't already in docs/
foreach ($docFile in $docFiles) {
    if (Test-Path $docFile) {
        $targetPath = Join-Path "docs" (Split-Path $docFile -Leaf)
        if ($docFile -ne $targetPath) {
            Move-Item $docFile $targetPath -Force
            Write-Host "  Moved: $docFile → docs/" -ForegroundColor Gray
        }
    }
}

# Move archive to docs/archive for historical reference
if (Test-Path "archive") {
    if (Test-Path "docs/archive") {
        Remove-Item "docs/archive" -Recurse -Force
    }
    Move-Item "archive" "docs/archive" -Force
    Write-Host "  Moved: archive/ → docs/archive/" -ForegroundColor Gray
}

# Step 7: Create utility scripts folder
Write-Host "`nTOOL STEP 7: Organizing utility scripts..." -ForegroundColor Yellow

# Create scripts structure
$scriptFolders = @('scripts/maintenance', 'scripts/utilities', 'scripts/testing')
foreach ($folder in $scriptFolders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  Created: $folder/" -ForegroundColor Green
    }
}

# Move standalone scripts to scripts folder
$standaloneScripts = Get-ChildItem -Filter "*.ps1" | Where-Object { 
    $_.Name -notlike "*.Tests.ps1" -and $_.Directory.Name -eq (Get-Location | Split-Path -Leaf)
}

foreach ($script in $standaloneScripts) {
    $targetPath = Join-Path "scripts/utilities" $script.Name
    Move-Item $script.FullName $targetPath -Force
    Write-Host "  Moved: $($script.Name) → scripts/utilities/" -ForegroundColor Gray
}

# Step 8: Final cleanup and validation
Write-Host "`nPASS STEP 8: Final validation..." -ForegroundColor Yellow

# Check root folder count
$rootItems = Get-ChildItem -Directory | Where-Object { $_.Name -notin @('.git') }
Write-Host "  Root folders: $($rootItems.Count)" -ForegroundColor White

if ($rootItems.Count -le 5) {
    Write-Host "  PASS Target achieved: ≤5 root folders!" -ForegroundColor Green
} else {
    Write-Host "  WARNING  Still have $($rootItems.Count) root folders" -ForegroundColor Yellow
    $rootItems | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
}

# Show final structure
Write-Host "`nREPORT FINAL PROJECT STRUCTURE:" -ForegroundColor Cyan
Get-ChildItem -Directory | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
    $itemCount = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
    Write-Host "  [SYMBOL] $($_.Name)/ ($itemCount files)" -ForegroundColor White
}

Write-Host "`nCOMPLETED PROJECT REORGANIZATION COMPLETE!" -ForegroundColor Green
Write-Host "Clean 5-folder structure ready for development" -ForegroundColor Cyan


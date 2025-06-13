# Root Directory Cleanup Script
# Organizes loose files in the project root into appropriate directories

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

Write-Host "🧹 Starting root directory cleanup..." -ForegroundColor Cyan

$rootPath = Split-Path $PSScriptRoot -Parent
if (-not $rootPath) {
    $rootPath = "."
}

# Define file categories and their target locations
$fileCategories = @{
    'Legacy README files' = @{
        Pattern = 'README-*.md'
        Target = 'archive/legacy-docs'
        Files = @('README-backup.md', 'README-new.md', 'README-old.md')
    }
    'Summary and Report Files' = @{
        Pattern = '*-SUMMARY*.md', '*-REPORT*.md', '*ACCOMPLISHED*.md'
        Target = 'docs/reports/project-summaries'
        Files = @(
            'AUTO-FIX-INTEGRATION-SUMMARY.md',
            'BRANCH-SOLUTION-SUMMARY.md', 
            'CLEANUP-SUMMARY.md',
            'CODEFIXER-IMPROVEMENTS-SUMMARY.md',
            'DEPLOYMENT-WRAPPER-SUMMARY.md',
            'INTEGRATION-SUMMARY.md',
            'MISSION-ACCOMPLISHED-FINAL.md',
            'MISSION-ACCOMPLISHED-INTEGRATION.md',
            'PROJECT-ORGANIZATION-COMPLETE.md',
            'TEST-ISSUES-SUMMARY-REPORT.md',
            'WORKFLOW-CONSOLIDATION-SUMMARY.md'
        )
    }
    'Testing and Validation Docs' = @{
        Pattern = '*TEST*.md', '*TESTING*.md'
        Target = 'docs/testing'
        Files = @(
            'INLINE-WINDOWS-TEST.md',
            'TESTING-DEPLOYMENT-WRAPPER.md', 
            'TESTING.md',
            'WINDOWS-TESTING-GUIDE.md'
        )
    }
    'Legacy Fix Scripts' = @{
        Pattern = 'fix-*.ps1', '*fix*.ps1'
        Target = 'archive/legacy-scripts'
        Files = @(
            'auto-fix.ps1',
            'cleanup-root-fixes.ps1',
            'comprehensive-fix-and-test.ps1',
            'fix-all-syntax-errors.ps1',
            'fix-deploy-unicode.ps1',
            'fix-here-strings-v2.ps1',
            'fix-here-strings.ps1',
            'fix-import-issues.ps1',
            'fix-psscriptanalyzer-using-project-patterns.ps1',
            'fix-psscriptanalyzer.ps1',
            'simple-import-cleanup.ps1'
        )
    }
    # REMOVED: Deploy and Launch Scripts - these stay in root for ease of use
    # Intentionally keeping in root: deploy.*, launch-gui.*, gui.py, quick-download.sh
    # REMOVED: GUI and Utilities - gui.py stays in root for ease of use
    'Legacy Test Scripts' = @{
        Pattern = 'test-*.ps1', '*test*.ps1'
        Target = 'archive/legacy-scripts'
        Files = @(
            'test-powershell-quickstart.ps1',
            'windows-quick-test.ps1'
        )
    }
    # Configuration and Reports - keep important operational files
    'Project Configuration' = @{
        Pattern = '*.yaml', '*.json'
        Target = 'configs/project'
        Files = @('path-index.yaml')  # workflow-dashboard-report.json might be actively used
    }
}

function Move-FilesToTarget {
    param(
        [string[]]$Files,
        [string]$TargetDir,
        [string]$Category
    )
    
    $movedCount = 0
    $targetPath = Join-Path $rootPath $TargetDir
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path $targetPath) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        Write-Host "  📁 Created directory: $TargetDir" -ForegroundColor Green
    }
    
    foreach ($file in $Files) {
        $sourcePath = Join-Path $rootPath $file
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $targetPath $file
            
            if ($DryRun) {
                Write-Host "  🔍 Would move: $file → $TargetDir/" -ForegroundColor Yellow
            } else {
                try {
                    Move-Item -Path $sourcePath -Destination $destPath -Force
                    Write-Host "  ✅ Moved: $file → $TargetDir/" -ForegroundColor Green
                    $movedCount++
                } catch {
                    Write-Host "  ❌ Failed to move $file`: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
    
    if ($movedCount -gt 0 -or $DryRun) {
        Write-Host "📦 $Category`: $movedCount files moved" -ForegroundColor Cyan
    }
}

# Main cleanup process
Write-Host "🔍 Analyzing files to move..." -ForegroundColor Yellow

$totalMoved = 0
foreach ($category in $fileCategories.GetEnumerator()) {
    $categoryName = $category.Key
    $config = $category.Value
    
    Write-Host "`n📂 Processing: $categoryName" -ForegroundColor Magenta
    Move-FilesToTarget -Files $config.Files -TargetDir $config.Target -Category $categoryName
}

# Clean up empty __pycache__ directories
if (Test-Path "__pycache__") {
    if ($DryRun) {
        Write-Host "`n🔍 Would remove: __pycache__ directory" -ForegroundColor Yellow
    } else {
        Remove-Item "__pycache__" -Recurse -Force
        Write-Host "`n🗑️ Removed: __pycache__ directory" -ForegroundColor Green
    }
}

# Update .gitignore to prevent future clutter
$gitignoreAdditions = @(
    '',
    '# Prevent root directory clutter',
    '*-SUMMARY*.md',
    '*-REPORT*.md', 
    'fix-*.ps1',
    'test-*.ps1',
    'deploy.*',
    'launch-*.*',
    '*.temp',
    '*.tmp',
    '__pycache__/',
    '*.pyc'
)

$gitignorePath = Join-Path $rootPath '.gitignore'
if (Test-Path $gitignorePath) {
    $existingContent = Get-Content $gitignorePath -Raw
    $hasClutterSection = $existingContent -match 'Prevent root directory clutter'
    
    if (-not $hasClutterSection -and -not $DryRun) {
        Add-Content $gitignorePath ($gitignoreAdditions -join "`n")
        Write-Host "`n📝 Updated .gitignore to prevent future clutter" -ForegroundColor Green
    }
}

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN COMPLETE - No files were actually moved" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to perform the cleanup" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Root directory cleanup completed!" -ForegroundColor Green
    Write-Host "📁 Files organized into appropriate directories" -ForegroundColor Green
    Write-Host "🔄 Run 'git status' to review changes before committing" -ForegroundColor Cyan
}

#!/usr/bin/env pwsh
# Migrate from multiple deploy/launcher scripts to unified launcher

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$archiveDir = "archive/legacy-launchers-$timestamp"

Write-Host " Migrating to Unified Launcher System" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Create archive directory
New-Item -ItemType Directory -Path $archiveDir -Force | Out-NullWrite-Host "PASS Created archive directory: $archiveDir" -ForegroundColor Green

# List of files to archive
$filesToArchive = @(
 "deploy.bat",
 "deploy.ps1", 
 "deploy.sh",
 "launch-gui.bat",
 "launch-gui.ps1",
 "launch-gui.sh"
)

$archivedCount = 0
foreach ($file in $filesToArchive) {
 if (Test-Path $file) {
 Move-Item $file $archiveDir -Force
 Write-Host " Archived: $file" -ForegroundColor Yellow
 $archivedCount++
 }
}

Write-Host ""
Write-Host " Migration Summary:" -ForegroundColor Blue
Write-Host " Archived files: $archivedCount" -ForegroundColor White
Write-Host " New unified launcher: launcher.py" -ForegroundColor Green
Write-Host " Platform wrappers: start.sh, start.bat, start.ps1" -ForegroundColor Green

Write-Host ""
Write-Host " New Usage:" -ForegroundColor Cyan
Write-Host " Interactive menu: ./launcher.py" -ForegroundColor White
Write-Host " Deploy environment: ./launcher.py deploy" -ForegroundColor White 
Write-Host " Launch GUI: ./launcher.py gui" -ForegroundColor White
Write-Host " Health check: ./launcher.py health" -ForegroundColor White
Write-Host ""
Write-Host " Platform shortcuts:" -ForegroundColor Blue
Write-Host " Windows: start.bat" -ForegroundColor White
Write-Host " Unix: ./start.sh" -ForegroundColor White 
Write-Host " PowerShell: ./start.ps1" -ForegroundColor White

Write-Host ""
Write-Host "PASS Migration completed successfully!" -ForegroundColor Green


#!/usr/bin/env pwsh
# Clean up root directory - move reports and temporary files to appropriate locations

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "� Cleaning up root directory..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Create cleanup directories
$reportsArchive = "reports/archive-$timestamp"
$tempArchive = "archive/temp-files-$timestamp"

New-Item -ItemType Directory -Path $reportsArchive -Force | Out-Null
New-Item -ItemType Directory -Path $tempArchive -Force | Out-Null# Files to move to reports archive
$reportFiles = @(
 "AGENTS.md",
 "AUTOMATED-EXECUTION-CONFIRMED.md", 
 "CROSS-PLATFORM-COMPLETE.md",
 "FINAL-COMMIT-READY.md",
 "MERGE-CONFLICT-CRISIS-ANALYSIS.md",
 "MIGRATION-REPORT.md", 
 "MISSION-ACCOMPLISHED-FINAL.md",
 "SIMPLIFIED-DEPLOYMENT-SUMMARY.md",
 "YAML-DEPLOY-CONSOLIDATION-SUMMARY.md",
 "workflow-dashboard-report.json"
)

# Files to move to temp archive 
$tempFiles = @(
 "bootstrap.py",
 "launch-gui.py", 
 "quick-start.py",
 "quick-start.sh",
 "README-new-clean.md",
 "README-old-corrupted.md"
)

# Move report files
$movedReports = 0
foreach ($file in $reportFiles) {
 if (Test-Path $file) {
 Move-Item $file $reportsArchive -Force
 Write-Host " Moved report: $file" -ForegroundColor Yellow
 $movedReports++
 }
}

# Move temp files
$movedTemp = 0
foreach ($file in $tempFiles) {
 if (Test-Path $file) {
 Move-Item $file $tempArchive -Force
 Write-Host " Archived temp file: $file" -ForegroundColor Gray
 $movedTemp++
 }
}

Write-Host ""
Write-Host " Cleanup Summary:" -ForegroundColor Blue
Write-Host " Reports moved: $movedReports" -ForegroundColor White
Write-Host " Temp files archived: $movedTemp" -ForegroundColor White
Write-Host " Reports location: $reportsArchive" -ForegroundColor Green
Write-Host " Archive location: $tempArchive" -ForegroundColor Green

Write-Host ""
Write-Host "� Clean root directory now contains:" -ForegroundColor Green
Get-ChildItem -Path "." -File | Where-Object{ $_.Name -notmatch '\.(logtmp)$' } | Select-ObjectName  Format-Table -AutoSize

Write-Host ""
Write-Host "PASS Root directory cleanup completed!" -ForegroundColor Green



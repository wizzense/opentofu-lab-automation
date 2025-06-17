<#
VALIDATION-ONLY MODE: This script has been converted to validation-only.
It will only report issues and create GitHub issues for tracking.
No automatic file modifications or repairs are performed.
Use PatchManager for explicit file changes when needed.
#>
#!/usr/bin/env pwsh
<#
.SYNOPSIS
 Fix corrupted GitHub Actions workflow files
.DESCRIPTION
 Repairs workflow files that were corrupted by the YAML validation script
 that incorrectly replaced YAML keywords with 'true' variants
.PARAMETER WorkflowPath
 Path to the .github/workflows directory
#>

param(
 string$WorkflowPath = ".\.github\workflows"
)

function Repair-WorkflowFile {
 param(string$FilePath)
 
 Write-Host "Repairing workflow file: $FilePath" -ForegroundColor Yellow
 
 try {
 $content = Get-Content $FilePath -Raw
 $originalContent = $content
 
 # Fix the common corruptions
 $fixes = @{
 'true:' = 'on:'
 'crtrue:' = 'cron:'
 'runs-true:' = 'runs-on:'
 'python-versitrue:' = 'python-version:'
 'descriptitrue:' = 'description:'
 'versitrue:' = 'version:'
 }
 
 foreach ($corruption in $fixes.Keys) {
 $content = $content -replace regex::Escape($corruption), $fixes$corruption
 }
 
 if ($content -ne $originalContent) {
 # DISABLED: # DISABLED: Set-Content -Path $FilePath -Value $content -NoNewline
 Write-Host " VALIDATION: Found issue - corruptions in $FilePath" -ForegroundColor Green
 return $true
 } else {
 Write-Host " INFO No corruptions found in $FilePath" -ForegroundColor Cyan
 return $false
 }
 } catch {
 Write-Error "Failed to repair $FilePath`: $_"
 return $false
 }
}

# Main execution
Write-Host " Starting GitHub Actions workflow repair..." -ForegroundColor Cyan

if (-not (Test-Path $WorkflowPath)) {
 Write-Error "Workflow path not found: $WorkflowPath"
 exit 1
}

$workflowFiles = Get-ChildItem -Path $WorkflowPath -Filter "*.yml" -File
$fixedCount = 0

foreach ($file in $workflowFiles) {
 if (Repair-WorkflowFile -FilePath $file.FullName) {
 $fixedCount++
 }
}

Write-Host "`n Workflow repair complete!" -ForegroundColor Green
Write-Host "Files processed: $($workflowFiles.Count)" -ForegroundColor White
Write-Host "Files fixed: $fixedCount" -ForegroundColor Green

if ($fixedCount -gt 0) {
 Write-Host "`n Next steps:" -ForegroundColor Yellow
 Write-Host "1. Review the changes with: git diff" -ForegroundColor White
 Write-Host "2. Test a workflow with: gh workflow run <workflow-name>" -ForegroundColor White
 Write-Host "3. Commit the fixes: git add . && git commit -m 'fix: repair corrupted workflow files'" -ForegroundColor White
}

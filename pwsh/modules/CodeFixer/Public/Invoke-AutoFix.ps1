<#
.SYNOPSIS
Automatically fixes common PowerShell syntax errors

.DESCRIPTION
This function analyzes PowerShell files for common syntax errors and automatically
applies fixes where possible. It creates backups before making changes.

.PARAMETER Path
Root path containing code to fix (default: current directory)

.PARAMETER WhatIf
Show what changes would be made without applying them

.PARAMETER PassThru
Return the list of files that were modified

.EXAMPLE
Invoke-AutoFix

.EXAMPLE
Invoke-AutoFix -Path "/workspaces/opentofu-lab-automation" -WhatIf
#>
function Invoke-AutoFix {
 CmdletBinding(SupportsShouldProcess)
 param(
 string$Path = ".",
 switch$PassThru
 )
 
 






$ErrorActionPreference = "Stop"
 
 Write-Host "Starting automatic PowerShell syntax fixing..." -ForegroundColor Cyan
 
 # Resolve path
 $fullPath = Resolve-Path $Path -ErrorAction Stop
 
 # Track all fixed files
 $fixedFiles = @()
 
 # Find all PowerShell files
 $powerShellFiles = Get-ChildItem -Path $fullPath -Recurse -Include "*.ps1", "*.psm1", "*.psd1" -File
 
 # Filter out legacy/archive files
 $ignorePaths = @("archive", "backups", "legacy", "historical-fixes", "deprecated-")
 $powerShellFiles = $powerShellFiles  Where-Object {
 $filePath = $_.FullName
 $shouldIgnore = $false
 foreach ($ignorePath in $ignorePaths) {
 if ($filePath -like "*$ignorePath*") {
 $shouldIgnore = $true
 break
 }
 }
 return -not $shouldIgnore
 }
 
 if ($powerShellFiles.Count -eq 0) {
 Write-Host "No PowerShell files found in $fullPath (after filtering legacy files)" -ForegroundColor Yellow
 return
 }
 
 Write-Host "Found $($powerShellFiles.Count) PowerShell files to analyze" -ForegroundColor Green
 
 foreach ($file in $powerShellFiles) {
 Write-Host "`nAnalyzing: $($file.Name)" -ForegroundColor Gray
 
 try {
 # Parse the file to check for syntax errors
 $tokens = $null
 $parseErrors = $null
 $content = Get-Content -Path $file.FullName -Raw
 $ast = System.Management.Automation.Language.Parser::ParseInput(
 $content, 
 $file.FullName,
 ref$tokens, 
 ref$parseErrors
 )
 
 if ($parseErrors.Count -eq 0) {
 Write-Host "  No syntax errors found" -ForegroundColor Green
 continue
 }
 
 Write-Host " Found $($parseErrors.Count) syntax error(s)" -ForegroundColor Yellow
 
 # Create backup before fixing
 $backupPath = "$($file.FullName).backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
 if ($PSCmdlet.ShouldProcess($file.FullName, "Create backup and fix syntax errors")) {
 Copy-Item -Path $file.FullName -Destination $backupPath
 Write-Host " Created backup: $(System.IO.Path::GetFileName($backupPath))" -ForegroundColor Cyan
 
 # Apply fixes
 $fixedContent = $content
 $hasChanges = $false
 
 # Sort errors by line number (descending) to fix from bottom up
 # This prevents line number shifts from affecting later fixes
 $sortedErrors = $parseErrors  Sort-Object { $_.Extent.StartLineNumber } -Descending
 
 foreach ($error in $sortedErrors) {
 Write-Host " Fixing: $($error.Message)" -ForegroundColor Yellow
 
 $fixResult = Repair-SyntaxError -Content $fixedContent -Error $error
 if ($fixResult.Fixed) {
 $fixedContent = $fixResult.Content
 $hasChanges = $true
 Write-Host " PASS Applied fix: $($fixResult.Description)" -ForegroundColor Green
 } else {
 Write-Host " WARN Could not auto-fix: $($error.Message)" -ForegroundColor Yellow
 }
 }
 
 # Save the fixed content if changes were made
 if ($hasChanges) {
 $fixedContent  Set-Content -Path $file.FullName -Encoding UTF8
 $fixedFiles += $file.FullName
 Write-Host " PASS Fixed and saved $($file.Name)" -ForegroundColor Green
 
 # Verify the fix worked
 $verifyErrors = $null
 try {
 System.Management.Automation.Language.Parser::ParseFile(
 $file.FullName, 
 ref$null, 
 ref$verifyErrors
 )
 if ($verifyErrors.Count -eq 0) {
 Write-Host " PASS Verification passed - no syntax errors remain" -ForegroundColor Green
 } else {
 Write-Host " WARN $($verifyErrors.Count) syntax error(s) remain" -ForegroundColor Yellow
 }
 } catch {
 Write-Host " FAIL Verification failed: $($_.Exception.Message)" -ForegroundColor Red
 }
 } else {
 Write-Host " WARN No automatic fixes could be applied" -ForegroundColor Yellow
 # Remove backup if no changes were made
 Remove-Item -Path $backupPath -Force
 }
 }
 
 } catch {
 Write-Host " FAIL Error processing file: $($_.Exception.Message)" -ForegroundColor Red
 }
 }
 
 # Summary
 Write-Host "`n===================== FIX SUMMARY =====================" -ForegroundColor Cyan
 Write-Host "Files Processed: $($powerShellFiles.Count)" -ForegroundColor White
 Write-Host "Files Fixed: $($fixedFiles.Count)" -ForegroundColor $$(if (fixedFiles.Count -gt 0) { "Green" } else { "White" })
 Write-Host "=======================================================" -ForegroundColor Cyan
 
 if ($fixedFiles.Count -gt 0) {
 Write-Host "`n� Fixed Files:" -ForegroundColor Green
 foreach ($file in $fixedFiles) {
 Write-Host " • $(System.IO.Path::GetFileName($file))" -ForegroundColor Green
 }
 }
 
 if ($PassThru) {
 return $fixedFiles
 }
}




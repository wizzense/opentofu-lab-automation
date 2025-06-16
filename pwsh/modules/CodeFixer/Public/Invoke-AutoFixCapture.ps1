# Auto-Fix Capture System
# Learns from manual fixes and applies them automatically

function Invoke-AutoFixCapture {
 <#
 .SYNOPSIS
 Automatically capture and apply common fixes based on learned patterns
 
 .DESCRIPTION
 This function analyzes the codebase for common issues that we've manually fixed
 and applies the same fixes automatically to prevent regression
 #>
 
 CmdletBinding()
 param(
 Parameter()
 string$Path = ".",
 
 Parameter()
 switch$WhatIf,
 
 Parameter()
 switch$Verbose
 )
 
 Write-Host " Auto-Fix Capture System" -ForegroundColor Cyan
 Write-Host "=========================" -ForegroundColor Cyan
 
 $fixes = @()
 $totalFiles = 0
 $fixedFiles = 0
 
 # Define fix patterns based on our manual fixes
 $fixPatterns = @{
 'BrokenParameterBlocks' = @{
 Pattern = '\Parameter\(Mandatory=\$true\)\s*#.*?if.*?PSScriptAnalyzer.*?\\string\'
 Replacement = 'Parameter(Mandatory=$true)`n string'
 Description = 'Fix broken parameter blocks with embedded PSScriptAnalyzer imports'
 }
 
 'OrphanedPSScriptAnalyzer' = @{
 Pattern = '# Auto-added import for PSScriptAnalyzer\s*\n.*?PSScriptAnalyzer.*?\n'
 Replacement = ''
 Description = 'Remove orphaned PSScriptAnalyzer import blocks'
 }
 
 'BrokenValidateSet' = @{
 Pattern = '\ValidateSet\(^\+\)\s*\n\s*\n\s*\\s*\string\'
 Replacement = 'ValidateSet($1)`n string'
 Description = 'Fix broken ValidateSet parameter attributes'
 }
 
 'ModuleImportPaths' = @{
 Pattern = 'Import-Module.*?lab_utils'
 Replacement = 'Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -Force'
 Description = 'Update module import paths to new LabRunner location'
 }
 
 'TestHelpersPath' = @{
 Pattern = '\$LabUtilsPath = Join-Path \$PSScriptRoot.*?lab_utils'
 Replacement = '$LabRunnerPath = Join-Path $PSScriptRoot "../../pwsh/modules/LabRunner"'
 Description = 'Update TestHelpers path references'
 }
 
 'UnicodeCharacters' = @{
 Pattern = '��FAILWARNPASS'
 Replacement = ''
 Description = 'Remove Unicode characters that cause Windows encoding issues'
 }
 
 'ErrorsCommand' = @{
 Pattern = '\$\s*errors\s*\'
 Replacement = '$errorOutput '
 Description = 'Fix undefined errors command references'
 }
 
 'MissingClosingBrace' = @{
 Pattern = 'function\s+\w+\s*\{\s*param\(^}+\)\s*(?!\})'
 Replacement = '$1}'
 Description = 'Add missing closing braces for function parameter blocks'
 }
 }
 
 # Get all PowerShell files
 $psFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1", "*.psd1"  Where-Object { 
 $_.FullName -notmatch '\\(archivebackupsnode_modules)\\' 
 }
 
 Write-Host " Scanning $($psFiles.Count) PowerShell files for fixable issues..." -ForegroundColor Blue
 
 foreach ($file in $psFiles) {
 $totalFiles++
 $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
 if (-not $content) { continue }
 
 $originalContent = $content
 $fileFixed = $false
 $fileFixes = @()
 
 foreach ($fixName in $fixPatterns.Keys) {
 $fix = $fixPatterns$fixName
 
 if ($content -match $fix.Pattern) {
 if ($fix.Pattern -eq 'UnicodeCharacters') {
 # Special handling for Unicode replacement
 # Correct duplicate keys in Unicode replacement
 $unicodeChars = @{
 '>>' = 'Info:'
 '�' = 'Path:'
 'Package:' = 'Directory:'
 'Volume:' = 'Critical:'
 'FAIL' = 'ERROR:'
 'WARN' = 'WARNING:'
 'PASS' = 'OK:'
 }
 
 foreach ($unicode in $unicodeChars.Keys) {
 if ($content.Contains($unicode)) {
 $content = $content.Replace($unicode, $unicodeChars$unicode)
 $fileFixes += "Replaced Unicode: $unicode -> $($unicodeChars$unicode)"
 $fileFixed = $true
 }
 }
 } else {
 # Standard regex replacement
 $newContent = $content -replace $fix.Pattern, $fix.Replacement
 if ($newContent -ne $content) {
 $content = $newContent
 $fileFixes += $fix.Description
 $fileFixed = $true
 }
 }
 }
 }
 
 # Apply fixes if any were found
 if ($fileFixed) {
 if ($WhatIf) {
 Write-Host " WHAT-IF Would fix: $($file.Name)" -ForegroundColor Yellow
 foreach ($fix in $fileFixes) {
 Write-Host " • $fix" -ForegroundColor Gray
 }
 } else {
 # Create backup
 $backupPath = "$($file.FullName).backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
 Copy-Item $file.FullName $backupPath -ErrorAction SilentlyContinue
 
 # Apply fixes
 Set-Content -Path $file.FullName -Value $content -Encoding UTF8
 Write-Host " PASS Fixed: $($file.Name)" -ForegroundColor Green
 
 if ($Verbose) {
 foreach ($fix in $fileFixes) {
 Write-Host " • $fix" -ForegroundColor Gray
 }
 }
 
 $fixes += @{
 File = $file.Name
 Path = $file.FullName
 Fixes = $fileFixes
 BackupPath = $backupPath
 }
 }
 
 $fixedFiles++
 }
 }
 
 # Summary
 Write-Host "`n Auto-Fix Summary" -ForegroundColor Cyan
 Write-Host "===================" -ForegroundColor Cyan
 Write-Host "� Files Scanned: $totalFiles" -ForegroundColor Blue
 Write-Host " Files Fixed: $fixedFiles" -ForegroundColor Green
 Write-Host "� Backups Created: $fixedFiles" -ForegroundColor Yellow
 
 if ($WhatIf) {
 Write-Host "`nWARN WhatIf Mode: No changes were applied" -ForegroundColor Yellow
 Write-Host "Run without -WhatIf to apply fixes" -ForegroundColor Gray
 }
 
 return $fixes
}

function Export-FixPatterns {
 <#
 .SYNOPSIS
 Export learned fix patterns to a JSON file for sharing and version control
 #>
 
 param(
 Parameter()
 string$OutputPath = "./tools/auto-fix-patterns.json"
 )
 
 $patterns = @{
 Version = "1.0"
 LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
 Description = "Auto-fix patterns learned from manual fixes"
 Patterns = @{
 BrokenParameterBlocks = @{
 Pattern = '\Parameter\(Mandatory=\$true\)\s*#.*?if.*?PSScriptAnalyzer.*?\\string\'
 Replacement = 'Parameter(Mandatory=$true)`n string'
 Description = 'Fix broken parameter blocks with embedded PSScriptAnalyzer imports'
 Category = 'Syntax'
 Severity = 'High'
 }
 OrphanedPSScriptAnalyzer = @{
 Pattern = '# Auto-added import for PSScriptAnalyzer\s*\n.*?PSScriptAnalyzer.*?\n'
 Replacement = ''
 Description = 'Remove orphaned PSScriptAnalyzer import blocks'
 Category = 'Cleanup'
 Severity = 'Medium'
 }
 ModuleImportPaths = @{
 Pattern = 'Import-Module.*?lab_utils'
 Replacement = 'Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -Force'
 Description = 'Update module import paths to new LabRunner location'
 Category = 'Refactoring'
 Severity = 'High'
 }
 UnicodeCharacters = @{
 Pattern = '��FAILWARNPASS'
 Replacement = 'TEXT_EQUIVALENT'
 Description = 'Remove Unicode characters that cause Windows encoding issues'
 Category = 'Compatibility'
 Severity = 'Medium'
 }
 }
 }
 
 patterns | ConvertTo-Json -Depth 5  Set-Content -Path $OutputPath -Encoding UTF8
 Write-Host "PASS Fix patterns exported to: $OutputPath" -ForegroundColor Green
}

function Import-FixPatterns {
 <#
 .SYNOPSIS
 Import fix patterns from a JSON file
 #>
 
 param(
 Parameter()
 string$InputPath = "./tools/auto-fix-patterns.json"
 )
 
 if (Test-Path $InputPath) {
 $patterns = Get-Content $InputPath -Raw  ConvertFrom-Json
 Write-Host "PASS Imported fix patterns from: $InputPath" -ForegroundColor Green
 Write-Host " Version: $($patterns.Version)" -ForegroundColor Gray
 Write-Host " Last Updated: $($patterns.LastUpdated)" -ForegroundColor Gray
 Write-Host " Patterns Count: $($patterns.Patterns.PSObject.Properties.Count)" -ForegroundColor Gray
 return $patterns
 } else {
 Write-Warning "Fix patterns file not found: $InputPath"
 return $null
 }
}

Export-ModuleMember -Function Invoke-AutoFixCapture, Export-FixPatterns, Import-FixPatterns














<#
.SYNOPSIS
Automatically fixes common syntax errors in PowerShell test files

.DESCRIPTION
Analyzes PowerShell test files for common syntax errors and automatically fixes them.
Specifically targets issues with:
- Ternary-style "if" expressions
- -Skip parameter without parentheses
- Incorrect indentation for It blocks
- Missing closing quotes on It statements

.PARAMETER Path
Path to a file or directory containing test files to fix

.PARAMETER Filter
Pattern to filter files when Path is a directory (default: "*.Tests.ps1")

.PARAMETER WhatIf
Show what changes would be made without applying them

.PARAMETER PassThru
Return the list of files that were modified

.EXAMPLE
Invoke-TestSyntaxFix -Path "tests/"

.EXAMPLE
Invoke-TestSyntaxFix -Path "tests/0000_Cleanup-Files.Tests.ps1" -WhatIf
#>
function Invoke-TestSyntaxFix {
 [CmdletBinding(SupportsShouldProcess)]
 param(
 [Parameter(Mandatory=$true, Position=0)






]
 [string]$Path,
 
 [Parameter(Mandatory=$false)]
 [string]$Filter = "*.Tests.ps1",
 
 [switch]$PassThru
 )
 
 $ErrorActionPreference = "Stop"
 
 Write-Verbose "Starting test syntax fix process for $Path"
 
 # Get files to process
 $filesToProcess = @()
 if (Test-Path $Path -PathType Container) {
 $filesToProcess = Get-ChildItem -Path $Path -Filter $Filter -Recurse
 Write-Verbose "Found $($filesToProcess.Count) test files in directory"
 } else {
 if (Test-Path $Path -PathType Leaf) {
 $filesToProcess = @(Get-Item -Path $Path)
 Write-Verbose "Processing single file: $Path"
 } else {
 Write-Error "Path not found: $Path"
 return
 }
 }
 
 $fixedFiles = @()
 
 foreach ($file in $filesToProcess) {
 Write-Verbose "Processing: $($file.FullName)"
 
 # Read content
 $content = Get-Content $file.FullName -Raw
 $originalContent = $content
 $modified = $false
 
 # Fix 1: Fix broken ternary-style "if" expressions
 $pattern1 = '\(if \(\$([^)]+)\) \{ ([^}]+) \} else \{ ([^}]+) \}\)'
 $replacement1 = '$$(if (1) { $2 } else { $3 })'
 if ($content -match $pattern1) {
 Write-Verbose " Fixing ternary-style if expressions"
 $content = $content -replace $pattern1, $replacement1
 $modified = $true
 }
 
 # Fix 2: Fix -Skip parameter without parentheses
 $pattern2 = '-Skip:\$([a-zA-Z0-9_]+)(?!\))'
 $replacement2 = '-Skip:($$$1)'
 if ($content -match $pattern2) {
 Write-Verbose " Fixing -Skip parameter without parentheses"
 $content = $content -replace $pattern2, $replacement2
 $modified = $true
 }
 
 # Fix 3: Fix incorrect indentation for It blocks
 $pattern3 = '(\s+)}(\r?\n)\s+It '
 $replacement3 = '$1}$2 It '
 if ($content -match $pattern3) {
 Write-Verbose " Fixing indentation for It blocks"
 $content = $content -replace $pattern3, $replacement3
 $modified = $true
 }
 
 # Fix 4: Fix missing closing quotes on It statements
 $pattern4 = "It 'should ([^']+)' -Skip:([^{]+) \{"
 $replacement4 = "It 'should $1' -Skip:$2 {"
 if ($content -match $pattern4) {
 Write-Verbose " Fixing missing closing quotes on It statements"
 $content = $content -replace $pattern4, $replacement4
 $modified = $true
 }
 
 # Apply changes if needed
 if ($modified) {
 if ($PSCmdlet.ShouldProcess($file.FullName, "Apply syntax fixes")) {
 Set-Content -Path $file.FullName -Value $content -NoNewline
 Write-Verbose " [PASS] Fixed: $($file.Name)"
 $fixedFiles += $file.FullName
 } else {
 Write-Verbose " Would fix: $($file.Name) (WhatIf mode)"
 }
 } else {
 Write-Verbose " No issues found in: $($file.Name)"
 }
 }
 
 Write-Verbose "Completed syntax fixes. Fixed files: $($fixedFiles.Count)"
 
 if ($PassThru) {
 return $fixedFiles
 }
}




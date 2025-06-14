<#
.SYNOPSIS
Fixes the order of Import-Module and Param blocks in PowerShell scripts

.DESCRIPTION
This function ensures that the Param block comes before the Import-Module
statement in PowerShell runner scripts, which is the correct order for
proper parameter binding.

.PARAMETER Path
Path to a file or directory containing scripts to fix

.PARAMETER Filter
Pattern to filter files when Path is a directory (default: "*.ps1")

.PARAMETER WhatIf
Show what changes would be made without applying them

.PARAMETER PassThru
Return the list of files that were modified

.EXAMPLE
Invoke-ScriptOrderFix -Path "pwsh/runner_scripts/"

.EXAMPLE
Invoke-ScriptOrderFix -Path "pwsh/runner_scripts/0001_Reset-Git.ps1" -WhatIf
#>
function Invoke-ScriptOrderFix {
 [CmdletBinding(SupportsShouldProcess)]
 param(
 [Parameter(Mandatory=$true, Position=0)






]
 [string]$Path,
 
 [Parameter(Mandatory=$false)]
 [string]$Filter = "*.ps1",
 
 [switch]$PassThru
 )
 
 $ErrorActionPreference = "Stop"
 
 Write-Verbose "Starting script order fix process for $Path"
 
 # Get files to process
 $filesToProcess = @()
 if (Test-Path $Path -PathType Container) {
 $filesToProcess = Get-ChildItem -Path $Path -Filter $Filter -Recurse
 Write-Verbose "Found $($filesToProcess.Count) script files in directory"
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
 # Skip test files
 if ($file.Name -match '\.Tests\.ps1$') {
 Write-Verbose "Skipping test file: $($file.Name)"
 continue
 }
 
 Write-Verbose "Processing: $($file.FullName)"
 
 # Read content
 $lines = Get-Content $file.FullName
 
 # Check if this script has the problematic pattern (Import-Module before Param)
 if ($lines.Count -ge 2 -and 
 $lines[0] -match "^Import-Module.*" -and 
 $lines[1] -match "^Param\(") {
 
 Write-Verbose " Found Import-Module before Param block in $($file.Name)"
 
 # Extract the Import-Module line and Param block
 $importLine = $lines[0]
 
 # Find the end of the Param block
 $paramStart = 1
 $paramEnd = $paramStart
 $parenCount = 0
 $inParam = $false
 
 for ($i = $paramStart; $i -lt $lines.Count; $i++) {
 $line = $lines[$i]
 if ($line -match "^Param\(") {
 $inParam = $true
 }
 if ($inParam) {
 $parenCount += ($line.Split('(').Count - 1)
 $parenCount -= ($line.Split(')').Count - 1)
 if ($parenCount -eq 0) {
 $paramEnd = $i
 break
 }
 }
 }
 
 # Extract the Param block
 $paramBlock = $lines[$paramStart..$paramEnd] -join "`n"
 
 # Reconstruct the content with Param block first
 $newContent = @()
 $newContent += $paramBlock
 $newContent += $importLine
 $newContent += $lines[($paramEnd + 1)..($lines.Count - 1)]
 
 # Apply fix
 if ($PSCmdlet.ShouldProcess($file.FullName, "Fix Import-Module/Param order")) {
 $newContent | Set-Content $file.FullName
 Write-Verbose " [PASS] Fixed: $($file.Name)"
 $fixedFiles += $file.FullName
 } else {
 Write-Verbose " Would fix: $($file.Name) (WhatIf mode)"
 }
 } else {
 Write-Verbose " No Import-Module/Param order issues in: $($file.Name)"
 }
 }
 
 Write-Verbose "Completed script order fixes. Fixed files: $($fixedFiles.Count)"
 
 if ($PassThru) {
 return $fixedFiles
 }
}




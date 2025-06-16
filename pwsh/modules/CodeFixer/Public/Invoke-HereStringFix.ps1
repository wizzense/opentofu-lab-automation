<#
.SYNOPSIS
 Systematically fixes here-string syntax errors in PowerShell files

.DESCRIPTION
 Fixes common here-string syntax issues:
 - @'' should be @'
 - '@ should be '@
 - Fixes malformed here-string headers and footers
 - Handles both single and double quote here-strings

.PARAMETER Path
 Path to fix (file or directory)

.PARAMETER AutoFix
 If specified, automatically fixes the detected issues. Otherwise, only reports them.

.PARAMETER WhatIf
 Show what would be fixed without making changes

.PARAMETER Recurse
 If specified, recursively scans subdirectories.

.PARAMETER ExcludePath
 Optional paths to exclude from scanning.

.EXAMPLE
 Invoke-HereStringFix -Path ./scripts/ -AutoFix

.EXAMPLE
 Invoke-HereStringFix -Path ./script.ps1 -WhatIf
#>
function Invoke-HereStringFix {
 CmdletBinding()
 param(
 Parameter(Mandatory = $true)



 string$Path,
 
 Parameter(Mandatory = $false)
 switch$AutoFix,
 
 Parameter(Mandatory = $false)
 switch$WhatIf,
 
 Parameter(Mandatory = $false)
 switch$Recurse,
 
 Parameter(Mandatory = $false)
 string$ExcludePath = @("archive", "legacy")
 )

 Write-Host " Here-String Syntax Fixer" -ForegroundColor Cyan
 Write-Host "=" * 40

 $stats = @{
 TotalFiles = 0
 FilesWithIssues = 0
 TotalIssuesFixed = 0
 ErrorFiles = @()
 }

 # Get all PowerShell files
 $files = @()
 if (Test-Path $Path -PathType Leaf) {
 $files = @(Get-Item $Path)
 } else {
 $getParams = @{
 Path = $Path
 Include = @("*.ps1", "*.psm1", "*.psd1")
 File = $true
 }
 if ($Recurse) {
 $getParams.Recurse = $true
 }
 $files = Get-ChildItem @getParams
 }

 # Filter out excluded paths
 foreach ($exclude in $ExcludePath) {
 $files = $files  Where-Object { $_.FullName -notmatch $exclude }
 }

 $stats.TotalFiles = $files.Count
 Write-Host "Found $($stats.TotalFiles) PowerShell files to check" -ForegroundColor Gray

 # Enhanced regex patterns for finding here-string issues
 $patterns = @(
 @{ Search = "@'(?!\s*`$)"; Replace = "@'"; Description = "Fix here-string header" },
 @{ Search = "'@"; Replace = "'@"; Description = "Fix here-string footer" },
 @{ Search = '@"(?!\s*`$)'; Replace = '@"'; Description = "Fix here-string header" },
 @{ Search = '"@'; Replace = '"@'; Description = "Fix here-string footer" },
 @{ Search = "@'"; Replace = "@'"; Description = "Fix malformed here-string header" },
 @{ Search = "'@"; Replace = "'@"; Description = "Fix malformed here-string footer" }
 )

 foreach ($file in $files) {
 try {
 $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
 
 if (-not $content) { continue }
 
 $originalContent = $content
 $fileHasIssues = $false
 $fileFixes = 0

 foreach ($pattern in $patterns) {
 # Use proper regex without escaping the search pattern (since it's already a regex)
 $matches = regex::Matches($content, $pattern.Search)
 if ($matches.Count -gt 0) {
 if ((-not $WhatIf) -and ($AutoFix)) {
 $content = $content -replace $pattern.Search, $pattern.Replace
 }
 $fileFixes += $matches.Count
 $fileHasIssues = $true
 
 Write-Host " PASS $($pattern.Description): $($matches.Count) fixes in $($file.Name)" -ForegroundColor Green
 }
 }

 if ($fileHasIssues) {
 $stats.FilesWithIssues++
 $stats.TotalIssuesFixed += $fileFixes
 
 if ((-not $WhatIf) -and $AutoFix -and ($originalContent -ne $content)) {
 try {
 Set-Content -Path $file.FullName -Value $content -NoNewline
 Write-Host " � Saved $($file.Name) with $fileFixes fixes" -ForegroundColor Yellow
 } catch {
 Write-Error "Failed to save file $($file.Name): $_"
 $stats.ErrorFiles += $file.FullName
 }
 } elseif ($WhatIf) {
 Write-Host " Would fix $fileFixes issues in $($file.Name)" -ForegroundColor Yellow
 } elseif (-not $AutoFix) {
 Write-Host " WARN $fileFixes issues found in $($file.Name) - use -AutoFix to repair" -ForegroundColor Yellow
 }
 }
 } catch {
 Write-Warning "Error processing file $($file.FullName): $_"
 $stats.ErrorFiles += $file.FullName
 }
 }

 Write-Host "`n Here-String Fix Summary:" -ForegroundColor Cyan
 Write-Host " Files processed: $($stats.TotalFiles)" -ForegroundColor White
 Write-Host " Files with issues: $($stats.FilesWithIssues)" -ForegroundColor Yellow
 
 if ($AutoFix -and -not $WhatIf) {
 Write-Host " Total fixes applied: $($stats.TotalIssuesFixed)" -ForegroundColor Green
 } else {
 Write-Host " Total issues found: $($stats.TotalIssuesFixed)" -ForegroundColor Yellow
 }
 
 if ($stats.ErrorFiles.Count -gt 0) {
 Write-Host " Error files: $($stats.ErrorFiles.Count)" -ForegroundColor Red
 }
 
 if ($WhatIf) {
 Write-Host " WARN WhatIf mode - no changes made" -ForegroundColor Yellow
 } elseif (-not $AutoFix) {
 Write-Host " WARN Report-only mode - use -AutoFix to make changes" -ForegroundColor Yellow
 }

 return $stats
}



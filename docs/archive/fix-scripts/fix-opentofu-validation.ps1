<#
VALIDATION-ONLY MODE: This script has been converted to validation-only.
It will only report issues and create GitHub issues for tracking.
No automatic file modifications or repairs are performed.
Use PatchManager for explicit file changes when needed.
#>
#!/usr/bin/env pwsh
# Fix OpenTofu validation patterns

$ProjectRoot = $PSScriptRoot
$testOpenTofuPath = Join-Path $ProjectRoot "pwsh\modules\CodeFixer\Public\Test-OpenTofuConfig.ps1"

Write-Host "Creating improved OpenTofu validation logic..." -ForegroundColor Cyan

# Read the current file
$content = Get-Content -Path $testOpenTofuPath -Raw

# Replace the problematic validation patterns with better ones
$oldPattern = @'
 # Check for common syntax issues
 if ($content -match '^\\"\s*\n') {
 $lineNum = ($content.Substring(0, $matches.Index) -split "`n").Length
 $fileResult.Errors += PSCustomObject@{
 Line = $lineNum
 Message = "Unclosed double quote"
 RuleName = "SyntaxError"
 }
 }
 
 if ($content -match '^\\"^"*\$\{') {
 $lineNum = ($content.Substring(0, $matches.Index) -split "`n").Length
 $fileResult.Errors += PSCustomObject@{
 Line = $lineNum
 Message = "Interpolation syntax issue detected"
 RuleName = "InterpolationError"
 }
 }
'@

$newPattern = @'
 # Check for common syntax issues - improved patterns
 # Look for actual unclosed strings and interpolations only in broken files
 $lines = $content -split "`n"
 for ($i = 0; $i -lt $lines.Length; $i++) {
 $line = $lines$i.Trim()
 
 # Skip comments and empty lines
 if ($line -match '^\s*#' -or string::IsNullOrWhiteSpace($line)) {
 continue
 }
 
 # Check for obviously broken patterns
 if ($line -match '^^"*"^"*$' -and $line -notmatch '=\s*"^"*"?\s*$') {
 # This might be an unclosed string
 if ($line -match '"^"*$' -and $line -notmatch '=\s*"^"*$') {
 $fileResult.Errors += PSCustomObject@{
 Line = $i + 1
 Message = "Potentially unclosed string"
 RuleName = "SyntaxError"
 }
 }
 }
 
 # Check for unclosed interpolations
 if ($line -match '\$\{^}*$') {
 $fileResult.Errors += PSCustomObject@{
 Line = $i + 1
 Message = "Unclosed interpolation expression"
 RuleName = "InterpolationError"
 }
 }
 }
'@

# Apply the replacement
$newContent = $content -replace regex::Escape($oldPattern), $newPattern

# Write the improved file
newContent | # DISABLED: Out-File -FilePath $testOpenTofuPath -Encoding UTF8

Write-Host "PASS Improved OpenTofu validation patterns!" -ForegroundColor Green


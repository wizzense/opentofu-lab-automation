<#
.SYNOPSIS
 Comprehensive auto-fix for all common PowerShell syntax and structure issues

.DESCRIPTION
 Applies multiple fixes in sequence:
 - Here-string syntax issues (@'' -> @')
 - Import path issues (updates module paths)
 - Ternary syntax issues (fixes PowerShell 7 ternary expressions)
 - Test syntax issues (Pester test formatting)
 - Script order issues (dependency ordering)
 - Cleans up root directory

.PARAMETER Path
 Path to fix (file or directory). Defaults to current directory.

.PARAMETER AutoFix
 If specified, automatically fixes the detected issues. Otherwise, only reports them.

.PARAMETER WhatIf
 Show what would be fixed without making changes

.PARAMETER SkipValidation
 Skip final validation after fixes

.PARAMETER Recurse
 If specified, recursively scans subdirectories.

.PARAMETER ExcludePath
 Optional paths to exclude from scanning.

.EXAMPLE
 Invoke-ComprehensiveAutoFix -AutoFix

.EXAMPLE
 Invoke-ComprehensiveAutoFix -Path ./scripts/ -WhatIf

.EXAMPLE
 Invoke-ComprehensiveAutoFix -Path ./script.ps1 -AutoFix

.NOTES
 Updated: 2025-06-13
#>
function Invoke-ComprehensiveAutoFix {
 [CmdletBinding()]
 param(
 [Parameter(Mandatory = $false)






]
 [string]$Path = ".",
 
 [Parameter(Mandatory = $false)]
 [switch]$AutoFix,
 
 [Parameter(Mandatory = $false)]
 [switch]$WhatIf,
 
 [Parameter(Mandatory = $false)]
 [switch]$SkipValidation,
 
 [Parameter(Mandatory = $false)]
 [switch]$Recurse,
 
 [Parameter(Mandatory = $false)]
 [switch]$CleanupRoot,
 
 [Parameter(Mandatory = $false)]
 [string[]]$ExcludePath = @("archive", "legacy", "backup")
 )

 Write-Host " Comprehensive PowerShell Auto-Fix" -ForegroundColor Cyan
 Write-Host "=" * 50

 # Overall statistics
 $stats = @{
 TotalFiles = 0
 FilesFixed = 0
 TotalFixes = 0
 FixesByCategory = @{
 HereString = 0
 ImportPaths = 0
 TestSyntax = 0
 RootCleanup = 0
 TernarySyntax = 0
 ScriptOrder = 0
 }
 }
 $startTime = Get-Date

 # Step 1: Fix here-strings
 Write-Host "`n1⃣ Fixing here-string syntax..." -ForegroundColor Yellow
 try {
 $hereStringParams = @{
 Path = $Path
 ExcludePath = $ExcludePath
 }
 if ($AutoFix -and -not $WhatIf) { $hereStringParams.AutoFix = $true }
 if ($WhatIf) { $hereStringParams.WhatIf = $true }
 if ($Recurse) { $hereStringParams.Recurse = $true }
 
 $hereStringResults = Invoke-HereStringFix @hereStringParams
 $stats.FixesByCategory.HereString += $hereStringResults.TotalIssuesFixed
 } catch {
 Write-Warning "Here-string fix failed: $_"
 }

 # Step 2: Fix import paths
 Write-Host "`n2⃣ Fixing import paths..." -ForegroundColor Yellow
 try {
 $importParams = @{
 Path = $Path
 }
 if ($AutoFix -and -not $WhatIf) { $importParams.AutoFix = $true }
 
 $importResults = Invoke-ImportAnalysis @importParams
 $stats.FixesByCategory.ImportPaths += $importResults.TotalFixes
 } catch {
 Write-Warning "Import fix failed: $_"
 }

 # Step 3: Fix ternary syntax
 Write-Host "`n3⃣ Fixing ternary syntax..." -ForegroundColor Yellow
 try {
 $ternaryParams = @{
 Path = $Path
 }
 if ($WhatIf) { $ternaryParams.WhatIf = $true }
 if ($AutoFix -and -not $WhatIf) { $ternaryParams.AutoFix = $true }
 
 $ternaryResults = Invoke-TernarySyntaxFix @ternaryParams
 $stats.FixesByCategory.TernarySyntax += $ternaryResults.TotalFixes
 } catch {
 Write-Warning "Ternary fix failed: $_"
 }

 # Step 4: Fix test syntax
 Write-Host "`n4⃣ Fixing test syntax..." -ForegroundColor Yellow
 try {
 $testParams = @{
 Path = $Path
 }
 if ($WhatIf) { $testParams.WhatIf = $true }
 if ($AutoFix -and -not $WhatIf) { $testParams.AutoFix = $true }
 
 $testResults = Invoke-TestSyntaxFix @testParams
 $stats.FixesByCategory.TestSyntax += $testResults.TotalFixes
 } catch {
 Write-Warning "Test syntax fix failed: $_"
 }

 # Step 5: Clean up root directory
 if ($CleanupRoot -and -not $WhatIf) {
 Write-Host "`n5⃣ Cleaning up root directory..." -ForegroundColor Yellow
 try {
 # Use proper cleanup script
 $scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts/maintenance/cleanup-root-scripts.ps1"
 if (Test-Path $scriptPath) {
 & $scriptPath
 } else {
 $scriptPath = "/workspaces/opentofu-lab-automation/scripts/maintenance/cleanup-root-scripts.ps1"
 if (Test-Path $scriptPath) {
 & $scriptPath
 } else {
 Write-Warning "Could not find cleanup script"
 }
 }
 $stats.FixesByCategory.RootCleanup++
 } catch {
 Write-Warning "Root cleanup failed: $_"
 }
 }

 # Step 6: Run script ordering fix
 Write-Host "`n6⃣ Fixing script order..." -ForegroundColor Yellow
 try {
 if ($AutoFix -and -not $WhatIf) {
 $orderResults = Invoke-ScriptOrderFix -Path $Path -AutoFix
 $stats.FixesByCategory.ScriptOrder += $orderResults.TotalFixes
 } else {
 $orderResults = Invoke-ScriptOrderFix -Path $Path -WhatIf:$true
 }
 } catch {
 Write-Warning "Script order fix failed: $_"
 }

 # Step 7: Run comprehensive validation (if not skipped and not WhatIf)
 if (-not $SkipValidation -and -not $WhatIf -and $AutoFix) {
 Write-Host "`n7⃣ Running validation..." -ForegroundColor Yellow
 try {
 $validationResults = Invoke-ComprehensiveValidation -Path $Path -SkipLint
 } catch {
 Write-Warning "Validation failed: $_"
 }
 }

 $endTime = Get-Date
 $duration = $endTime - $startTime

 # Calculate total fixes
 $stats.TotalFixes = ($stats.FixesByCategory.Values | Measure-Object -Sum).Sum
 
 # Summary
 Write-Host "`n Comprehensive Auto-Fix Summary:" -ForegroundColor Cyan
 Write-Host " Duration: $($duration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor White
 
 $color = if ($AutoFix -and -not $WhatIf) { "Green" } else { "Yellow" }
 
 Write-Host " Here-strings: $($stats.FixesByCategory.HereString) fixes" -ForegroundColor $color
 Write-Host " Import paths: $($stats.FixesByCategory.ImportPaths) fixes" -ForegroundColor $color 
 Write-Host " Ternary syntax: $($stats.FixesByCategory.TernarySyntax) fixes" -ForegroundColor $color
 Write-Host " Test syntax: $($stats.FixesByCategory.TestSyntax) fixes" -ForegroundColor $color
 Write-Host " Script order: $($stats.FixesByCategory.ScriptOrder) fixes" -ForegroundColor $color
 
 if ($CleanupRoot -and -not $WhatIf) {
 Write-Host " Root cleanup: Completed" -ForegroundColor Green
 }
 
 Write-Host " TOTAL FIXES: $($stats.TotalFixes)" -ForegroundColor Cyan
 
 if ($validationResults) {
 Write-Host "`n Final Validation Results:" -ForegroundColor Magenta
 Write-Host " Valid files: $($validationResults.ValidFiles)/$($validationResults.TotalFiles)" -ForegroundColor Green
 
 if ($validationResults.ErrorFiles -gt 0) {
 Write-Host " Files with errors: $($validationResults.ErrorFiles)" -ForegroundColor Red
 } else {
 Write-Host " No errors found! " -ForegroundColor Green
 }
 }
 
 if ($WhatIf) {
 Write-Host "`n [WARN] WhatIf mode - no changes were made" -ForegroundColor Yellow
 } elseif (-not $AutoFix) {
 Write-Host "`n [INFO] Report-only mode - use -AutoFix to apply changes" -ForegroundColor Yellow
 }

 return $stats
}




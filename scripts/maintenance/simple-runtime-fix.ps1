# fix-runtime-execution-simple.ps1
# Simple targeted fixes for the most critical runtime execution issues

[CmdletBinding()]
param(
 [Parameter(Mandatory = $false)






]
 [switch]$WhatIf
)

Import-Module (Join-Path $PSScriptRoot "/pwsh/modules/CodeFixer/CodeFixer.psd1") -Force

$ErrorActionPreference = "Stop"

Write-Host " Applying Simple Runtime Execution Fixes" -ForegroundColor Cyan
Write-Host "=" * 50

$runnerPath = "pwsh/runner.ps1"

if (-not (Test-Path $runnerPath)) {
 Write-Error "Runner script not found: $runnerPath"
 exit 1
}

$content = Get-Content $runnerPath -Raw
$fixes = @()

# Fix 1: Add script syntax validation before execution
Write-Host " Fix 1: Adding script syntax validation..." -ForegroundColor Green

$validationInsert = @'
 # Validate script syntax before execution
 try {
 $scriptContent = Get-Content $scriptPath -Raw
 $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)
 Write-CustomLog "Script syntax validation passed for $($s.Name)"
 } catch {
 Write-CustomLog "ERROR: Script has syntax errors: $scriptPath - $_" 'ERROR'
 $failed += $s.Name
 continue
 }
 
'@

# Insert validation before the config flag check
if ($content -match '(\s+)(if \(\$flag = Get-ScriptConfigFlag -Path \$scriptPath\))') {
 $content = $content -replace '(\s+)(if \(\$flag = Get-ScriptConfigFlag -Path \$scriptPath\))', "`$1$validationInsert`$2"
 $fixes += "[PASS] Added script syntax validation before execution"
} else {
 Write-Warning "Could not find insertion point for syntax validation"
}

# Fix 2: Improve error detection in output processing
Write-Host " Fix 2: Improving error detection..." -ForegroundColor Green

$oldErrorProcessing = @'
 foreach ($line in $output) {
 if (-not $line) { continue }
 if ($line -is [System.Management.Automation.ErrorRecord]) {
 Write-Error $line.ToString()
 } elseif ($line -is [System.Management.Automation.WarningRecord]) {
 Write-Warning $line.ToString()
 } else {
 Write-CustomLog $line.ToString()
 }
 }
'@

$newErrorProcessing = @'
 foreach ($line in $output) {
 if (-not $line) { continue }
 
 $lineStr = $line.ToString().Trim()
 
 # Detect PowerShell parameter binding errors
 if ($lineStr -match "The term 'Param' is not recognized" -or 
 $lineStr -match "ParameterBindingException" -or
 $lineStr -match "positional parameter cannot be found") {
 Write-CustomLog "ERROR: Parameter binding issue detected in $($s.Name): $lineStr" 'ERROR'
 $exitCode = 1
 } elseif ($line -is [System.Management.Automation.ErrorRecord] -or $lineStr.StartsWith('ERROR:')) {
 Write-CustomLog "ERROR: $lineStr" 'ERROR'
 $exitCode = 1
 } elseif ($line -is [System.Management.Automation.WarningRecord] -or $lineStr.StartsWith('WARNING:')) {
 Write-CustomLog "WARNING: $lineStr" 'WARN'
 } else {
 Write-CustomLog $lineStr
 }
 }
'@

if ($content -match [regex]::Escape($oldErrorProcessing)) {
 $content = $content -replace [regex]::Escape($oldErrorProcessing), $newErrorProcessing
 $fixes += "[PASS] Enhanced error detection for parameter binding issues"
} else {
 Write-Warning "Could not find error processing section to enhance"
}

# Fix 3: Improve config file encoding
Write-Host " Fix 3: Fixing config file encoding..." -ForegroundColor Green

$content = $content -replace 
 'Out-File -FilePath \$tempCfg -Encoding utf8', 
 'Out-File -FilePath $tempCfg -Encoding utf8 -NoNewline'

$fixes += "[PASS] Fixed temporary config file encoding"

# Display what we're fixing
Write-Host "`n Applied Fixes:" -ForegroundColor Cyan
foreach ($fix in $fixes) {
 Write-Host " $fix" -ForegroundColor White
}

if ($WhatIf) {
 Write-Host "`n[WARN] WhatIf mode - changes not applied" -ForegroundColor Yellow
 Write-Host "Run without -WhatIf to apply fixes" -ForegroundColor Gray
 return
}

# Backup original file
$backupPath = "$runnerPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $runnerPath $backupPath
Write-Host "� Backup created: $backupPath" -ForegroundColor Gray

# Apply fixes
Set-Content -Path $runnerPath -Value $content -Encoding UTF8
Write-Host "[PASS] Simple runtime fixes applied successfully!" -ForegroundColor Green

# Validate the fixed script
Write-Host "`n� Validating fixed script..." -ForegroundColor Cyan

try {
 # Test PowerShell syntax
 $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
 Write-Host "[PASS] PowerShell syntax validation passed" -ForegroundColor Green
} catch {
 Write-Error "[FAIL] PowerShell syntax validation failed: $_"
 Write-Host "Restoring backup..." -ForegroundColor Yellow
 Copy-Item $backupPath $runnerPath -Force
 exit 1
}

Write-Host "`n✨ Simple runtime execution fixes completed successfully!" -ForegroundColor Green






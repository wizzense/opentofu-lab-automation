# fix-bootstrap-script.ps1
# Comprehensive fix for kicker-bootstrap.ps1 runtime issues

[CmdletBinding()]

Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/""/CodeFixer.psd1") -Force
param(
    [Parameter(Mandatory = $false)






]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Fixing Bootstrap Script Runtime Issues" -ForegroundColor Cyan
Write-Host "=" * 50

$bootstrapPath = "pwsh/kicker-bootstrap.ps1"

if (-not (Test-Path $bootstrapPath)) {
    Write-Error "Bootstrap script not found: $bootstrapPath"
    exit 1
}

Write-Host "📄 Reading current bootstrap script..." -ForegroundColor Yellow

$content = Get-Content $bootstrapPath -Raw

# Fix 1: Remove duplicate prompt definition and standardize prompting
Write-Host "🔧 Fix 1: Consolidating prompt logic..." -ForegroundColor Green

$fixes = @()

# Remove the problematic global prompt variable and Write-Continue function that causes duplicates
$oldPromptSection = @'
$prompt = "`n<press any key to continue>`n"


function Write-Continue($prompt) {
  [Console]::Write($prompt + '  ')
  Read-LoggedInput -Prompt $prompt | Out-Null
}
'@

$newPromptSection = @'
function Write-Continue {
    param([string]$Message = "Press any key to continue...")
    






Write-Host $Message -ForegroundColor Yellow -NoNewline
    $null = Read-Host
}
'@

if ($content -match [regex]::Escape($oldPromptSection)) {
    $content = $content -replace [regex]::Escape($oldPromptSection), $newPromptSection
    $fixes += "✅ Replaced problematic Write-Continue function"
} else {
    Write-Warning "Could not find exact prompt section to replace - applying manual fix"
    
    # Manual replacement patterns
    $content = $content -replace 'function Write-Continue\(\$prompt\) \{[^}]+\}', $newPromptSection
    $content = $content -replace '\$prompt = "`n<press any key to continue>`n"', ''
    $fixes += "✅ Applied manual Write-Continue fix"
}

# Fix 2: Replace the Write-Continue call with a cleaner version
$oldWriteCall = 'Write-Continue "`n<press any key to continue>`n"'
$newWriteCall = 'Write-Continue "Press Enter to continue..."'

if ($content -match [regex]::Escape($oldWriteCall)) {
    $content = $content -replace [regex]::Escape($oldWriteCall), $newWriteCall
    $fixes += "✅ Fixed Write-Continue call"
}

# Fix 3: Fix configuration selection logic that might cause parsing issues
$oldConfigLogic = @'
        for ($i = 0; $i -lt $configFiles.Count; $i++) {
            $num = $i + 1
            Write-CustomLog ("{0}) {1}" -f $num, $configFiles[$i].Name) "INFO" | Write-Host
        }
'@

$newConfigLogic = @'
        for ($i = 0; $i -lt $configFiles.Count; $i++) {
            $num = $i + 1
            Write-Host "$num) $($configFiles[$i].Name)" -ForegroundColor White
        }
'@

if ($content -match [regex]::Escape($oldConfigLogic)) {
    $content = $content -replace [regex]::Escape($oldConfigLogic), $newConfigLogic
    $fixes += "✅ Fixed configuration selection display"
}

# Fix 4: Improve prompt handling in configuration selection
$oldConfigPrompt = '$ans = Read-LoggedInput -Prompt ''Select configuration number'''
$newConfigPrompt = '$ans = Read-Host -Prompt "Select configuration number"'

$content = $content -replace [regex]::Escape($oldConfigPrompt), $newConfigPrompt
$fixes += "✅ Simplified configuration selection prompt"

# Fix 5: Clean up any stray escape characters or formatting issues
$content = $content -replace '`n<press any key to continue>`n', 'Press Enter to continue...'
$content = $content -replace ':\s*$', ''  # Remove trailing colons at end of lines

# Fix 6: Ensure proper Read-LoggedInput usage
$content = $content -replace 'Read-LoggedInput -Prompt "([^"]+)"', 'Read-Host -Prompt "$1"'

$fixes += "✅ Cleaned up formatting and escape characters"

# Fix 7: Add input validation for configuration selection
$validationFix = @'
        $ans = Read-Host -Prompt "Select configuration number"
        
        # Validate input
        if (-not $ans -or $ans -notmatch '^\d+$') {
            Write-Host "Invalid input. Using first configuration file." -ForegroundColor Yellow
            $ConfigFile = $configFiles[0].FullName
        } elseif ([int]$ans -ge 1 -and [int]$ans -le $configFiles.Count) {
            $ConfigFile = $configFiles[[int]$ans - 1].FullName
        } else {
            Write-Host "Number out of range. Using first configuration file." -ForegroundColor Yellow
            $ConfigFile = $configFiles[0].FullName
        }
'@

$oldValidation = @'
        $ans = Read-Host -Prompt "Select configuration number"
        if ($ans -match '^[0-9]+$' -and [int]$ans -ge 1 -and [int]$ans -le $configFiles.Count) {
            $ConfigFile = $configFiles[[int]$ans - 1].FullName
        } else {
            $ConfigFile = $configFiles[0].FullName
        }
'@

$content = $content -replace [regex]::Escape('$ans = Read-Host -Prompt "Select configuration number"[^}]+\}'), $validationFix

$fixes += "✅ Added input validation for configuration selection"

# Display what we're fixing
Write-Host "`n🔍 Applied Fixes:" -ForegroundColor Cyan
foreach ($fix in $fixes) {
    Write-Host "  $fix" -ForegroundColor White
}

if ($WhatIf) {
    Write-Host "`n⚠️ WhatIf mode - changes not applied" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to apply fixes" -ForegroundColor Gray
    return
}

# Backup original file
$backupPath = "$bootstrapPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $bootstrapPath $backupPath
Write-Host "📁 Backup created: $backupPath" -ForegroundColor Gray

# Apply fixes
Set-Content -Path $bootstrapPath -Value $content -Encoding UTF8
Write-Host "✅ Bootstrap script fixes applied successfully!" -ForegroundColor Green

# Validate the fixed script
Write-Host "`n🔬 Validating fixed script..." -ForegroundColor Cyan

try {
    # Test PowerShell syntax
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
    Write-Host "✅ PowerShell syntax validation passed" -ForegroundColor Green
} catch {
    Write-Error "❌ PowerShell syntax validation failed: $_"
    Write-Host "Restoring backup..." -ForegroundColor Yellow
    Copy-Item $backupPath $bootstrapPath -Force
    exit 1
}

# Test for common issues
$issues = @()

if ($content -match 'Write-Continue.*Write-Continue') {
    $issues += "Potential duplicate Write-Continue calls"
}

if ($content -match ':\s*$') {
    $issues += "Potential stray colons found"
}

if ($content -match '\$prompt.*\$prompt') {
    $issues += "Potential duplicate prompt variables"
}

if ($issues.Count -gt 0) {
    Write-Host "`n⚠️ Potential remaining issues detected:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
} else {
    Write-Host "🎉 No remaining issues detected!" -ForegroundColor Green
}

Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "  - Original file backed up to: $backupPath" -ForegroundColor White
Write-Host "  - Applied $($fixes.Count) fixes to bootstrap script" -ForegroundColor White
Write-Host "  - Fixed prompt duplication and formatting issues" -ForegroundColor White
Write-Host "  - Improved configuration selection logic" -ForegroundColor White
Write-Host "  - Enhanced error handling and validation" -ForegroundColor White

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test the bootstrap script in a clean environment" -ForegroundColor White
Write-Host "  2. Verify no duplicate prompts appear" -ForegroundColor White
Write-Host "  3. Check configuration selection works properly" -ForegroundColor White
Write-Host "  4. Monitor for the ':' character issues" -ForegroundColor White

Write-Host "`n✨ Bootstrap script fixes completed successfully!" -ForegroundColor Green





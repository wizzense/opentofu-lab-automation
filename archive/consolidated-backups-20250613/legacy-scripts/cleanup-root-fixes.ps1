#!/usr/bin/env pwsh
<#
.SYNOPSIS
Clean up root directory by moving scattered fix scripts to archive and creating unified interface

.DESCRIPTION
Moves old fix scripts from root to archive and creates a simple unified auto-fix wrapper
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)








Write-Host "🧹 Cleaning up root directory..." -ForegroundColor Cyan

# Files to move to archive
$filesToMove = @(
    "fix-all-syntax-errors.ps1",
    "fix-here-strings.ps1", 
    "cleanup-remaining.ps1",
    "organize-project-fixed.ps1",
    "organize-project.ps1"
)

# Create archive directory for old fix scripts
$archiveDir = "archive/root-fix-scripts-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (-not $WhatIf) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

$moved = 0
foreach ($file in $filesToMove) {
    if (Test-Path $file) {
        Write-Host "  📦 Moving $file to archive..." -ForegroundColor Yellow
        if (-not $WhatIf) {
            Move-Item $file $archiveDir -Force
        }
        $moved++
    }
}

# Keep auto-fix.ps1 but update it to use the module
$newAutoFix = @'
#!/usr/bin/env pwsh
<#
.SYNOPSIS
Unified auto-fix script using CodeFixer module

.DESCRIPTION
Simple wrapper around the CodeFixer module for comprehensive auto-fixing
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)






]
    [string]$Path = ".",
    
    [switch]$WhatIf,
    [switch]$SkipValidation
)

# Import CodeFixer module
Import-Module (Join-Path $PSScriptRoot "pwsh/modules/CodeFixer") -Force

# Run comprehensive auto-fix
Invoke-ComprehensiveAutoFix -Path $Path -WhatIf:$WhatIf -SkipValidation:$SkipValidation
'@

if (-not $WhatIf) {
    Set-Content -Path "auto-fix.ps1" -Value $newAutoFix
    Write-Host "  ✅ Updated auto-fix.ps1 to use CodeFixer module" -ForegroundColor Green
}

Write-Host "`n📊 Cleanup Summary:" -ForegroundColor Cyan
Write-Host "  Files moved to archive: $moved" -ForegroundColor White
Write-Host "  Updated auto-fix.ps1 to use module" -ForegroundColor Green

if ($WhatIf) {
    Write-Host "  ⚠️  WhatIf mode - no changes made" -ForegroundColor Yellow
} else {
    Write-Host "  📁 Archive created: $archiveDir" -ForegroundColor Yellow
}




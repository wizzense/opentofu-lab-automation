#!/usr/bin/env pwsh
<#
.SYNOPSIS
Comprehensive fix for ALL import corruption patterns identified in the codebase

.DESCRIPTION
This script fixes multiple corruption patterns:
1. Missing newlines between import statements
2. Duplicate -Force flags (accumulating each run)
3. Malformed absolute Windows paths 
4. Double slashes in paths
5. Concatenated statements without separation

.PARAMETER WhatIf
Shows what would be fixed without applying changes

.EXAMPLE
./comprehensive-import-fix.ps1
./comprehensive-import-fix.ps1 -WhatIf
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

function Write-FixLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [COMPREHENSIVE-FIX] [$Level] $Message" -ForegroundColor $color
}

Write-FixLog "Starting comprehensive import corruption fix..." "SUCCESS"

# Get all PowerShell files
$allFiles = Get-ChildItem -Path "." -Recurse -Include "*.ps1", "*.psm1" -File |
    Where-Object { 
        $_.FullName -notlike "*\archive\*" -and 
        $_.FullName -notlike "*\backups\*" -and
        $_.FullName -notlike "*\.git\*"
    }

Write-FixLog "Found $($allFiles.Count) PowerShell files to check"

$stats = @{
    FilesChecked = 0
    FilesCorrupted = 0
    FilesFixed = 0
    DuplicateForceFlags = 0
    ImportPathsFixed = 0
    NewlinesAdded = 0
    ConcatenationFixed = 0
}

foreach ($file in $allFiles) {
    $stats.FilesChecked++
    $relativePath = $file.FullName -replace [regex]::Escape($PWD), "."
    
    try {
        $originalContent = Get-Content -Path $file.FullName -Raw
        $newContent = $originalContent
        $fileChanged = $false
        $issues = @()
        
        # Pattern 1: Fix concatenated Import-Module statements (missing newlines)
        if ($newContent -match 'Import-Module[^`r`n]*Import-Module') {
            $issues += "Concatenated import statements"
            $newContent = $newContent -replace '(Import-Module[^`r`n]*?)(?=Import-Module)', "`$1`n"
            $fileChanged = $true
            $stats.NewlinesAdded++
        }
        
        # Pattern 2: Remove duplicate -Force flags (more than one)
        $forceMatches = [regex]::Matches($newContent, '(-Force\s*)+')
        foreach ($match in $forceMatches) {
            $forceCount = ($match.Value -split '-Force').Count - 1
            if ($forceCount -gt 1) {
                $issues += "Duplicate -Force flags ($forceCount found)"
                $newContent = $newContent -replace [regex]::Escape($match.Value), ' -Force'
                $fileChanged = $true
                $stats.DuplicateForceFlags += ($forceCount - 1)
            }
        }
          # Pattern 3: Fix malformed absolute Windows paths
        if ($newContent -match 'Import-Module\s+["`'']?/C:\\') {
            $issues += "Malformed absolute Windows paths"
            $newContent = $newContent -replace 'Import-Module\s+["`'']?/C:\\[^"`'']*?//pwsh/modules/([^/"`'']*)/["`'']?', 'Import-Module "/pwsh/modules/$1/"'
            $fileChanged = $true
            $stats.ImportPathsFixed++
        }
        
        # Pattern 4: Fix double slashes in import paths
        if ($newContent -match 'Import-Module[^`r`n]*//') {
            $issues += "Double slashes in import paths"
            $newContent = $newContent -replace '(Import-Module[^`r`n]*?)//+', '$1/'
            $fileChanged = $true
        }
        
        # Pattern 5: Fix Import-Module statements that run into other commands
        if ($newContent -match 'Import-Module[^`r`n]*-Force[A-Za-z]') {
            $issues += "Import statement concatenated with other commands"
            $newContent = $newContent -replace '(Import-Module[^`r`n]*?-Force)([A-Za-z])', "`$1`n`$2"
            $fileChanged = $true
            $stats.ConcatenationFixed++
        }
          # Pattern 6: Fix basic path corrections to use relative paths
        $newContent = $newContent -replace 'Import-Module\s+["`'']?/pwsh/modules/(LabRunner|CodeFixer|BackupManager|PatchManager)/["`'']?', 'Import-Module "/pwsh/modules/$1/"'
        
        if ($issues.Count -gt 0) {
            $stats.FilesCorrupted++
            Write-FixLog "CORRUPTED: $relativePath - Issues: $($issues -join ', ')" "WARNING"
            
            if (-not $WhatIf) {
                Set-Content -Path $file.FullName -Value $newContent -NoNewline
                $stats.FilesFixed++
                Write-FixLog "  FIXED: $relativePath" "SUCCESS"
            } else {
                Write-FixLog "  Would fix: $relativePath" "INFO"
            }
        }
        
    } catch {
        Write-FixLog "ERROR processing $relativePath`: $($_.Exception.Message)" "ERROR"
    }
}

Write-FixLog "Comprehensive fix completed!" "SUCCESS"
Write-FixLog "Statistics:" "INFO"
Write-FixLog "  Files checked: $($stats.FilesChecked)" "INFO"
Write-FixLog "  Files corrupted: $($stats.FilesCorrupted)" "INFO"
Write-FixLog "  Files fixed: $($stats.FilesFixed)" "INFO"
Write-FixLog "  Duplicate -Force flags removed: $($stats.DuplicateForceFlags)" "INFO"
Write-FixLog "  Import paths corrected: $($stats.ImportPathsFixed)" "INFO"
Write-FixLog "  Missing newlines added: $($stats.NewlinesAdded)" "INFO"
Write-FixLog "  Concatenation issues fixed: $($stats.ConcatenationFixed)" "INFO"

if ($WhatIf) {
    Write-FixLog "Run without -WhatIf to apply these fixes" "INFO"
} else {
    Write-FixLog "All fixes have been applied!" "SUCCESS"
}

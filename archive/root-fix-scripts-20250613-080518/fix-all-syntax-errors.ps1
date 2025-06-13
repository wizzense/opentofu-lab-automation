#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive fix for all PowerShell syntax errors in the project

.DESCRIPTION
    This script identifies and fixes all PowerShell syntax errors across the entire project,
    with special handling for GitHub Actions syntax that confuses PowerShell parsers.
#>

param(
    [switch]$WhatIf
)





$ErrorActionPreference = "Stop"

Write-Host "🔧 COMPREHENSIVE POWERSHELL SYNTAX FIX" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$totalFixed = 0
$issuesFound = @()

# Function to fix GitHub Actions syntax in PowerShell files
function Fix-GitHubActionsSyntax {
    param([string]$FilePath, [string]$Content)
    
    



$originalContent = $Content
    $fixedContent = $Content
    $changes = @()
    
    # Pattern 1: Fix ${{ }} in strings - make them literal strings
    $pattern1 = '\$\{\{([^}]+)\}\}'
    if ($fixedContent -match $pattern1) {
        $fixedContent = $fixedContent -replace $pattern1, '`${{ $1 }}'
        $changes += "Fixed GitHub Actions syntax: `${{ }} -> ```${{ }}"
    }
    
    # Pattern 2: Fix backtick issues in variable names
    $pattern2 = 'Use `\{ instead of \{ in variable names\.'
    
    # Pattern 3: Fix double quotes around GitHub expressions
    $pattern3 = '"\$\{\{([^}]+)\}\}"'
    if ($fixedContent -match $pattern3) {
        $fixedContent = $fixedContent -replace $pattern3, '"`${{ $1 }}"'
        $changes += "Fixed quoted GitHub Actions expressions"
    }
    
    # Pattern 4: Fix single quotes around GitHub expressions  
    $pattern4 = "'\$\{\{([^}]+)\}\}'"
    if ($fixedContent -match $pattern4) {
        $fixedContent = $fixedContent -replace $pattern4, "'`${{ `$1 }}'"
        $changes += "Fixed single-quoted GitHub Actions expressions"
    }
    
    return @{
        Content = $fixedContent
        Changed = ($originalContent -ne $fixedContent)
        Changes = $changes
    }
}

# Function to fix common PowerShell syntax errors
function Fix-CommonSyntaxErrors {
    param([string]$FilePath, [string]$Content)
    
    



$originalContent = $Content
    $fixedContent = $Content
    $changes = @()
    
    # Fix missing string terminators
    $lines = $fixedContent -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Check for unclosed single quotes
        $singleQuotes = ($line.ToCharArray() | Where-Object { $_ -eq "'" }).Count
        if ($singleQuotes % 2 -eq 1 -and $line -notmatch "\\'" -and $line -notmatch "#.*'") {
            $lines[$i] = $line + "'"
            $changes += "Fixed missing single quote on line $($i + 1)"
        }
        
        # Check for unclosed double quotes
        $doubleQuotes = ($line.ToCharArray() | Where-Object { $_ -eq '"' }).Count
        if ($doubleQuotes % 2 -eq 1 -and $line -notmatch '\\"' -and $line -notmatch '#.*"') {
            $lines[$i] = $line + '"'
            $changes += "Fixed missing double quote on line $($i + 1)"
        }
    }
    $fixedContent = $lines -join "`n"
    
    # Fix missing closing braces
    $openBraces = ($fixedContent.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($fixedContent.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    if ($openBraces -gt $closeBraces) {
        $fixedContent += "`n}"
        $changes += "Added missing closing brace"
    }
    
    return @{
        Content = $fixedContent
        Changed = ($originalContent -ne $fixedContent)
        Changes = $changes
    }
}

# Get all PowerShell files, excluding legacy/archive
$allFiles = Get-ChildItem -Path . -Recurse -Include "*.ps1", "*.psm1", "*.psd1" -File | 
    Where-Object { 
        $_.FullName -notmatch [regex]::Escape("archive") -and
        $_.FullName -notmatch [regex]::Escape("legacy") -and 
        $_.FullName -notmatch [regex]::Escape("historical-fixes") -and
        $_.FullName -notmatch [regex]::Escape(".backup") -and
        $_.FullName -notmatch [regex]::Escape("temp") -and
        $_.FullName -notmatch [regex]::Escape("backup") 
    }

Write-Host "Found $($allFiles.Count) PowerShell files to check (excluding legacy/archive)" -ForegroundColor Green

# Check each file for syntax errors
foreach ($file in $allFiles) {
    Write-Host "`nChecking: $($file.Name)" -ForegroundColor Gray
    
    try {
        # Test syntax first
        $tokens = $null
        $parseErrors = $null
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Host "  ⚠️  Empty file, skipping" -ForegroundColor Yellow
            continue
        }
        
        # Try to parse
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $content, 
            $file.FullName,
            [ref]$tokens, 
            [ref]$parseErrors
        )
        
        if ($parseErrors.Count -eq 0) {
            Write-Host "  ✅ No syntax errors" -ForegroundColor Green
            continue
        }
        
        Write-Host "  ❌ Found $($parseErrors.Count) syntax error(s)" -ForegroundColor Red
        
        $issuesFound += @{
            File = $file.FullName
            Errors = $parseErrors
        }
        
        if ($WhatIf) {
            foreach ($error in $parseErrors) {
                Write-Host "    - $($error.Message)" -ForegroundColor Yellow
            }
            continue
        }
        
        # Try to fix
        $allChanges = @()
        $currentContent = $content
        
        # Apply GitHub Actions fixes
        $githubFix = Fix-GitHubActionsSyntax -FilePath $file.FullName -Content $currentContent
        if ($githubFix.Changed) {
            $currentContent = $githubFix.Content
            $allChanges += $githubFix.Changes
        }
        
        # Apply common syntax fixes
        $syntaxFix = Fix-CommonSyntaxErrors -FilePath $file.FullName -Content $currentContent
        if ($syntaxFix.Changed) {
            $currentContent = $syntaxFix.Content
            $allChanges += $syntaxFix.Changes
        }
        
        # Save if we made changes
        if ($allChanges.Count -gt 0) {
            # Create backup
            $backupPath = "$($file.FullName).backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -Path $file.FullName -Destination $backupPath
            
            # Save fixed content
            Set-Content -Path $file.FullName -Value $currentContent -Encoding UTF8
            
            Write-Host "  ✅ FIXED: Applied $($allChanges.Count) fix(es)" -ForegroundColor Green
            foreach ($change in $allChanges) {
                Write-Host "    • $change" -ForegroundColor Cyan
            }
            
            $totalFixed++
            
            # Verify the fix worked
            try {
                $verifyErrors = $null
                [System.Management.Automation.Language.Parser]::ParseFile(
                    $file.FullName, 
                    [ref]$null, 
                    [ref]$verifyErrors
                )
                if ($verifyErrors.Count -eq 0) {
                    Write-Host "  ✅ Verification: Syntax is now valid" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠️  Verification: $($verifyErrors.Count) errors remain" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  ❌ Verification failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  ⚠️  No automatic fixes available" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ❌ Error processing file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "📊 COMPREHENSIVE FIX SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Files Checked:        $($allFiles.Count)" -ForegroundColor White
Write-Host "Files with Issues:    $($issuesFound.Count)" -ForegroundColor Yellow
Write-Host "Files Fixed:          $totalFixed" -ForegroundColor $$(if (totalFixed -gt 0) { "Green" } else { "White" })

if ($WhatIf) {
    Write-Host "`nWhatIf Mode: No changes were made" -ForegroundColor Yellow
    if ($issuesFound.Count -gt 0) {
        Write-Host "`nTo fix these issues, run without -WhatIf:" -ForegroundColor Cyan
        Write-Host "  ./fix-all-syntax-errors.ps1" -ForegroundColor Gray
    }
} else {
    if ($totalFixed -gt 0) {
        Write-Host "`n✅ Successfully fixed $totalFixed files!" -ForegroundColor Green
        Write-Host "💡 Backup files created with .backup-* extension" -ForegroundColor Yellow
    } else {
        Write-Host "`n✅ No fixes were needed!" -ForegroundColor Green
    }
}

Write-Host "=====================================" -ForegroundColor Cyan



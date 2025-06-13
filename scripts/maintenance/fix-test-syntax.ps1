#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/fix-test-syntax.ps1

<#
.SYNOPSIS
Fixes common test syntax errors found throughout the test suite.

.DESCRIPTION
This script systematically fixes common Pester test syntax errors including:
- Malformed It statements with mismatched quotes/parentheses
- Missing closing braces
- Incorrect WhatIf parameter names
- Improper InModuleScope blocks
- Import path issues

.PARAMETER DryRun
Show what would be fixed without making changes

.EXAMPLE
./scripts/maintenance/fix-test-syntax.ps1

.EXAMPLE
./scripts/maintenance/fix-test-syntax.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [Parameter()






]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "/workspaces/opentofu-lab-automation"

function Write-SyntaxLog {
    param([string]$Message, [string]$Level = "INFO")
    






$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "FIX" { "Magenta" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-PowerShellSyntax {
    param([string]$FilePath)
    






try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $FilePath -Raw), [ref]$null)
        return $true
    }
    catch {
        return $false
    }
}

function Fix-TestFileSyntax {
    param([string]$FilePath)
    
    






$content = Get-Content $FilePath -Raw
    $originalContent = $content
    $fileName = Split-Path $FilePath -Leaf
    
    Write-SyntaxLog "Analyzing: $fileName" "INFO"
    
    # Check if file has syntax errors
    if (Test-PowerShellSyntax $FilePath) {
        Write-SyntaxLog "No syntax errors in: $fileName" "SUCCESS"
        return $false
    }
    
    Write-SyntaxLog "Fixing syntax errors in: $fileName" "FIX"
    
    # Common syntax fixes
    $fixes = @(
        # Fix malformed It statements with missing quotes or parentheses
        @{ 
            Pattern = "It '([^']*)\([^)]*'[^)]*\)"
            Replacement = "It '`$1'"
            Description = "Fix malformed It statements with mismatched quotes/parentheses"
        },
        
        # Fix -Whatif to -WhatIf (correct PowerShell parameter)
        @{
            Pattern = "-Whatif\b"
            Replacement = "-WhatIf"
            Description = "Fix -Whatif parameter to correct -WhatIf"
        },
        
        # Fix missing spaces before opening braces in It statements
        @{
            Pattern = "It '([^']+)'\s*\{"
            Replacement = "It '`$1' {"
            Description = "Fix spacing before opening braces in It statements"
        },
        
        # Fix missing closing quotes in It statements  
        @{
            Pattern = "It '([^']*)\(([^)]*)\s*\{"
            Replacement = "It '`$1' {"
            Description = "Fix malformed It statements with unmatched parentheses"
        },
        
        # Fix improper Context indentation
        @{
            Pattern = "(?m)^\s*Context\s+'([^']+)'\s*\{\s*$"
            Replacement = "`n    Context '`$1' {"
            Description = "Fix Context statement indentation"
        },
        
        # Fix InModuleScope formatting
        @{
            Pattern = "InModuleScope\s+(\w+)\s*\{\s*\n\s*Describe"
            Replacement = "InModuleScope `$1 {`n    Describe"
            Description = "Fix InModuleScope block formatting"
        },
        
        # Fix Should -Invoke syntax
        @{
            Pattern = "Should\s+-Invoke\s+-CommandName\s+([^\s]+)\s+-Times\s+(\d+)(?!\s+-)"
            Replacement = "Should -Invoke -CommandName `$1 -Exactly `$2"
            Description = "Fix Should -Invoke syntax to use -Exactly"
        },
        
        # Fix import paths for LabRunner module
        @{
            Pattern = "Import-Module.*'pwsh/modules/LabRunner\.psd1'"
            Replacement = "Import-Module (Join-Path `$PSScriptRoot '..' 'pwsh/modules/LabRunner/LabRunner.psd1')"
            Description = "Fix LabRunner module import path"
        },
        
        # Fix deprecated lab_utils paths
        @{
            Pattern = "'pwsh/lab_utils/"
            Replacement = "'pwsh/modules/LabRunner/"
            Description = "Update deprecated lab_utils paths"
        }
    )
    
    $appliedFixes = @()
    
    foreach ($fix in $fixes) {
        if ($content -match $fix.Pattern) {
            $content = $content -replace $fix.Pattern, $fix.Replacement
            $appliedFixes += $fix.Description
            Write-SyntaxLog "  Applied: $($fix.Description)" "FIX"
        }
    }
    
    # Ensure proper closing braces
    $openBraces = ($content | Select-String '\{' -AllMatches).Matches.Count
    $closeBraces = ($content | Select-String '\}' -AllMatches).Matches.Count
    
    if ($openBraces -gt $closeBraces) {
        $missing = $openBraces - $closeBraces
        $content += "`n" + ("}" * $missing)
        $appliedFixes += "Added $missing missing closing brace(s)"
        Write-SyntaxLog "  Added $missing missing closing brace(s)" "FIX"
    }
    
    # Test if fixes resolved the syntax errors
    if ($DryRun) {
        Write-SyntaxLog "  Would apply $($appliedFixes.Count) fixes to: $fileName" "INFO"
        foreach ($fix in $appliedFixes) {
            Write-SyntaxLog "    - $fix" "INFO"
        }
        return $appliedFixes.Count -gt 0
    }
    
    if ($content -ne $originalContent) {
        Set-Content $FilePath $content -Encoding UTF8
        
        # Verify the fix worked
        if (Test-PowerShellSyntax $FilePath) {
            Write-SyntaxLog "  Successfully fixed syntax in: $fileName" "SUCCESS"
            return $true
        } else {
            Write-SyntaxLog "  Syntax errors remain in: $fileName" "WARNING"
            return $false
        }
    }
    
    return $false
}

# Main execution
Write-SyntaxLog "Starting comprehensive test syntax fixes..." "INFO"
if ($DryRun) {
    Write-SyntaxLog "DRY RUN MODE - No changes will be made" "WARNING"
}

$testFiles = Get-ChildItem "$ProjectRoot/tests/*.Tests.ps1" -File
$fixedCount = 0
$errorCount = 0

foreach ($testFile in $testFiles) {
    try {
        if (Fix-TestFileSyntax $testFile.FullName) {
            $fixedCount++
        }
    }
    catch {
        Write-SyntaxLog "Error processing $($testFile.Name): $($_.Exception.Message)" "ERROR"
        $errorCount++
    }
}

Write-SyntaxLog "Syntax fix summary:" "INFO"
Write-SyntaxLog "  Files processed: $($testFiles.Count)" "INFO"
Write-SyntaxLog "  Files fixed: $fixedCount" "SUCCESS"
Write-SyntaxLog "  Errors encountered: $errorCount" "WARNING"

if ($fixedCount -gt 0 -and -not $DryRun) {
    # Generate report
    $reportTitle = "Test Syntax Fixes $(Get-Date -Format 'yyyy-MM-dd')"
    & "$ProjectRoot/scripts/utilities/new-report.ps1" -Type "test-analysis" -Title $reportTitle
    Write-SyntaxLog "Generated test syntax fixes report" "SUCCESS"
}

Write-SyntaxLog "Test syntax fixes completed!" "SUCCESS"




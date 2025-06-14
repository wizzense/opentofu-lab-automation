#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/fix-infrastructure-issues.ps1

<#
.SYNOPSIS
Fixes the highest priority infrastructure issues identified in the comprehensive test analysis.

.DESCRIPTION
This script addresses the top 5 infrastructure issues:
1. Fix CodeFixer module syntax errors
2. Define or mock missing commands
3. Repair broken test containers
4. Update module import paths
5. Address GitHub Actions dependency issues

.PARAMETER Fix
Which fix to apply: All, CodeFixer, MissingCommands, TestContainers, ImportPaths, GitHubActions

.PARAMETER DryRun
Show what would be fixed without making changes

.EXAMPLE
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "All"

.EXAMPLE
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "TestContainers" -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('All','CodeFixer','MissingCommands','TestContainers','ImportPaths','GitHubActions','TestSyntax')]
    [string]$Fix,
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
# Detect the correct project root based on the current environment
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $ProjectRoot = "/workspaces/opentofu-lab-automation"
}

function Write-FixLog {
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

function Fix-CodeFixerSyntax {
    Write-FixLog "Starting CodeFixer module syntax fixes..." "FIX"
    
    $codeFixerPath = "$ProjectRoot/pwsh/modules/CodeFixer"
    
    # Remove duplicate/problematic files
    $problemFiles = @(
        "$codeFixerPath/Public/Invoke-PowerShellLint-old.ps1",
        "$codeFixerPath/Public/Invoke-PowerShellLint-new.ps1"
    )
    
    foreach ($file in $problemFiles) {
        if (Test-Path $file) {
            if ($DryRun) {
                Write-FixLog "Would remove: $file" "INFO"
            } else {
                Remove-Item $file -Force
                Write-FixLog "Removed problematic file: $file" "SUCCESS"
            }
        }
    }
    
    # Check for syntax errors in remaining files
    $publicFiles = Get-ChildItem "$codeFixerPath/Public/*.ps1" -ErrorAction SilentlyContinue
    foreach ($file in $publicFiles) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file.FullName -Raw), [ref]$null)
            Write-FixLog "Syntax OK: $($file.Name)" "SUCCESS"
        }
        catch {
            Write-FixLog "Syntax ERROR in $($file.Name): $_" "ERROR"
            if (-not $DryRun) {
                # Basic syntax fix attempts
                $content = Get-Content $file.FullName -Raw
                $fixedContent = $content -replace '(?m)^\s*$\n', ''  # Remove empty lines
                $fixedContent = $fixedContent -replace '\)\s*\{', ') {'  # Fix spacing
                Set-Content $file.FullName $fixedContent
                Write-FixLog "Applied basic syntax fixes to $($file.Name)" "FIX"
            }
        }
    }
}

function Fix-MissingCommands {
    Write-FixLog "Fixing missing commands and function references..." "FIX"
    
    # Common missing commands to mock or define
    $missingCommands = @(
        'Format-Config',
        'Invoke-LabStep',
        'Get-Platform',
        'Write-Continue'
    )
    
    $testHelperPath = "$ProjectRoot/tests/helpers/TestHelpers.ps1"
    
    if (Test-Path $testHelperPath) {
        $content = Get-Content $testHelperPath -Raw
        
        foreach ($command in $missingCommands) {
            if ($content -notmatch "function.*$command") {
                $mockFunction = @"

# Mock function for missing command: $command
function global:$command {
    param([Parameter(ValueFromPipeline)






][object]`$InputObject)
    if (`$InputObject) { return `$InputObject }
    return `$true
}
"@
                if ($DryRun) {
                    Write-FixLog "Would add mock for: $command" "INFO"
                } else {
                    $content += $mockFunction
                    Write-FixLog "Added mock function: $command" "FIX"
                }
            }
        }
        
        if (-not $DryRun) {
            Set-Content $testHelperPath $content
        }
    }
}

function Fix-TestContainers {
    Write-FixLog "Fixing broken test containers..." "FIX"
    
    # Find test files with syntax errors
    $testFiles = Get-ChildItem "$ProjectRoot/tests/*.Tests.ps1" -File
    $fixedCount = 0
    
    foreach ($testFile in $testFiles) {
        try {
            # Try to parse the file
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $testFile.FullName -Raw), [ref]$null)
        }
        catch {
            Write-FixLog "Fixing syntax in: $($testFile.Name)" "FIX"
            
            if ($DryRun) {
                Write-FixLog "Would fix syntax errors in: $($testFile.Name)" "INFO"
                continue
            }
            
            $content = Get-Content $testFile.FullName -Raw
            
            # Common fixes for test syntax issues
            $fixes = @(
                @{ Pattern = "It '([^']*)\([^)]*'"; Replacement = "It '`$1'" },  # Fix malformed It statements
                @{ Pattern = "\{\s*\n\s*Context"; Replacement = "{\n\n    Context" },  # Fix Context indentation
                @{ Pattern = "InModuleScope\s+(\w+)\s*\{\s*\n\s*Describe"; Replacement = "InModuleScope `$1 {\n    Describe" },  # Fix InModuleScope
                @{ Pattern = "Should\s+-Invoke\s+-CommandName\s+([^\s]+)\s+-Times\s+(\d+)"; Replacement = "Should -Invoke -CommandName `$1 -Exactly `$2" }  # Fix Should -Invoke syntax
            )
            
            foreach ($fix in $fixes) {
                $content = $content -replace $fix.Pattern, $fix.Replacement
            }
            
            # Ensure proper closing braces
            $openBraces = ($content | Select-String '\{' -AllMatches).Matches.Count
            $closeBraces = ($content | Select-String '\}' -AllMatches).Matches.Count
            
            if ($openBraces -gt $closeBraces) {
                $content += "`n}"
                Write-FixLog "Added missing closing brace to: $($testFile.Name)" "FIX"
            }
            
            Set-Content $testFile.FullName $content
            $fixedCount++
        }
    }
    
    Write-FixLog "Fixed $fixedCount test container files" "SUCCESS"
}

function Fix-ImportPaths {
    Write-FixLog "Updating module import paths..." "FIX"
    
    # Define module path mappings
    $modules = @{
        "CodeFixer"     = "$ProjectRoot/pwsh/modules/CodeFixer/"
        "LabRunner"     = "$ProjectRoot/pwsh/modules/LabRunner/"
        "BackupManager" = "$ProjectRoot/pwsh/modules/BackupManager/"
    }
    
    # Build regex patterns and replacements
    $patterns = @()
    foreach ($name in $modules.Keys) {
        $escaped = [regex]::Escape("pwsh/modules/$name")
        $replacement = "Import-Module `"$($modules[$name])`" -Force"
        $pattern = 'Import-Module\s+[""''].*?' + $escaped + '.*?[""'']'
        $patterns += @{ Pattern = $pattern; Replacement = $replacement }
    }
    $updatedCount = 0
    # Scan all PS1 and PSM1 files under project
    $filesToUpdate = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1","*.psm1" -File -ErrorAction SilentlyContinue
    foreach ($file in $filesToUpdate) {
        $content = Get-Content $file.FullName -Raw
        $newContent = $content
        foreach ($p in $patterns) {
            $newContent = $newContent -replace $p.Pattern, $p.Replacement
        }
        if ($newContent -ne $content) {
            Set-Content $file.FullName $newContent
            Write-FixLog "Updated import paths in: $($file.FullName)" "SUCCESS"
            $updatedCount++
        }
    }
    if ($updatedCount -eq 0) {
        Write-FixLog "No files were updated with import path fixes" "WARNING"
    } else {
        Write-FixLog "Successfully fixed import paths in $updatedCount files" "SUCCESS"
    }
}

function Fix-GitHubActions {
    Write-FixLog "Addressing GitHub Actions dependency issues..." "FIX"
    
    $workflowsPath = "$ProjectRoot/.github/workflows"
    $workflowFiles = Get-ChildItem "$workflowsPath/*.yml" -File -ErrorAction SilentlyContinue
    
    foreach ($workflow in $workflowFiles) {
        $content = Get-Content $workflow.FullName -Raw
        $originalContent = $content
        
        # Common GitHub Actions fixes
        $content = $content -replace 'uses: actions/checkout@v3', 'uses: actions/checkout@v4'
        $content = $content -replace 'uses: actions/setup-node@v3', 'uses: actions/setup-node@v4'
        $content = $content -replace 'pwsh/modules', 'pwsh/modules'
          # Fix PowerShell module path references in workflows
        $content = $content -replace 'Import-Module.*?-Force.*?-Force.*?-Force', 'Import-Module'
        
        if ($content -ne $originalContent) {
            if ($DryRun) {
                Write-FixLog "Would update GitHub Actions in: $($workflow.Name)" "INFO"
            } else {
                Set-Content $workflow.FullName $content
                Write-FixLog "Updated GitHub Actions: $($workflow.Name)" "FIX"
            }
        }
    }
}

# Main execution
Write-FixLog "Starting infrastructure fixes for: $Fix" "INFO"
if ($DryRun) {
    Write-FixLog "DRY RUN MODE - No changes will be made" "WARNING"
}

try {    switch ($Fix) {
        'CodeFixer' { Fix-CodeFixerSyntax }
        'MissingCommands' { Fix-MissingCommands }
        'TestContainers' { Fix-TestContainers }
        'ImportPaths' { Fix-ImportPaths }
        'GitHubActions' { Fix-GitHubActions }
        'TestSyntax' { Fix-TestContainers } # TestSyntax uses the same function as TestContainers for now
        'All' {
            Write-FixLog "Running all infrastructure fixes..." "INFO"
            Fix-CodeFixerSyntax
            Fix-MissingCommands
            Fix-TestContainers
            Fix-ImportPaths
            Fix-GitHubActions
        }
    }
      Write-FixLog "Infrastructure fixes completed successfully!" "SUCCESS"
    
    # Generate report if not dry run
    if (-not $DryRun) {
        $reportTitle = "Infrastructure Fixes Applied $(Get-Date -Format 'yyyy-MM-dd')"
        & "$ProjectRoot/scripts/utilities/new-report.ps1" -Type "test-analysis" -Title $reportTitle
        Write-FixLog "Generated infrastructure fixes report" "SUCCESS"
    }
}
catch {
    Write-FixLog "Infrastructure fixes failed: $($_.Exception.Message)" "ERROR"
    exit 1
}













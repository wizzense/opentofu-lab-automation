# PowerShell Script Template and Validation System
# This prevents the Param/Import-Module ordering issue permanently

$ErrorActionPreference = 'Stop'

Write-Host "=== PowerShell Script Validation & Template System ===" -ForegroundColor Cyan

# 1. Create a proper script template
$scriptTemplate = @'
#Requires -Version 5.1
<#
.SYNOPSIS
    Brief description of the script

.DESCRIPTION
    Detailed description of what this script does

.PARAMETER Config
    Configuration object containing script parameters

.EXAMPLE
    .\ScriptName.ps1 -Config $config

.NOTES
    Author: OpenTofu Lab Automation
    Created: {DATE}
#>

Param(
    [Parameter(Mandatory = $true)]
    [object]$Config
)

# Import required modules AFTER Param block
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1" -Force

Write-CustomLog "Starting $($MyInvocation.MyCommand)"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
    
    # Your script logic here
    
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
'@

# 2. Save the template
$templatePath = "pwsh/ScriptTemplate.ps1"
$scriptTemplate -replace '{DATE}', (Get-Date -Format 'yyyy-MM-dd') | Set-Content $templatePath

Write-Host "✅ Created script template: $templatePath" -ForegroundColor Green

# 3. Create comprehensive validation function
$validationScript = @'
#Requires -Version 5.1
<#
.SYNOPSIS
    Validates PowerShell scripts for syntax and common issues

.DESCRIPTION
    Comprehensive validation that checks:
    - PowerShell syntax parsing
    - Param block positioning
    - Import-Module positioning
    - Required elements presence

.PARAMETER Path
    Path to script file or directory to validate

.PARAMETER Fix
    Automatically fix common issues when possible

.EXAMPLE
    Validate-PowerShellScript -Path "pwsh/runner_scripts" -Fix
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [switch]$Fix
)

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    try {
        $content = Get-Content $FilePath -Raw
        $tokens = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
        return @{ IsValid = $true; Error = $null }
    } catch {
        return @{ IsValid = $false; Error = $_.Exception.Message }
    }
}

function Test-ParamBlockPosition {
    param([string]$FilePath)
    
    $lines = Get-Content $FilePath
    $firstExecutableLine = -1
    $paramLineIndex = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        
        # Skip comments and empty lines
        if ($line -eq '' -or $line.StartsWith('#') -or $line.StartsWith('<#')) {
            continue
        }
        
        if ($firstExecutableLine -eq -1) {
            $firstExecutableLine = $i
        }
        
        if ($line.StartsWith('Param(')) {
            $paramLineIndex = $i
            break
        }
    }
    
    if ($paramLineIndex -eq -1) {
        return @{ IsValid = $false; Error = "No Param block found" }
    }
    
    if ($paramLineIndex -ne $firstExecutableLine) {
        return @{ IsValid = $false; Error = "Param block is not the first executable statement" }
    }
    
    return @{ IsValid = $true; Error = $null }
}

function Test-ImportModulePosition {
    param([string]$FilePath)
    
    $lines = Get-Content $FilePath
    $paramEndIndex = -1
    $importIndex = -1
    
    # Find Param block end
    $parenCount = 0
    $inParam = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        if ($line -match "^Param\(") {
            $inParam = $true
        }
        
        if ($inParam) {
            $parenCount += ($line.Split('(').Count - 1)
            $parenCount -= ($line.Split(')').Count - 1)
            
            if ($parenCount -eq 0) {
                $paramEndIndex = $i
                break
            }
        }
    }
    
    # Find Import-Module
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "Import-Module.*LabRunner.*-Force") {
            $importIndex = $i
            break
        }
    }
    
    if ($importIndex -ne -1 -and $paramEndIndex -ne -1 -and $importIndex -lt $paramEndIndex) {
        return @{ IsValid = $false; Error = "Import-Module comes before Param block" }
    }
    
    return @{ IsValid = $true; Error = $null }
}

function Repair-ScriptStructure {
    param([string]$FilePath)
    
    Write-Host "  🔧 Attempting to fix: $FilePath" -ForegroundColor Yellow
    
    $lines = Get-Content $FilePath
    $newLines = @()
    $importLine = ""
    $paramStart = -1
    $paramEnd = -1
    
    # Extract Import-Module line and find Param block
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^Import-Module.*LabRunner.*-Force") {
            $importLine = $lines[$i]
            continue # Skip this line
        }
        
        if ($lines[$i] -match "^Param\(") {
            $paramStart = $i
        }
        
        $newLines += $lines[$i]
    }
    
    # Find Param block end
    if ($paramStart -ne -1) {
        $parenCount = 0
        $inParam = $false
        
        for ($i = $paramStart; $i -lt $newLines.Count; $i++) {
            $line = $newLines[$i]
            
            if ($line -match "^Param\(") {
                $inParam = $true
            }
            
            if ($inParam) {
                $parenCount += ($line.Split('(').Count - 1)
                $parenCount -= ($line.Split(')').Count - 1)
                
                if ($parenCount -eq 0) {
                    $paramEnd = $i
                    break
                }
            }
        }
        
        # Insert Import-Module after Param block
        if ($paramEnd -ne -1 -and $importLine -ne "") {
            $finalLines = @()
            $finalLines += $newLines[0..$paramEnd]
            $finalLines += $importLine
            if ($paramEnd + 1 -lt $newLines.Count) {
                $finalLines += $newLines[($paramEnd + 1)..($newLines.Count - 1)]
            }
            
            Set-Content -Path $FilePath -Value ($finalLines -join "`n") -NoNewline
            return $true
        }
    }
    
    return $false
}

# Main validation logic
$totalFiles = 0
$validFiles = 0
$fixedFiles = 0
$errorFiles = @()

if (Test-Path $Path -PathType Container) {
    $files = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse
} else {
    $files = @(Get-Item $Path)
}

Write-Host "Validating $($files.Count) PowerShell files..." -ForegroundColor White

foreach ($file in $files) {
    $totalFiles++
    Write-Host "Checking: $($file.Name)" -ForegroundColor Gray
    
    $allValid = $true
    
    # Test 1: Basic PowerShell syntax
    $syntaxTest = Test-PowerShellSyntax -FilePath $file.FullName
    if (-not $syntaxTest.IsValid) {
        Write-Host "  ❌ Syntax Error: $($syntaxTest.Error)" -ForegroundColor Red
        $allValid = $false
    }
    
    # Test 2: Param block position
    $paramTest = Test-ParamBlockPosition -FilePath $file.FullName
    if (-not $paramTest.IsValid) {
        Write-Host "  ❌ Param Position Error: $($paramTest.Error)" -ForegroundColor Red
        $allValid = $false
    }
    
    # Test 3: Import-Module position
    $importTest = Test-ImportModulePosition -FilePath $file.FullName
    if (-not $importTest.IsValid) {
        Write-Host "  ❌ Import Position Error: $($importTest.Error)" -ForegroundColor Red
        $allValid = $false
        
        if ($Fix) {
            if (Repair-ScriptStructure -FilePath $file.FullName) {
                Write-Host "  ✅ FIXED: Script structure corrected" -ForegroundColor Green
                $fixedFiles++
                $allValid = $true
            }
        }
    }
    
    if ($allValid) {
        Write-Host "  ✅ Valid" -ForegroundColor Green
        $validFiles++
    } else {
        $errorFiles += $file.FullName
    }
}

Write-Host "`n=== Validation Summary ===" -ForegroundColor Cyan
Write-Host "Total files: $totalFiles" -ForegroundColor White
Write-Host "Valid files: $validFiles" -ForegroundColor Green
Write-Host "Fixed files: $fixedFiles" -ForegroundColor Yellow
Write-Host "Error files: $($errorFiles.Count)" -ForegroundColor Red

if ($errorFiles.Count -gt 0) {
    Write-Host "`nFiles with errors:" -ForegroundColor Red
    $errorFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "`n🎯 All PowerShell scripts are valid!" -ForegroundColor Green -BackgroundColor Black
    exit 0
}
'@

# Save validation script
Set-Content -Path "tools/Validate-PowerShellScripts.ps1" -Value $validationScript

Write-Host "✅ Created validation script: tools/Validate-PowerShellScripts.ps1" -ForegroundColor Green

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Run validation: pwsh tools/Validate-PowerShellScripts.ps1 -Path pwsh/runner_scripts" -ForegroundColor White
Write-Host "2. Auto-fix issues: pwsh tools/Validate-PowerShellScripts.ps1 -Path pwsh/runner_scripts -Fix" -ForegroundColor White
Write-Host "3. Use template for new scripts: pwsh/ScriptTemplate.ps1" -ForegroundColor White

# AutomaticFixCapture.ps1
# Captures and automates common manual fixes found during testing

function Invoke-AutomaticFixCapture {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = (Get-Location),
        [switch]$AnalyzeOnly,
        [switch]$AutoFix
    )
    
    Write-Host "🔍 Scanning for common issues that need automated fixes..." -ForegroundColor Cyan
    
    $issues = @()
    
    # 1. Check for corrupted parameter syntax (like we just fixed)
    $corruptedParams = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match '\[Parameter\([^\]]*\n.*?if \(-not \(Get-Module.*?PSScriptAnalyzer.*?\]\[') {
            [PSCustomObject]@{
                Type = "CorruptedParameter"
                File = $_.FullName
                Issue = "Parameter syntax corrupted with PSScriptAnalyzer import"
            }
        }
    }
    $issues += $corruptedParams
    
    # 2. Check for missing module imports in tests
    $missingImports = Get-ChildItem -Path "$ProjectRoot/tests" -Recurse -Include "*.Tests.ps1" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match 'pwsh/lab_utils' -and $content -notmatch 'pwsh/modules/LabRunner') {
            [PSCustomObject]@{
                Type = "OutdatedImport"
                File = $_.FullName
                Issue = "Still using old lab_utils path instead of pwsh/modules/LabRunner"
            }
        }
    }
    $issues += $missingImports
    
    # 3. Check for undefined commands (like 'errors')
    $undefinedCommands = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match '\$errors\s*=\s*errors\b' -or $content -match '^errors\b') {
            [PSCustomObject]@{
                Type = "UndefinedCommand"
                File = $_.FullName
                Issue = "References undefined 'errors' command"
            }
        }
    }
    $issues += $undefinedCommands
    
    # 4. Check for missing closing braces/brackets
    $syntaxErrors = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1" | ForEach-Object {
        try {
            $tokens = $null
            $parseErrors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors)
            if ($parseErrors.Count -gt 0) {
                foreach ($error in $parseErrors) {
                    [PSCustomObject]@{
                        Type = "SyntaxError"
                        File = $_.FullName
                        Issue = $error.Message
                        Line = $error.Extent.StartLineNumber
                    }
                }
            }
        } catch {
            # File might be binary or corrupted
        }
    }
    $issues += $syntaxErrors
    
    Write-Host "📊 Found $($issues.Count) issues to address" -ForegroundColor Yellow
    
    if ($AnalyzeOnly) {
        return $issues | Group-Object Type | ForEach-Object {
            Write-Host "`n$($_.Name): $($_.Count) files" -ForegroundColor Magenta
            $_.Group | ForEach-Object { Write-Host "  - $($_.File): $($_.Issue)" }
        }
    }
    
    if ($AutoFix) {
        Write-Host "🔧 Applying automatic fixes..." -ForegroundColor Green
        
        # Fix corrupted parameters
        $corruptedParams | ForEach-Object {
            Write-Host "Fixing corrupted parameter in $($_.File)" -ForegroundColor Yellow
            $content = Get-Content $_.File -Raw
            # Remove the PSScriptAnalyzer import that got inserted into parameter blocks
            $fixed = $content -replace '\[Parameter\(([^\]]*)\n# Auto-added import for PSScriptAnalyzer.*?Import-Module PSScriptAnalyzer -Force\n\]\[', '[Parameter($1)]'
            $fixed = $fixed -replace '\[Parameter\(([^\]]*)\n# Auto-added import for PSScriptAnalyzer.*?Import-Module PSScriptAnalyzer -Force\n\]\s*\[', '[Parameter($1)] ['
            Set-Content -Path $_.File -Value $fixed -NoNewline
        }
        
        # Fix outdated imports
        $missingImports | ForEach-Object {
            Write-Host "Updating import path in $($_.File)" -ForegroundColor Yellow
            $content = Get-Content $_.File -Raw
            $fixed = $content -replace 'pwsh/lab_utils', 'pwsh/modules/LabRunner'
            Set-Content -Path $_.File -Value $fixed -NoNewline
        }
        
        # Fix undefined commands
        $undefinedCommands | ForEach-Object {
            Write-Host "Fixing undefined 'errors' command in $($_.File)" -ForegroundColor Yellow
            $content = Get-Content $_.File -Raw
            # Replace undefined 'errors' with proper error handling
            $fixed = $content -replace '\$errors\s*=\s*errors\b', '$errors = @()'
            $fixed = $fixed -replace '^errors\b', '# errors # TODO: Define this command or remove'
            Set-Content -Path $_.File -Value $fixed -NoNewline
        }
        
        Write-Host "✅ Automatic fixes applied!" -ForegroundColor Green
    }
    
    return $issues
}

# Function to create automated fix rules
function New-AutoFixRule {
    [CmdletBinding()]
    param(
        [string]$RuleName,
        [string]$Pattern,
        [string]$Replacement,
        [string]$Description,
        [string[]]$FileTypes = @("*.ps1"),
        [string]$Scope = "All"
    )
    
    $ruleFile = Join-Path (Split-Path $PSScriptRoot) "AutoFixRules.json"
    
    $rule = @{
        Name = $RuleName
        Pattern = $Pattern
        Replacement = $Replacement
        Description = $Description
        FileTypes = $FileTypes
        Scope = $Scope
        Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    if (Test-Path $ruleFile) {
        $rules = Get-Content $ruleFile | ConvertFrom-Json
        $rules = @($rules) + $rule
    } else {
        $rules = @($rule)
    }
    
    $rules | ConvertTo-Json -Depth 10 | Set-Content $ruleFile
    Write-Host "✅ Auto-fix rule '$RuleName' created" -ForegroundColor Green
}

# Export functions
Export-ModuleMember -Function Invoke-AutomaticFixCapture, New-AutoFixRule

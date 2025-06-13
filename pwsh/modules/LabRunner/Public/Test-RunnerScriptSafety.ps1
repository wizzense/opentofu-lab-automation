#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/pwsh/modules/LabRunner/Public/Test-RunnerScriptSafety.ps1

<#
.SYNOPSIS
Validates runner scripts for safety, security, and compliance

.DESCRIPTION
This module provides comprehensive validation for runner scripts including:
- Security scanning for malicious content
- Syntax validation and auto-fixing
- Configuration compliance checking
- Deployment readiness validation

.PARAMETER ScriptPath
Path to the runner script to validate

.PARAMETER AutoFix
Attempt to automatically fix issues when possible

.EXAMPLE
Test-RunnerScriptSafety -ScriptPath "./runner_scripts/0999_NewScript.ps1"
#>

function Test-RunnerScriptName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $fileName = Split-Path $ScriptPath -Leaf
    $errors = @()
    
    # Check file extension
    if (-not $fileName.EndsWith('.ps1')) {
        $errors += "Invalid file extension. Runner scripts must end with .ps1"
    }
    
    # Check for spaces
    if ($fileName -match '\s') {
        $errors += "Invalid script name. Spaces not allowed in runner script names"
    }
    
    # Check for special characters (allow only alphanumeric, hyphens, underscores)
    if ($fileName -match '[^a-zA-Z0-9\-_\.]') {
        $errors += "Invalid characters in script name. Only alphanumeric, hyphens, and underscores allowed"
    }
    
    # Check for sequence number (should start with 4 digits)
    if ($fileName -notmatch '^\d{4}_') {
        $errors += "Missing sequence number. Runner scripts should start with a 4-digit sequence number followed by underscore"
    }
    
    if ($errors.Count -gt 0) {
        throw "Invalid script name: $($errors -join '; ')"
    }
    
    return $true
}

function Test-RunnerScriptSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script file not found: $ScriptPath"
    }
    
    $content = Get-Content $ScriptPath -Raw
    $errors = @()
    
    # Check for dangerous commands
    $dangerousPatterns = @(
        'Remove-Item.*-Recurse.*-Force',
        'Format-Volume',
        'Clear-Host.*cls',
        'Invoke-Expression.*\$\(',
        'iex\s+\$',
        'Start-Process.*\.exe.*-Wait.*-NoNewWindow',
        'Invoke-WebRequest.*\.exe',
        'curl.*\.exe',
        'wget.*\.exe'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($content -match $pattern) {
            $errors += "Potentially dangerous command detected: $pattern"
        }
    }
    
    # Check for hardcoded credentials
    $credentialPatterns = @(
        'password\s*=\s*["\x27][^"\x27]{3,}["\x27]',
        'apikey\s*=\s*["\x27][a-zA-Z0-9]{20,}["\x27]',
        'connectionstring.*password\s*=',
        'secret\s*=\s*["\x27][^"\x27]{10,}["\x27]'
    )
    
    foreach ($pattern in $credentialPatterns) {
        if ($content -match $pattern) {
            $errors += "Hardcoded credentials detected"
            break  # Don't report multiple credential issues
        }
    }
    
    # Check for suspicious network access
    $suspiciousDomains = @(
        'bit\.ly', 'tinyurl\.com', 'raw\.githubusercontent\.com',
        '\.tk$', '\.ml$', '\.ga$', '\.cf$',  # Free domains often used for malware
        'malware', 'bitcoin', 'crypto', 'miner'
    )
    
    foreach ($domain in $suspiciousDomains) {
        if ($content -match $domain) {
            $errors += "Suspicious network access detected: $domain"
        }
    }
    
    if ($errors.Count -gt 0) {
        throw "Security validation failed: $($errors -join '; ')"
    }
    
    return $true
}

function Test-RunnerScriptSyntax {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $result = @{
        HasErrors = $false
        Errors = @()
        CanAutoFix = $false
    }
    
    try {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
        
        if ($parseErrors.Count -gt 0) {
            $result.HasErrors = $true
            $result.Errors = $parseErrors | ForEach-Object { $_.Message }
            
            # Check if these are auto-fixable errors
            $autoFixablePatterns = @(
                'Missing closing', 'Expected', 'Unexpected token'
            )
            
            $result.CanAutoFix = $result.Errors | Where-Object { 
                $error = $_
                $autoFixablePatterns | Where-Object { $error -match $_ }
            }
        }
    }
    catch {
        $result.HasErrors = $true
        $result.Errors = @($_.Exception.Message)
        $result.CanAutoFix = $false
    }
    
    return $result
}

function Test-RunnerScriptEncoding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    try {
        # Try to read the file as UTF-8
        $content = Get-Content $ScriptPath -Encoding UTF8 -ErrorAction Stop
        
        # Check for BOM issues or invalid characters
        $bytes = [System.IO.File]::ReadAllBytes($ScriptPath)
        
        # Check for UTF-8 BOM (should not be present for PowerShell scripts)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Warning "UTF-8 BOM detected. This may cause issues with PowerShell execution."
        }
        
        # Check for null bytes or other binary content
        if ($bytes -contains 0x00) {
            throw "Invalid encoding: File contains null bytes"
        }
        
        return $true
    }
    catch {
        throw "Invalid encoding: $($_.Exception.Message)"
    }
}

function Test-RunnerScriptSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $file = Get-Item $ScriptPath
    $sizeKB = [math]::Round($file.Length / 1KB, 2)
    
    $result = @{
        SizeKB = $sizeKB
        SizeWarning = $false
        RecommendSplit = $false
    }
    
    if ($sizeKB -gt 100) {  # 100KB threshold
        $result.SizeWarning = $true
        $result.RecommendSplit = $true
    }
    elseif ($sizeKB -gt 50) {  # 50KB threshold
        $result.SizeWarning = $true
    }
    
    return $result
}

function Test-RunnerScriptParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $result = @{
        HasParameterErrors = $false
        CanAutoFix = $false
        Errors = @()
    }
    
    try {
        $content = Get-Content $ScriptPath -Raw
        
        # Check if script has parameter block
        if ($content -match 'Param\s*\(') {
            # Parse the parameter block for issues
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$parseErrors)
            
            # Look for parameter validation issues
            $paramBlock = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.ParamBlockAst]}, $true)
            
            if ($paramBlock) {
                foreach ($param in $paramBlock.Parameters) {
                    # Check for invalid parameter attributes
                    foreach ($attribute in $param.Attributes) {
                        if ($attribute.TypeName.Name -eq 'Parameter') {
                            # Check for invalid Parameter attribute properties
                            foreach ($namedArg in $attribute.NamedArguments) {
                                $validProperties = @('Mandatory', 'Position', 'ValueFromPipeline', 'ValueFromPipelineByPropertyName', 'ValueFromRemainingArguments', 'HelpMessage', 'DontShow', 'ParameterSetName')
                                if ($namedArg.ArgumentName -notin $validProperties) {
                                    $result.HasParameterErrors = $true
                                    $result.Errors += "Invalid Parameter attribute property: $($namedArg.ArgumentName)"
                                    $result.CanAutoFix = $true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        $result.HasParameterErrors = $true
        $result.Errors += $_.Exception.Message
    }
    
    return $result
}

function Test-RunnerScriptConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $content = Get-Content $ScriptPath -Raw
    
    $result = @{
        UsesConfiguration = $false
        NeedsConfigSupport = $false
        HasConfigParameter = $false
    }
    
    # Check if script uses $Config parameter
    if ($content -match '\$Config\.' -or $content -match 'Param\([^)]*\$Config') {
        $result.UsesConfiguration = $true
        $result.HasConfigParameter = $true
    }
    
    # Check if script needs configuration support (has hardcoded values that should be configurable)
    $needsConfigPatterns = @(
        'C:\\',  # Hardcoded Windows paths
        'Program Files',
        'localhost',
        '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',  # IP addresses
        'http://[^"'']+',  # Hardcoded URLs
        'https://[^"'']+'
    )
    
    foreach ($pattern in $needsConfigPatterns) {
        if ($content -match $pattern) {
            $result.NeedsConfigSupport = $true
            break
        }
    }
    
    return $result
}

function Invoke-RunnerScriptAutoFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $result = @{
        FixesApplied = 0
        NewSyntaxValid = $false
        FixDetails = @()
    }
    
    try {
        # Import CodeFixer module for advanced fixing
        Import-Module "$PSScriptRoot/../../CodeFixer/CodeFixer.psm1" -Force -ErrorAction SilentlyContinue
        
        $originalContent = Get-Content $ScriptPath -Raw
        $newContent = $originalContent
        
        # Fix 1: Add missing parameter block with Config parameter
        if ($newContent -notmatch 'Param\s*\(') {
            $paramBlock = @"
Param(
    [Parameter()]
    [object]`$Config
)

"@
            $newContent = $paramBlock + $newContent
            $result.FixesApplied++
            $result.FixDetails += "Added missing parameter block with Config parameter"
        }
        
        # Fix 2: Add basic error handling if missing
        if ($newContent -notmatch 'try\s*\{' -and $newContent -notmatch '\$ErrorActionPreference') {
            # Add error handling wrapper
            $lines = $newContent -split "`n"
            $paramEndIndex = -1
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*\)\s*$' -and $paramEndIndex -eq -1) {
                    $paramEndIndex = $i
                    break
                }
            }
            
            if ($paramEndIndex -gt -1) {
                $errorHandlingInsert = @"

`$ErrorActionPreference = "Stop"

try {
"@
                $lines = $lines[0..$paramEndIndex] + $errorHandlingInsert.Split("`n") + $lines[($paramEndIndex + 1)..($lines.Count - 1)] + @("}", "catch {", "    Write-Error `"Script failed: `$(`$_.Exception.Message)`"", "    exit 1", "}")
                $newContent = $lines -join "`n"
                $result.FixesApplied++
                $result.FixDetails += "Added basic error handling"
            }
        }
        
        # Apply CodeFixer if available
        if (Get-Command Invoke-PowerShellLint -ErrorAction SilentlyContinue) {
            try {
                $tempFile = "$env:TEMP/runner_script_temp.ps1"
                $newContent | Out-File $tempFile -Encoding UTF8
                
                # Run linting to identify issues
                $lintResult = Invoke-PowerShellLint -Path $tempFile -PassThru
                if ($lintResult.Issues.Count -gt 0) {
                    $result.FixDetails += "CodeFixer identified $($lintResult.Issues.Count) linting issues"
                }
                
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "CodeFixer integration failed: $($_.Exception.Message)"
            }
        }
        
        # Write back the fixed content
        if ($newContent -ne $originalContent) {
            $newContent | Out-File $ScriptPath -Encoding UTF8
            
            # Validate the new syntax
            try {
                $tokens = $null
                $parseErrors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
                $result.NewSyntaxValid = $parseErrors.Count -eq 0
            }
            catch {
                $result.NewSyntaxValid = $false
            }
        }
        else {
            $result.NewSyntaxValid = $true  # No changes needed
        }
    }
    catch {
        Write-Error "Auto-fix failed: $($_.Exception.Message)"
    }
    
    return $result
}

function Invoke-CodeFixerOnRunnerScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $result = @{
        LintIssuesFound = 0
        AutoFixesApplied = 0
        RemainingIssues = 0
    }
    
    try {
        # Import CodeFixer module
        Import-Module "$PSScriptRoot/../../CodeFixer/CodeFixer.psm1" -Force -ErrorAction SilentlyContinue
        
        if (Get-Command Invoke-PowerShellLint -ErrorAction SilentlyContinue) {
            $lintResult = Invoke-PowerShellLint -Path $ScriptPath -PassThru
            $result.LintIssuesFound = $lintResult.Issues.Count
            
            # Apply automatic fixes if available
            if (Get-Command Invoke-AutoFixCapture -ErrorAction SilentlyContinue) {
                $fixResult = Invoke-AutoFixCapture -FilePath $ScriptPath
                $result.AutoFixesApplied = $fixResult.FixesApplied
            }
            
            # Re-run linting to see remaining issues
            $postFixLintResult = Invoke-PowerShellLint -Path $ScriptPath -PassThru
            $result.RemainingIssues = $postFixLintResult.Issues.Count
        }
    }
    catch {
        Write-Warning "CodeFixer integration failed: $($_.Exception.Message)"
    }
    
    return $result
}

function Invoke-RunnerScriptDeploymentValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $errors = @()
    
    # Run all validation checks
    try {
        Test-RunnerScriptName $ScriptPath
    }
    catch {
        $errors += "Name validation: $($_.Exception.Message)"
    }
    
    try {
        Test-RunnerScriptSafety $ScriptPath
    }
    catch {
        $errors += "Security validation: $($_.Exception.Message)"
    }
    
    $syntaxResult = Test-RunnerScriptSyntax $ScriptPath
    if ($syntaxResult.HasErrors) {
        $errors += "Syntax validation: $($syntaxResult.Errors -join '; ')"
    }
    
    if ($errors.Count -gt 0) {
        throw "Failed security validation: $($errors -join '; ')"
    }
    
    return $true
}

function Test-RunnerScriptDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )
    
    $content = Get-Content $ScriptPath -Raw
    
    $result = @{
        RequiresApproval = $false
        Reason = ""
        AutoDeployable = $true
    }
    
    # Check for external dependencies
    $externalDepPatterns = @(
        'Install-Module\s+[^-]',
        'Invoke-WebRequest',
        'curl\s+',
        'wget\s+',
        'chocolatey',
        'npm install',
        'pip install'
    )
    
    foreach ($pattern in $externalDepPatterns) {
        if ($content -match $pattern) {
            $result.RequiresApproval = $true
            $result.AutoDeployable = $false
            $result.Reason = "External dependencies detected"
            break
        }
    }
    
    # Check for system modification commands
    $systemModPatterns = @(
        'Set-ExecutionPolicy',
        'New-ItemProperty.*Registry',
        'Set-ItemProperty.*Registry',
        'Enable-WindowsOptionalFeature',
        'Disable-WindowsOptionalFeature'
    )
    
    foreach ($pattern in $systemModPatterns) {
        if ($content -match $pattern) {
            $result.RequiresApproval = $true
            $result.AutoDeployable = $false
            $result.Reason = "System modification commands detected"
            break
        }
    }
    
    return $result
}

# Functions are automatically available when dot-sourced

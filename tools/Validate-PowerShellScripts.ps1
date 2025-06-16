# tools/Validate-PowerShellScripts.ps1

<#
.SYNOPSIS
    Comprehensive PowerShell script validation and auto-fix system
.DESCRIPTION
    Validates PowerShell scripts for syntax errors, parameter/import-module ordering,
    and other common issues. Can automatically fix detected problems.
.PARAMETER Path
    Path to validate (file or directory)
.PARAMETER AutoFix
    Automatically fix detected issues
.PARAMETER CI
    CI mode - stricter validation and non-interactive
.EXAMPLE
    .\Validate-PowerShellScripts.ps1 -Path "pwsh/runner_scripts" -AutoFix
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)





]
    [string]$Path = ".",
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoFix,
    
    [Parameter(Mandatory = $false)]
    [switch]$CI,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipSyntaxCheck
)

# Import the shared logging module
Import-Module "/pwsh/modules/CodeFixerLogging/" -Force

# Initialize results tracking
$script:Results = @{
    TotalFiles = 0
    ValidFiles = 0
    FixedFiles = 0
    ErrorFiles = 0
    Issues = @()
}

function Write-ValidationMessage {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    






$timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        "Fix" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host "$Message" -ForegroundColor $color
}

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    






try {
        $content = Get-Content $FilePath -Raw
        
        # Preprocess content to handle GitHub Actions syntax
        $processedContent = Preprocess-ContentForValidation -Content $content -FilePath $FilePath
        
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize($processedContent, [ref]$errors)
        
        if ($errors.Count -gt 0) {
            return @{
                IsValid = $false
                Errors = $errors
            }
        }
        
        return @{ IsValid = $true; Errors = @() }
    }
    catch {
        return @{
            IsValid = $false
            Errors = @(@{ Message = $_.Exception.Message; Line = 0; Column = 0 })
        }
    }
}

function Test-ParameterImportOrder {
    param([string]$FilePath)
    
    






try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        $lines = Get-Content $FilePath -ErrorAction Stop
        
        # Check for null or empty content
        if ([string]::IsNullOrWhiteSpace($content)) {
            return @()
        }
        
        # Find Param block and Import-Module statements
        $paramMatch = [regex]::Match($content, '(?m)^\s*Param\s*\(', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $importMatches = [regex]::Matches($content, '(?m)^\s*Import-Module\s+"/pwsh/modules/CodeFixer(LabRunner|CodeFixer|BackupManager)/"', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        $issues = @()
    } catch {
        Write-Warning "Error reading file ${FilePath}: $($_.Exception.Message)"
        return @()
    }
    
    if ($paramMatch.Success -and $importMatches.Count -gt 0) {
        $paramLine = ($content.Substring(0, $paramMatch.Index) -split "`n").Count
        
        foreach ($import in $importMatches) {
            $importLine = ($content.Substring(0, $import.Index) -split "`n").Count
            if ($importLine -lt $paramLine) {
                $issues += @{
                    Type = "ParameterOrderError"
                    Message = "Import-Module statement at line $importLine comes before Param block at line $paramLine"
                    Line = $importLine
                    Severity = "Error"
                }
            }
        }
    }
    
    return $issues
}

function Fix-ParameterImportOrder {
    param([string]$FilePath)
    
    






try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        $lines = Get-Content $FilePath -ErrorAction Stop
        
        # Check for null or empty content
        if ([string]::IsNullOrWhiteSpace($content)) {
            return $false
        }
    
    # Extract Param block
    $paramMatch = [regex]::Match($content, '(?ms)^\s*Param\s*\([^}]*\}?\s*\)', [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $paramMatch.Success) {
        $paramMatch = [regex]::Match($content, '(?ms)^\s*Param\s*\([^)]*\)', [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    }
    
    # Find Import-Module statements before Param
    $importMatches = [regex]::Matches($content, '(?m)^.*Import-Module\s+[^`r`n]*', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    if ($paramMatch.Success -and $importMatches.Count -gt 0) {
        $paramLine = ($content.Substring(0, $paramMatch.Index) -split "`n").Count
        $importsToMove = @()
        
        foreach ($import in $importMatches) {
            $importLine = ($content.Substring(0, $import.Index) -split "`n").Count
            if ($importLine -lt $paramLine) {
                $importsToMove += $import.Value.Trim()
            }
        }
        
        if ($importsToMove.Count -gt 0) {
            # Remove imports from original positions
            $newContent = $content
            foreach ($import in $importMatches) {
                $importLine = ($content.Substring(0, $import.Index) -split "`n").Count
                if ($importLine -lt $paramLine) {
                    $newContent = $newContent -replace [regex]::Escape($import.Value), ""
                }
            }
            
            # Add imports after Param block
            $paramEndIndex = $paramMatch.Index + $paramMatch.Length
            $newContent = $newContent.Insert($paramEndIndex, "`n" + ($importsToMove -join "`n"))
            
            Set-Content -Path $FilePath -Value $newContent -NoNewline
            return $true
        }
    }
    
    return $false
    } catch {
        Write-Warning "Error fixing parameter order in ${FilePath}: $($_.Exception.Message)"
        return $false
    }
}

function Test-ScriptStyle {
    param([string]$FilePath)
    
    






$content = Get-Content $FilePath -Raw
    $issues = @()
    
    # Check for proper comment-based help
    if ($content -notmatch '(?ms)<#[\s\S]*?\.SYNOPSIS[\s\S]*?#>') {
        $issues += @{
            Type = "MissingHelp"
            Message = "Script missing comment-based help with .SYNOPSIS"
            Line = 1
            Severity = "Warning"
        }
    }
    
    # Check for proper error handling in main logic
    if ($content -match 'Import-Module.*-Force' -and $content -notmatch 'try\s*{[\s\S]*}[\s\S]*catch') {
        $issues += @{
            Type = "MissingErrorHandling"
            Message = "Script with Import-Module should have try/catch error handling"
            Line = 1
            Severity = "Warning"
        }
    }
    
    return $issues
}

function Validate-PowerShellFile {
    param([string]$FilePath)
    
    






Write-ValidationMessage "Validating: $FilePath" "Info"
    $script:Results.TotalFiles++
    
    $allIssues = @()
    $wasFixed = $false
    
    # Test syntax
    if (-not $SkipSyntaxCheck) {
        $syntaxResult = Test-PowerShellSyntax -FilePath $FilePath
        if (-not $syntaxResult.IsValid) {
            foreach ($error in $syntaxResult.Errors) {
                $allIssues += @{
                    Type = "SyntaxError"
                    Message = $error.Message
                    Line = $error.Line
                    Severity = "Error"
                }
            }
        }
    }
    
    # Test parameter/import order
    $orderIssues = Test-ParameterImportOrder -FilePath $FilePath
    $allIssues += $orderIssues
    
    # Test style issues
    $styleIssues = Test-ScriptStyle -FilePath $FilePath
    $allIssues += $styleIssues
    
    # Auto-fix if requested
    if ($AutoFix) {
        # Fix syntax errors first (placeholder for future implementation)
        $syntaxErrors = $allIssues | Where-Object { $_.Type -eq "SyntaxError" }
        if ($syntaxErrors.Count -gt 0) {
            # TODO: Implement Fix-SyntaxErrors function
            Write-ValidationMessage "  SYNTAX ERRORS: $($syntaxErrors.Count) errors found (manual fix required)" "Warning"
        }
        
        # Fix parameter/import order issues
        if ($orderIssues.Count -gt 0) {
            if (Fix-ParameterImportOrder -FilePath $FilePath) {
                Write-ValidationMessage "  FIXED: Parameter/Import-Module ordering" "Fix"
                $wasFixed = $true
                $script:Results.FixedFiles++
                
                # Re-test syntax after fix
                if (-not $SkipSyntaxCheck) {
                    $syntaxResult = Test-PowerShellSyntax -FilePath $FilePath
                    if ($syntaxResult.IsValid) {
                        $allIssues = $allIssues | Where-Object { $_.Type -ne "SyntaxError" -and $_.Type -ne "ParameterOrderError" }
                    }
                } else {
                    $allIssues = $allIssues | Where-Object { $_.Type -ne "ParameterOrderError" }
                }
            }
        }
    }
    
    # Report issues
    foreach ($issue in $allIssues) {
        $level = switch ($issue.Severity) {
            "Error" { "Error" }
            "Warning" { "Warning" }
            default { "Info" }
        }
        Write-ValidationMessage "  $($issue.Type): $($issue.Message)" $level
        
        $script:Results.Issues += @{
            File = $FilePath
            Type = $issue.Type
            Message = $issue.Message
            Line = $issue.Line
            Severity = $issue.Severity
        }
    }
    
    $errorIssues = $allIssues | Where-Object { $_.Severity -eq "Error" }
    if ($errorIssues.Count -eq 0) {
        if (-not $wasFixed) {
            Write-ValidationMessage "   Valid" "Success"
        }
        $script:Results.ValidFiles++
    } else {
        $script:Results.ErrorFiles++
    }
}

function Get-PowerShellFiles {
    param([string]$Path)
    
    






if (Test-Path $Path -PathType Leaf) {
        if ($Path -match '\.ps1$') {
            return @($Path)
        } else {
            return @()
        }
    } elseif (Test-Path $Path -PathType Container) {
        return Get-ChildItem -Path $Path -Recurse -Filter "*.ps1" | ForEach-Object { $_.FullName }
    } else {
        throw "Path not found: $Path"
    }
}

function Should-IgnoreFile {
    param([string]$FilePath)
    
    






$relativePath = $FilePath -replace [regex]::Escape((Get-Location).Path), ""
    $relativePath = $relativePath.TrimStart('\', '/')
    
    # Ignore patterns
    $ignorePatterns = @(
        "archive/",
        "legacy/", 
        "historical-fixes/",
        ".backup",
        "temp/",
        "backup/",
        "/node_modules/",
        ".git/"
    )
    
    # Check if file matches ignore patterns
    foreach ($pattern in $ignorePatterns) {
        if ($relativePath -match [regex]::Escape($pattern)) {
            return $true
        }
    }
    
    return $false
}

function Preprocess-ContentForValidation {
    param([string]$Content, [string]$FilePath)
    
    






# For files that might contain GitHub Actions workflow syntax,
    # temporarily replace ${{ }} expressions to avoid PowerShell parser confusion
    if ($FilePath -match "(TestGenerator|TestAutoFixer)" -or $Content -match "github\.") {
        # Replace GitHub Actions expressions with valid PowerShell syntax for parsing
        $processedContent = $Content -replace '\$\{\{([^}]+)\}\}', '${GH_ACTION_PLACEHOLDER}'
        return $processedContent
    }
    
    return $Content
}

# Main execution
try {
    Write-ValidationMessage "PowerShell Script Validation Started" "Info"
    Write-ValidationMessage "Path: $Path | AutoFix: $AutoFix | CI: $CI" "Info"
    
    $files = Get-PowerShellFiles -Path $Path
    
    if ($files.Count -eq 0) {
        Write-ValidationMessage "No PowerShell files found in: $Path" "Warning"
        exit 0
    }
    
    Write-ValidationMessage "Found $($files.Count) PowerShell files to validate" "Info"
    
    foreach ($file in $files) {
        if (Should-IgnoreFile -FilePath $file) {
            Write-ValidationMessage "Ignoring file (legacy/archive): $file" "Warning"
            $script:Results.ValidFiles++
            $script:Results.TotalFiles++
            continue
        }
        Validate-PowerShellFile -FilePath $file
    }
    
    # Summary
    Write-Host "`n" -NoNewline
    Write-ValidationMessage "=== VALIDATION SUMMARY ===" "Info"
    Write-ValidationMessage "Total Files: $($script:Results.TotalFiles)" "Info"
    Write-ValidationMessage "Valid Files: $($script:Results.ValidFiles)" "Success"
    Write-ValidationMessage "Fixed Files: $($script:Results.FixedFiles)" "Fix"
    Write-ValidationMessage "Error Files: $($script:Results.ErrorFiles)" "Error"
    Write-ValidationMessage "Total Issues: $($script:Results.Issues.Count)" "Info"
    
    $errorCount = ($script:Results.Issues | Where-Object { $_.Severity -eq "Error" }).Count
    $warningCount = ($script:Results.Issues | Where-Object { $_.Severity -eq "Warning" }).Count
    
    if ($errorCount -gt 0) {
        Write-ValidationMessage "Errors: $errorCount" "Error"
    }
    if ($warningCount -gt 0) {
        Write-ValidationMessage "Warnings: $warningCount" "Warning"
    }
    
    # Exit with appropriate code
    if ($CI -and $errorCount -gt 0) {
        Write-ValidationMessage "CI mode: Exiting with error code due to validation failures" "Error"
        exit 1
    } elseif ($errorCount -gt 0) {
        exit 1
    } else {
        Write-ValidationMessage "All validations passed!" "Success"
        exit 0
    }
    
} catch {
    Write-ValidationMessage "Validation failed: $($_.Exception.Message)" "Error"
    if ($CI) {
        exit 1
    } else {
        throw
    }
}

# Ensure Write-CustomLog is defined if not imported
if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "INFO" { "Green" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

function Fix-SyntaxErrors {
    param([string]$FilePath)
    
    






$content = Get-Content $FilePath -Raw
    $originalContent = $content
    $hasChanges = $false
    
    # Common syntax fixes
    $fixes = @(
        # Fix missing quotes in strings - common pattern like $pwsh/modules/LabRunner'
        @{
            Pattern = "(\$\w+/[^'`"]*)'(?!\w)"
            Replacement = "$1'"
            Description = "Fix missing opening quote"
        },
        # Fix GitHub Actions variable syntax in PowerShell files
        @{
            Pattern = '`\$\{\{([^}]+)\}\}'
            Replacement = '${{ $1 }}'
            Description = "Fix GitHub Actions variable syntax"
        },
        # Fix common missing closing quotes
        @{
            Pattern = "('[^']*$)"
            Replacement = "$1'"
            Description = "Add missing closing quote"
        }
    )
    
    foreach ($fix in $fixes) {
        if ($content -match $fix.Pattern) {
            $newContent = $content -replace $fix.Pattern, $fix.Replacement
            if ($newContent -ne $content) {
                Write-ValidationMessage "    Applied fix: $($fix.Description)" "Fix"
                $content = $newContent
                $hasChanges = $true
            }
        }
    }
    
    if ($hasChanges) {
        Set-Content -Path $FilePath -Value $content -NoNewline
        return $true
    }
    
    return $false
}






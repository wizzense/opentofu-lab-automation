# comprehensive-syntax-checker.ps1
# A comprehensive script to validate PowerShell and JSON files for syntax errors

param(
    string$RootPath = ".",
    switch$FixIssues,
    switch$Detailed
)








$ErrorActionPreference = 'Continue'

Write-Host "=== Comprehensive Syntax Checker ===" -ForegroundColor Cyan
Write-Host "Scanning: $RootPath" -ForegroundColor Cyan
Write-Host "Fix Issues: $FixIssues" -ForegroundColor Cyan
Write-Host ""

$issuesFound = @()

# Function to test PowerShell file syntax
function Test-PowerShellSyntax {
    param(string$FilePath)
    
    






$issues = @()
    
    try {
        # Method 1: AST Parser
        $errors = $null
        $ast = System.Management.Automation.Language.Parser::ParseFile($FilePath, ref$null, ref$errors)
        
        if ($errors -and $errors.Count -gt 0) {
            foreach ($error in $errors) {
                $issues += PSCustomObject@{
                    File = $FilePath
                    Type = "PowerShell Syntax Error"
                    Line = $error.Extent.StartLineNumber
                    Message = $error.Message
                    Text = $error.Extent.Text
                    Severity = "Error"
                }
            }
        }
        
        # Method 2: Check for common issues
        $content = Get-Content -Path $FilePath -Raw
        
        # Check for unmatched quotes
        $singleQuotes = ($content -split "'"  Measure-Object).Count - 1
        $doubleQuotes = ($content -split '"'  Measure-Object).Count - 1
        
        if ($singleQuotes % 2 -ne 0) {
            $issues += PSCustomObject@{
                File = $FilePath
                Type = "Unmatched Quotes"
                Line = "Unknown"
                Message = "Potential unmatched single quotes detected"
                Text = ""
                Severity = "Warning"
            }
        }
        
        # Check for common syntax patterns that cause issues
        $lines = Get-Content -Path $FilePath
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines$i
            $lineNum = $i + 1
            
            # Check for problematic string patterns
            if ($line -match 'Read-LoggedInput\s+"^"*\$^"*"' -and $line -notmatch 'Read-LoggedInput\s+"^"*\$\{^}*\}^"*"') {
                $issues += PSCustomObject@{
                    File = $FilePath
                    Type = "Variable in String"
                    Line = $lineNum
                    Message = "Variable interpolation in string may cause parsing issues"
                    Text = $line.Trim()
                    Severity = "Warning"
                }
            }
            
            # Check for missing closing braces
            $openBraces = ($line -split '\{'  Measure-Object).Count - 1
            $closeBraces = ($line -split '\}'  Measure-Object).Count - 1
            
            if ($openBraces -ne $closeBraces -and ($openBraces -gt 0 -or $closeBraces -gt 0)) {
                # This is a simplistic check - a more sophisticated version would track across lines
                if ($Detailed) {
                    $issues += PSCustomObject@{
                        File = $FilePath
                        Type = "Brace Mismatch"
                        Line = $lineNum
                        Message = "Potential brace mismatch on this line (open: $openBraces, close: $closeBraces)"
                        Text = $line.Trim()
                        Severity = "Info"
                    }
                }
            }
        }
        
    } catch {
        $issues += PSCustomObject@{
            File = $FilePath
            Type = "Parse Exception"
            Line = "Unknown"
            Message = $_.Exception.Message
            Text = ""
            Severity = "Error"
        }
    }
    
    return $issues
}

# Function to test JSON file syntax
function Test-JsonSyntax {
    param(string$FilePath)
    
    






$issues = @()
    
    try {
        $content = Get-Content -Path $FilePath -Raw
        $null = ConvertFrom-Json $content -ErrorAction Stop
    } catch {
        $issues += PSCustomObject@{
            File = $FilePath
            Type = "JSON Syntax Error"
            Line = "Unknown"
            Message = $_.Exception.Message
            Text = ""
            Severity = "Error"
        }
    }
    
    return $issues
}

# Function to fix common issues
function Fix-CommonIssues {
    param(PSCustomObject$Issue)
    
    






if ($Issue.Type -eq "Variable in String" -and $Issue.File -match '\.ps1$') {
        Write-Host "  Attempting to fix variable interpolation issue..." -ForegroundColor Yellow
        
        $content = Get-Content -Path $Issue.File -Raw
        # Fix variable interpolation by using $() syntax
        $fixedContent = $content -replace 'Read-LoggedInput\s+"(^"*)\$(a-zA-Z_a-zA-Z0-9_*)(^"*)"', 'Read-LoggedInput "$$1$$$($2)$$3"'
        
        if ($fixedContent -ne $content) {
            Set-Content -Path $Issue.File -Value $fixedContent -Encoding UTF8
            Write-Host "    Fixed variable interpolation in $($Issue.File)" -ForegroundColor Green
            return $true
        }
    }
    
    return $false
}

# Scan PowerShell files
Write-Host "Scanning PowerShell files..." -ForegroundColor Yellow
$psFiles = Get-ChildItem -Path $RootPath -Recurse -Include "*.ps1", "*.psm1", "*.psd1" 
    Where-Object { 
        $_.FullName -notlike "*backup*" -and 
        $_.FullName -notlike "*archive*" -and
        $_.FullName -notlike "*cleanup-backup*"
    }

foreach ($file in $psFiles) {
    Write-Host "  Checking: $($file.FullName)" -ForegroundColor Gray
    $fileIssues = Test-PowerShellSyntax -FilePath $file.FullName
    $issuesFound += $fileIssues
    
    if ($FixIssues -and $fileIssues) {
        foreach ($issue in $fileIssues) {
            $fixed = Fix-CommonIssues -Issue $issue
            if ($fixed) {
                Write-Host "    Fixed issue: $($issue.Message)" -ForegroundColor Green
            }
        }
    }
}

# Scan JSON files
Write-Host "Scanning JSON files..." -ForegroundColor Yellow
$jsonFiles = Get-ChildItem -Path $RootPath -Recurse -Include "*.json" 
    Where-Object { 
        $_.FullName -notlike "*backup*" -and 
        $_.FullName -notlike "*archive*" -and
        $_.FullName -notlike "*node_modules*"
    }

foreach ($file in $jsonFiles) {
    Write-Host "  Checking: $($file.FullName)" -ForegroundColor Gray
    $fileIssues = Test-JsonSyntax -FilePath $file.FullName
    $issuesFound += $fileIssues
}

# Report results
Write-Host ""
Write-Host "=== RESULTS ===" -ForegroundColor Cyan

if ($issuesFound.Count -eq 0) {
    Write-Host " No syntax issues found!" -ForegroundColor Green
} else {
    Write-Host "Found $($issuesFound.Count) issues:" -ForegroundColor Red
    
    $grouped = issuesFound | Group-Object Severity
    foreach ($group in $grouped) {
        Write-Host ""
        Write-Host "$($group.Name) Issues ($($group.Count)):" -ForegroundColor $(
            switch ($group.Name) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "Cyan" }
                default { "Gray" }
            }
        )
        
        foreach ($issue in $group.Group) {
            Write-Host "  $($issue.Type) $($issue.File):$($issue.Line)" -ForegroundColor Gray
            Write-Host "    $($issue.Message)" -ForegroundColor Gray
            if ($issue.Text -and $issue.Text.Trim()) {
                Write-Host "    Text: $($issue.Text)" -ForegroundColor DarkGray
            }
        }
    }
    
    if (-not $FixIssues) {
        Write-Host ""
        Write-Host "Run with -FixIssues to attempt automatic fixes for some issues." -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Files scanned: $($psFiles.Count + $jsonFiles.Count)" -ForegroundColor White
Write-Host "PowerShell files: $($psFiles.Count)" -ForegroundColor White
Write-Host "JSON files: $($jsonFiles.Count)" -ForegroundColor White
Write-Host "Issues found: $($issuesFound.Count)" -ForegroundColor White

return $issuesFound.Count





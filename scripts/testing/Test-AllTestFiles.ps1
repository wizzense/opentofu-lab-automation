# Test Validation System
# Ensures all test files meet quality standards before they can break the testing system

Param(
    Parameter(Mandatory=$false)
    string$TestsPath = ".\tests\",
    
    Parameter(Mandatory=$false)
    switch$AutoFix,
    
    Parameter(Mandatory=$false)
    switch$Detailed,
    
    Parameter(Mandatory=$false)
    string$OutputFormat = "Console" # Console, JSON, HTML
)

function Test-AllTestFiles {
    param(
        string$Path,
        bool$AutoFix,
        bool$Detailed
    )
    
    Write-Host "� Validating all test files in: $Path" -ForegroundColor Cyan
    
    $results = @{
        TotalFiles = 0
        ValidFiles = 0
        InvalidFiles = 0
        FixedFiles = 0
        Errors = @()
        Details = @()
    }
    
    $testFiles = Get-ChildItem -Path $Path -Filter "*.Tests.ps1" -Recurse
    $results.TotalFiles = $testFiles.Count
    
    foreach ($testFile in $testFiles) {
        Write-Host "Checking: $($testFile.Name)" -ForegroundColor Yellow
        
        $validation = Test-SingleTestFile -Path $testFile.FullName -Detailed:$Detailed
        
        if ($validation.IsValid) {
            $results.ValidFiles++
            Write-Host "  PASS Valid" -ForegroundColor Green
        } else {
            $results.InvalidFiles++
            $results.Errors += @{
                File = $testFile.Name
                Errors = $validation.Errors
            }
            
            Write-Host "  FAIL Invalid: $($validation.Errors -join '; ')" -ForegroundColor Red
            
            if ($AutoFix) {
                Write-Host "   Attempting auto-fix..." -ForegroundColor Orange
                $fixed = Repair-TestFile -Path $testFile.FullName
                if ($fixed) {
                    $results.FixedFiles++
                    Write-Host "  PASS Fixed successfully" -ForegroundColor Green
                } else {
                    Write-Host "  FAIL Auto-fix failed" -ForegroundColor Red
                }
            }
        }
        
        if ($Detailed) {
            $results.Details += @{
                File = $testFile.Name
                Validation = $validation
            }
        }
    }
    
    return $results
}

function Test-SingleTestFile {
    param(
        string$Path,
        bool$Detailed = $false
    )
    
    $errors = @()
    $warnings = @()
    $isValid = $true
    
    try {
        # Test 1: File exists and is readable
        if (-not (Test-Path $Path)) {
            $errors += "File does not exist"
            return @{ IsValid = $false; Errors = $errors; Warnings = $warnings }
        }
        
        $content = Get-Content $Path -Raw -ErrorAction Stop
        
        # Test 2: PowerShell syntax validation
        try {
            $tokens = System.Management.Automation.PSParser::Tokenize($content, ref$null)
            $syntaxErrors = tokens | Where-Object { $_.Type -eq 'SyntaxError' }
            if ($syntaxErrors) {
                $errors += "Syntax errors found: $($syntaxErrors.Content -join ', ')"
                $isValid = $false
            }
        } catch {
            $errors += "PowerShell parsing failed: $($_.Exception.Message)"
            $isValid = $false
        }
        
        # Test 3: Pester structure validation
        if ($content -notmatch 'Describe\s+.*Tests') {
            $errors += "Missing or malformed Describe block"
            $isValid = $false
        }
        
        if ($content -notmatch 'Context\s+') {
            $warnings += "No Context blocks found - recommended for organization"
        }
        
        if ($content -notmatch 'It\s+') {
            $errors += "No It blocks found - tests are required"
            $isValid = $false
        }
        
        # Test 4: Common error patterns that break Pester
        $badPatterns = @(
            @{ Pattern = '\\s*Should\s+-Not\s+-Throw\s*(?!\S)'; Error = "Empty pipe element before Should -Not -Throw" }
            @{ Pattern = '\{\s*\}\s*\\s*Should'; Error = "Empty script block before Should assertion" }
            @{ Pattern = 'Should\s+.*\s+outside.*Describe'; Error = "Should command outside Describe block" }
            @{ Pattern = '\A-Z\\a-zA-Z0-9-\'; Error = "Malformed regex pattern" }
            @{ Pattern = '\$\w+\s*=\s*\\s*Should'; Error = "Invalid assignment with pipe" }
        )
        
        foreach ($pattern in $badPatterns) {
            if ($content -match $pattern.Pattern) {
                $errors += $pattern.Error
                $isValid = $false
            }
        }
        
        # Test 5: Try Pester discovery (if valid so far)
        if ($isValid) {
            try {
                $tempResult = Invoke-Pester -Path $Path -DryRun -Quiet -ErrorAction Stop
                if ($tempResult.FailedCount -gt 0) {
                    $errors += "Pester discovery found issues"
                    $isValid = $false
                }
            } catch {
                $errors += "Pester discovery failed: $($_.Exception.Message)"
                $isValid = $false
            }
        }
        
        # Test 6: Best practices validation
        if ($content -notmatch 'BeforeAll\s*\{') {
            $warnings += "Consider using BeforeAll for setup"
        }
        
        if ($content -match '\.ps1\s*-ErrorAction\s+SilentlyContinue') {
            $warnings += "Consider handling errors explicitly instead of suppressing"
        }
        
    } catch {
        $errors += "Validation failed: $($_.Exception.Message)"
        $isValid = $false
    }
    
    return @{
        IsValid = $isValid
        Errors = $errors
        Warnings = $warnings
        HasSyntaxErrors = (errors | Where-Object { $_ -match 'syntaxparsing' }).Count -gt 0
        HasStructureErrors = (errors | Where-Object { $_ -match 'DescribeContextIt' }).Count -gt 0
        HasPesterErrors = (errors | Where-Object { $_ -match 'PesterShould' }).Count -gt 0
    }
}

function Repair-TestFile {
    param(string$Path)
    
    try {
        # Get script name from filename
        $fileName = System.IO.Path::GetFileNameWithoutExtension($Path)
        $scriptName = $fileName -replace '\.Tests$', ''
        
        # Determine script type
        $scriptType = switch -Regex ($scriptName) {
            '^0-9{4}_Install-' { "Installer" }
            '^0-9{4}_Config-' { "Configuration" }
            '^0-9{4}_Get-' { "SystemInfo" }
            '^0-9{4}_Setup-' { "Setup" }
            '^0-9{4}_Reset-' { "Cleanup" }
            '^0-9{4}_Enable-' { "Configuration" }
            default { "Installer" }
        }
        
        # Backup original
        $backupPath = "$Path.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $Path $backupPath
        
        # Generate new test using standard template
        $outputDir = Split-Path $Path -Parent
        $generatorScript = Join-Path $PSScriptRoot ".." "testing" "New-StandardTest.ps1"
        
        if (Test-Path $generatorScript) {
            & $generatorScript -ScriptName $scriptName -ScriptType $scriptType -OutputPath $outputDir -OverwriteExisting -Validate
            return $true
        } else {
            Write-Warning "Test generator not found at: $generatorScript"
            return $false
        }
        
    } catch {
        Write-Error "Failed to repair test file: $($_.Exception.Message)"
        return $false
    }
}

function Export-ValidationResults {
    param(
        hashtable$Results,
        string$Format,
        string$OutputPath = ".\test-validation-results"
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    switch ($Format.ToLower()) {
        "json" {
            $outputFile = "$OutputPath-$timestamp.json"
            Results | ConvertTo-Json -Depth 10  Set-Content $outputFile
            Write-Host "Results exported to: $outputFile" -ForegroundColor Cyan
        }
        "html" {
            $outputFile = "$OutputPath-$timestamp.html"
            $html = ConvertTo-ValidationHtml -Results $Results
            html | Set-Content $outputFile
            Write-Host "Results exported to: $outputFile" -ForegroundColor Cyan
        }
        "console" {
            Write-ValidationSummary -Results $Results
        }
    }
}

function ConvertTo-ValidationHtml {
    param(hashtable$Results)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Validation Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .valid { color: green; }
        .invalid { color: red; }
        .warning { color: orange; }
        .error-list { background: #fff0f0; padding: 10px; border-left: 3px solid red; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Test Validation Results</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Total Files: $($Results.TotalFiles)</p>
        <p class="valid">Valid Files: $($Results.ValidFiles)</p>
        <p class="invalid">Invalid Files: $($Results.InvalidFiles)</p>
        <p class="warning">Fixed Files: $($Results.FixedFiles)</p>
    </div>
"@
    
    if ($Results.Errors.Count -gt 0) {
        $html += "<h2>Errors Found</h2>"
        foreach ($error in $Results.Errors) {
            $html += "<div class='error-list'>"
            $html += "<h3>$($error.File)</h3>"
            $html += "<ul>"
            foreach ($err in $error.Errors) {
                $html += "<li>$err</li>"
            }
            $html += "</ul></div>"
        }
    }
    
    $html += "</body></html>"
    return $html
}

function Write-ValidationSummary {
    param(hashtable$Results)
    
    Write-Host "`n Validation Summary" -ForegroundColor Cyan
    Write-Host "Total Files: $($Results.TotalFiles)" -ForegroundColor White
    Write-Host "Valid Files: $($Results.ValidFiles)" -ForegroundColor Green
    Write-Host "Invalid Files: $($Results.InvalidFiles)" -ForegroundColor Red
    Write-Host "Fixed Files: $($Results.FixedFiles)" -ForegroundColor Yellow
    
    if ($Results.InvalidFiles -gt 0) {
        Write-Host "`nFAIL Issues Found:" -ForegroundColor Red
        foreach ($error in $Results.Errors) {
            Write-Host "  $($error.File):" -ForegroundColor Yellow
            foreach ($err in $error.Errors) {
                Write-Host "    - $err" -ForegroundColor Red
            }
        }
    }
    
    $healthScore = if ($Results.TotalFiles -gt 0) { 
        math::Round(($Results.ValidFiles / $Results.TotalFiles) * 100, 1) 
    } else { 100 }
    
    Write-Host "`n� Test Suite Health: $healthScore%" -ForegroundColor $(if ($healthScore -gt 90) { "Green" } elseif ($healthScore -gt 70) { "Yellow" } else { "Red" })
}

# Main execution
$results = Test-AllTestFiles -Path $TestsPath -AutoFix:$AutoFix -Detailed:$Detailed
Export-ValidationResults -Results $results -Format $OutputFormat

# Exit with appropriate code
if ($results.InvalidFiles -gt 0 -and -not $AutoFix) {
    Write-Host "`n� Tip: Use -AutoFix to automatically repair broken test files" -ForegroundColor Cyan
    exit 1
} else {
    exit 0
}


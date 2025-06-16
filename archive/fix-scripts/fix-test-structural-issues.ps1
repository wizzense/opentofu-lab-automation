# PowerShell script to fix structural issues in test files
param(
    string$TestPath = ".\tests\",
    switch$WhatIf
)

Write-Host "Starting test file structural fixes..." -ForegroundColor Green

# Get all test files with parsing errors
$testFiles = Get-ChildItem -Path $TestPath -Filter "*.Tests.ps1" -Recurse

$fixedCount = 0
$errorCount = 0

foreach ($testFile in $testFiles) {
    try {
        Write-Host "Processing: $($testFile.Name)" -ForegroundColor Yellow
        
        $content = Get-Content -Path $testFile.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            Write-Warning "Could not read file: $($testFile.FullName)"
            continue
        }
        
        $originalContent = $content
        $changed = $false
        
        # Fix 1: Add missing closing braces for Describe blocks
        if ($content -match "Describe\s+'.+?'\s+-Tag\s+'.+?'\s+\{\s*$" -and $content -notmatch "\}\s*$") {
            Write-Host "  - Adding missing closing brace" -ForegroundColor Cyan
            $content = $content.TrimEnd() + "`n}"
            $changed = $true
        }
        
        # Fix 2: Fix empty pipe elements
        $content = $content -replace '\\s*Should\s+-Not\s+-Throw\s*$', '}  Should -Not -Throw'
        if ($content -ne $originalContent) {
            Write-Host "  - Fixed empty pipe elements" -ForegroundColor Cyan
            $changed = $true
            $originalContent = $content
        }
        
        # Fix 3: Fix unterminated strings in Context blocks
        $content = $content -replace "Context\s+'(^'+)'\s+\{\s*~~~", "Context '$1' {"
        if ($content -ne $originalContent) {
            Write-Host "  - Fixed unterminated Context strings" -ForegroundColor Cyan
            $changed = $true
            $originalContent = $content
        }
        
        # Fix 4: Fix invalid assignment expressions for Get-CrossPlatformTempPath
        $content = $content -replace '\(Get-CrossPlatformTempPath\)\s*=', '$script:CrossPlatformTempPath ='
        if ($content -ne $originalContent) {
            Write-Host "  - Fixed invalid assignment expressions" -ForegroundColor Cyan
            $changed = $true
            $originalContent = $content
        }
        
        # Fix 5: Fix missing closing parentheses in Join-Path calls
        $pattern = "(Join-Path^)+)\s+~~~"
        if ($content -match $pattern) {
            $content = $content -replace $pattern, '$1)'
            Write-Host "  - Fixed missing closing parentheses" -ForegroundColor Cyan
            $changed = $true
        }
        
        # Fix 6: Fix malformed here-strings and parameter blocks
        $content = $content -replace 'param\(\s*\\s*\\s*\$Config\s*\)', 'param(hashtable$Config)'
        if ($content -ne $originalContent) {
            Write-Host "  - Fixed parameter blocks" -ForegroundColor Cyan
            $changed = $true
            $originalContent = $content
        }
        
        # Fix 7: Ensure proper string termination
        $content = $content -replace "('(^'*?)')\s*~~~", '$1"'
        if ($content -ne $originalContent) {
            Write-Host "  - Fixed string termination" -ForegroundColor Cyan
            $changed = $true
            $originalContent = $content
        }
        
        # Fix 8: Fix improperly closed parentheses patterns
        $content = $content -replace '\)\s+\)\s+\)\s+\)\s+-and', ') -and'
        if ($content -ne $originalContent) {
            Write-Host "  - Fixed excessive closing parentheses" -ForegroundColor Cyan
            $changed = $true
        }
        
        # Write changes if any were made
        if ($changed -and -not $WhatIf) {
            Set-Content -Path $testFile.FullName -Value $content -Encoding UTF8
            Write-Host "   Fixed: $($testFile.Name)" -ForegroundColor Green
            $fixedCount++
        }
        elseif ($changed -and $WhatIf) {
            Write-Host "  WHATIF Would fix: $($testFile.Name)" -ForegroundColor Magenta
            $fixedCount++
        }
        else {
            Write-Host "  - No changes needed" -ForegroundColor Gray
        }
        
    }
    catch {
        Write-Error "Error processing $($testFile.Name): $($_.Exception.Message)"
        $errorCount++
    }
}

Write-Host "`nCompleted test file fixes:" -ForegroundColor Green
Write-Host "  Fixed: $fixedCount files" -ForegroundColor Green
Write-Host "  Errors: $errorCount files" -ForegroundColor Red

# Run a quick syntax check on some of the files
Write-Host "`nRunning quick syntax validation..." -ForegroundColor Yellow
$sampleFiles = Get-ChildItem -Path $TestPath -Filter "*.Tests.ps1"  Select-Object -First 5

foreach ($file in $sampleFiles) {
    try {
        $null = System.Management.Automation.PSParser::Tokenize((Get-Content -Path $file.FullName -Raw), ref$null)
        Write-Host "   $($file.Name) - Syntax OK" -ForegroundColor Green
    }
    catch {
        Write-Host "   $($file.Name) - Syntax Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Test file structural fixes complete!" -ForegroundColor Green

# Comprehensive test file fixer
param(
    string$TestPath = ".\tests\",
    switch$WhatIf
)

Write-Host "Starting comprehensive test file fixes..." -ForegroundColor Green

# Pattern-based fixes for common issues
$fixes = @{
    "MissingDescribeClose" = @{
        Pattern = "Describe\s+'.+?'\s+-Tag\s+'.+?'\s+\{\s*(?:\r?\n)*\s*Context"
        Fix = { param($content)
            # Find Describe blocks without proper closing
            if ($content -match "Describe\s+'.+?'\s+-Tag\s+'.+?'\s+\{") {
                # Count braces to find imbalance
                $openBraces = ($content  Select-String -Pattern '\{' -AllMatches).Matches.Count
                $closeBraces = ($content  Select-String -Pattern '\}' -AllMatches).Matches.Count
                
                if ($openBraces -gt $closeBraces) {
                    $missingBraces = $openBraces - $closeBraces
                    $content = $content.TrimEnd()
                    for ($i = 0; $i -lt $missingBraces; $i++) {
                        $content += "`n}"
                    }
                }
            }
            return $content
        }
    }
    
    "EmptyPipeElements" = @{
        Pattern = '\\s*Should\s+-Not\s+-Throw\s*$'
        Replacement = '}  Should -Not -Throw'
    }
    
    "UnterminatedStrings" = @{
        Pattern = "(Context\s+'^'+)'\s*\{\s*~~~"
        Replacement = '$1'' {'
    }
    
    "InvalidAssignments" = @{
        Pattern = '\(Get-CrossPlatformTempPath\)\s*='
        Replacement = '$script:CrossPlatformTempPath ='
    }
    
    "MissingParentheses" = @{
        Pattern = "(Join-Path^)+)\s+\)"
        Replacement = '$1)'
    }
    
    "ExcessiveParentheses" = @{
        Pattern = "\)\s+\)\s+\)\s+\)\s+-and"
        Replacement = ') -and'
    }
    
    "BadParameterBlocks" = @{
        Pattern = 'param\(\s*\\s*\\s*\$Config\s*\)'
        Replacement = 'param(hashtable$Config)'
    }
}

$testFiles = Get-ChildItem -Path $TestPath -Filter "*.Tests.ps1" -Recurse
$fixedCount = 0

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
        
        # Apply each fix
        foreach ($fixName in $fixes.Keys) {
            $fix = $fixes$fixName
            
            if ($fix.ContainsKey('Replacement')) {
                # Simple regex replacement
                $newContent = $content -replace $fix.Pattern, $fix.Replacement
                if ($newContent -ne $content) {
                    Write-Host "  - Applied fix: $fixName" -ForegroundColor Cyan
                    $content = $newContent
                    $changed = $true
                }
            }
            elseif ($fix.ContainsKey('Fix')) {
                # Custom fix function
                $newContent = & $fix.Fix $content
                if ($newContent -ne $content) {
                    Write-Host "  - Applied fix: $fixName" -ForegroundColor Cyan
                    $content = $newContent
                    $changed = $true
                }
            }
        }
        
        # Additional specific fixes for problematic patterns
        
        # Fix 1: Handle malformed It blocks that start with { and end improperly
        $content = $content -replace '(\{\s*Test-Path\s+\$script:ScriptPath\s*\})\s*\\s*Should\s+-Not\s+-Throw', '{ Test-Path $script:ScriptPath }  Should -Not -Throw'
        
        # Fix 2: Fix missing closing braces in Context blocks
        if ($content -match "Context\s+'^'+'\s+\{\s*~~~") {
            $content = $content -replace "(Context\s+'^'+)'?\s*\{\s*~~~", '$1'' {'
            $changed = $true
        }
        
        # Fix 3: Fix incomplete Join-Path expressions with trailing quotes and parentheses
        $content = $content -replace "(Join-Path^)*)'?\s*\)\s*~~~", '$1)'
        
        # Fix 4: Add missing final closing brace if needed
        if ($content -match "Describe\s+" -and -not $content.TrimEnd().EndsWith('}')) {
            $content = $content.TrimEnd() + "`n}"
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
    }
}

Write-Host "`nCompleted comprehensive test file fixes:" -ForegroundColor Green
Write-Host "  Fixed: $fixedCount files" -ForegroundColor Green

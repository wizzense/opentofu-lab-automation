



# Fix all test syntax errors systematically
# filepath: fix-test-syntax-errors.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔧 FIXING ALL PESTER TEST SYNTAX ERRORS" -ForegroundColor Cyan

# Files with known syntax errors
$problematicFiles = @(
    "tests/0006_Install-ValidationTools.Tests.ps1",
    "tests/0008_Install-OpenTofu.Tests.ps1", 
    "tests/0010_Prepare-HyperVProvider.Tests.ps1",
    "tests/0104_Install-CA.Tests.ps1",
    "tests/0106_Install-WAC.Tests.ps1"
)

foreach ($file in $problematicFiles) {
    if (Test-Path $file) {
        Write-Host "  Fixing $file..." -ForegroundColor Yellow
        
        # Read content
        $content = Get-Content $file -Raw
        
        # Fix indentation issues with "It" statements
        $content = $content -replace '        }(\r?\n)\s+It ', '}$1        
        It '
        
        # Fix missing closing quotes on It statements  
        $content = $content -replace "It 'should handle execution with valid parameters' -Skip:\(\`$SkipNonWindows\) \{", "It 'should handle execution with valid parameters' -Skip:(`$SkipNonWindows) {"
        
        # Write back
        Set-Content $file -Value $content -NoNewline
        
        Write-Host "    ✅ Fixed $file" -ForegroundColor Green
    }
}

Write-Host "🎯 Syntax error fixes complete!" -ForegroundColor Green
Import-Module (Join-Path $PSScriptRoot "pwsh/modules/CodeFixer/CodeFixer.psd1") -Force





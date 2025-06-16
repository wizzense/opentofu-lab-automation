# test-syntax-validation.ps1
# Simple script to test our syntax validation capabilities

param(
    string$FilePath = "pwsh/runner.ps1"
)








Write-Host "Testing syntax validation for: $FilePath" -ForegroundColor Cyan

try {
    # Method 1: Try to parse the file using PowerShell parser
    Write-Host "Method 1: PowerShell AST Parser" -ForegroundColor Yellow
    $errors = $null
    $ast = System.Management.Automation.Language.Parser::ParseFile($FilePath, ref$null, ref$errors)
    
    if ($errors -and $errors.Count -gt 0) {
        Write-Host "SYNTAX ERRORS FOUND:" -ForegroundColor Red
        errors | ForEach-Object {
            Write-Host "  Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red
            Write-Host "    $($_.Extent.Text)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No syntax errors found by AST parser" -ForegroundColor Green
    }
} catch {
    Write-Host "  AST Parser failed: $_" -ForegroundColor Red
}

try {
    # Method 2: Try to tokenize the file
    Write-Host "Method 2: PowerShell Tokenizer" -ForegroundColor Yellow
    $content = Get-Content -Path $FilePath -Raw
    $tokens = $null
    $parseErrors = $null
    $null = System.Management.Automation.PSParser::Tokenize($content, ref$parseErrors)
    
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        Write-Host "PARSE ERRORS FOUND:" -ForegroundColor Red
        parseErrors | ForEach-Object {
            Write-Host "  Token: $($_.Token.Content)" -ForegroundColor Red
            Write-Host "    $($_.Message)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No parse errors found by tokenizer" -ForegroundColor Green
    }
} catch {
    Write-Host "  Tokenizer failed: $_" -ForegroundColor Red
}

try {
    # Method 3: Try PSScriptAnalyzer if available
    Write-Host "Method 3: PSScriptAnalyzer" -ForegroundColor Yellow
    if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
        Import-Module PSScriptAnalyzer -Force
        $results = Invoke-ScriptAnalyzer -Path $FilePath -Severity Error
        
        if ($results) {
            Write-Host "PSScriptAnalyzer found $($results.Count) errors:" -ForegroundColor Red
            results | ForEach-Object {
                Write-Host "  Line $($_.Line): $($_.Message)" -ForegroundColor Red
                Write-Host "    Rule: $($_.RuleName)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  No errors found by PSScriptAnalyzer" -ForegroundColor Green
        }
    } else {
        Write-Host "  PSScriptAnalyzer not available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  PSScriptAnalyzer failed: $_" -ForegroundColor Red
}

try {
    # Method 4: Try to dot-source the script (this will catch runtime syntax errors)
    Write-Host "Method 4: Dot-source test (check for runtime syntax errors)" -ForegroundColor Yellow
    $scriptBlock = ScriptBlock::Create($content)
    Write-Host "  Script can be created as ScriptBlock successfully" -ForegroundColor Green
} catch {
    Write-Host "  ScriptBlock creation failed: $_" -ForegroundColor Red
}





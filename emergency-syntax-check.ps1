#!/usr/bin/env pwsh
# Emergency PowerShell Syntax Validator
param([string]$Path = ".")

$errors = @()
Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse | ForEach-Object {
    try {
        $parseErrors = @()
        $tokens = @()
        [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors)
        
        if ($parseErrors.Count -gt 0) {
            Write-Host "❌ SYNTAX ERRORS in $($_.Name):" -ForegroundColor Red
            $parseErrors | ForEach-Object {
                Write-Host "   Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red
                $errors += "$($_.FullName):$($_.Extent.StartLineNumber): $($_.Message)"
            }
        } else {
            Write-Host "✅ $($_.Name)" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ FAILED to parse $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
        $errors += "$($_.FullName): Parse failed - $($_.Exception.Message)"
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`n🚨 FOUND $($errors.Count) SYNTAX ERRORS!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All PowerShell files have valid syntax" -ForegroundColor Green
    exit 0
}

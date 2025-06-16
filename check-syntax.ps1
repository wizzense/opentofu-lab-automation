try {
    $content = Get-Content 'pwsh\kicker-bootstrap.ps1' -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
    Write-Host "SYNTAX OK" -ForegroundColor Green
} catch {
    Write-Host "SYNTAX ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

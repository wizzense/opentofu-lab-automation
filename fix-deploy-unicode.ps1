#!/usr/bin/env pwsh
# Fix Unicode issues in deploy.py for Windows compatibility

$deployFile = "./deploy.py"

if (-not (Test-Path $deployFile)) {
    Write-Error "deploy.py not found"
    exit 1
}

Write-Host "🔧 Fixing Unicode issues in deploy.py..." -ForegroundColor Yellow

# Read the file content
$content = Get-Content $deployFile -Encoding UTF8 -Raw

# Replace all emoji and Unicode characters with Windows-compatible alternatives
$replacements = @{
    '🚀' = '>>'
    '📋' = 'Platform:'
    '🏠' = 'Project:'
    '🔧' = 'Setup:'
    '📦' = 'Repository:'
    '📁' = 'Path:'
    '🔊' = 'Verbosity:'
    '❌' = 'ERROR:'
    '⚠️' = 'WARNING:'
    '💥' = 'ERROR:'
    '✅' = 'OK:'
}

foreach ($emoji in $replacements.Keys) {
    $replacement = $replacements[$emoji]
    $content = $content -replace [regex]::Escape($emoji), $replacement
}

# Write the fixed content back
$content | Set-Content $deployFile -Encoding UTF8

Write-Host "✅ Fixed Unicode issues in deploy.py" -ForegroundColor Green
Write-Host "📝 All emoji characters replaced with text equivalents" -ForegroundColor Blue

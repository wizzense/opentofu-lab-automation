#!/usr/bin/env pwsh

# Validate YAML files in the .github/workflows directory
Write-Host "Validating YAML files in .github/workflows..." -ForegroundColor Cyan

$workflowDir = ".github/workflows"
$yamlFiles = Get-ChildItem -Path $workflowDir -Filter "*.yml"

foreach ($file in $yamlFiles) {
    Write-Host "Validating: $($file.Name)" -ForegroundColor Yellow
    try {
        $content = Get-Content -Path $file.FullName -Raw
        if ($content -notmatch "^---") {
            Write-Host "  ⚠️ Missing document start in $($file.Name)" -ForegroundColor Red
        } elseif ($content -match "(?m)^\s*\t") {
            Write-Host "  ⚠️ Tab characters found in $($file.Name)" -ForegroundColor Red
        } else {
            Write-Host "  ✅ $($file.Name) is valid" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ❌ Failed to read $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Host "Validation complete." -ForegroundColor Cyan

#!/usr/bin/env pwsh
# Fix corrupted YAML workflow files where 'on:' was replaced with 'true:'

param(
 [string]$Path = ".github/workflows"
)

$ErrorActionPreference = "Continue"

function Fix-YamlCorruption {
 param([string]$FilePath)
 
 $content = Get-Content $FilePath -Raw
 $originalContent = $content
 
 # Fix the corrupted keywords
 $fixes = @{
 'true:' = 'on:'
 'crtrue:' = 'cron:'
 'runs-true:' = 'runs-on:'
 'versitrue:' = 'version:'
 'descriptitrue:' = 'description:'
 'requirtrue:' = 'required:'
 'defaulttrue:' = 'default:'
 }
 
 $fixesApplied = @()
 foreach ($corrupt in $fixes.Keys) {
 $correct = $fixes[$corrupt]
 if ($content -match [regex]::Escape($corrupt)) {
 $content = $content -replace [regex]::Escape($corrupt), $correct
 $fixesApplied += "$corrupt → $correct"
 }
 }
 
 if ($fixesApplied.Count -gt 0) {
 $content | Out-File -FilePath $FilePath -Encoding UTF8 -NoNewline
 return $fixesApplied
 }
 
 return @()
}

Write-Host " Fixing corrupted YAML workflow files..." -ForegroundColor Yellow
Write-Host ""

$yamlFiles = Get-ChildItem -Path $Path -Recurse -Include "*.yml", "*.yaml" | Where-Object { !$_.PSIsContainer }
$totalFixed = 0

foreach ($file in $yamlFiles) {
 $relativePath = Resolve-Path $file.FullName -Relative
 $fixesApplied = Fix-YamlCorruption -FilePath $file.FullName
 
 if ($fixesApplied.Count -gt 0) {
 Write-Host "[PASS] Fixed $($fixesApplied.Count) corruptions in: $relativePath" -ForegroundColor Green
 foreach ($fix in $fixesApplied) {
 Write-Host " $fix" -ForegroundColor Gray
 }
 $totalFixed += $fixesApplied.Count
 } else {
 Write-Host " No corruptions found in: $relativePath" -ForegroundColor Gray
 }
}

Write-Host ""
Write-Host " Summary:" -ForegroundColor Cyan
Write-Host " Files processed: $($yamlFiles.Count)" -ForegroundColor White
Write-Host " Total corruptions fixed: $totalFixed" -ForegroundColor Green

if ($totalFixed -gt 0) {
 Write-Host ""
 Write-Host " Verifying fixes..." -ForegroundColor Yellow
 
 try {
 $yamlLintResult = yamllint $Path --format standard 2>&1
 if ($LASTEXITCODE -eq 0) {
 Write-Host "[PASS] No YAML errors found by yamllint" -ForegroundColor Green
 } else {
 $errorCount = ($yamlLintResult | Measure-Object).Count
 Write-Host "[WARN] Found $errorCount YAML issues:" -ForegroundColor Yellow
 $yamlLintResult | Select-Object -First 10 | ForEach-Object { Write-Host " $_" -ForegroundColor Red }
 if ($errorCount -gt 10) {
 Write-Host " ... and $($errorCount - 10) more" -ForegroundColor Red
 }
 }
 }
 catch {
 Write-Host "[WARN] Could not verify with yamllint: $_" -ForegroundColor Yellow
 }
}

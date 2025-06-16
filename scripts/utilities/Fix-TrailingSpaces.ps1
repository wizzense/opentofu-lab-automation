#!/usr/bin/env pwsh
# Fix trailing spaces in all YAML files

param(
 string$Path = ".github/workflows"
)

$ErrorActionPreference = "Continue"

function Remove-TrailingSpaces {
 param(string$FilePath)
 
 $content = Get-Content $FilePath -Raw
 $originalContent = $content
 
 # Split into lines, remove trailing spaces from each line, rejoin
 $lines = $content -split "`n"
 $fixedLines = @()
 
 $trailingSpaceCount = 0
 foreach ($line in $lines) {
 if ($line -match '\s+$') {
 $trailingSpaceCount++
 }
 $fixedLines += $line.TrimEnd()
 }
 
 $fixedContent = $fixedLines -join "`n"
 
 if ($fixedContent -ne $originalContent) {
 $fixedContent  Out-File -FilePath $FilePath -Encoding UTF8 -NoNewline
 return $trailingSpaceCount
 }
 
 return 0
}

Write-Host " Fixing trailing spaces in YAML files..." -ForegroundColor Yellow
Write-Host ""

$yamlFiles = Get-ChildItem -Path $Path -Recurse -Include "*.yml", "*.yaml"  Where-Object { !$_.PSIsContainer }
$totalFixed = 0

foreach ($file in $yamlFiles) {
 $relativePath = Resolve-Path $file.FullName -Relative
 $spacesFixed = Remove-TrailingSpaces -FilePath $file.FullName
 
 if ($spacesFixed -gt 0) {
 Write-Host "PASS Fixed $spacesFixed trailing spaces in: $relativePath" -ForegroundColor Green
 $totalFixed += $spacesFixed
 } else {
 Write-Host " No trailing spaces in: $relativePath" -ForegroundColor Gray
 }
}

Write-Host ""
Write-Host " Summary:" -ForegroundColor Cyan
Write-Host " Files processed: $($yamlFiles.Count)" -ForegroundColor White
Write-Host " Total trailing spaces fixed: $totalFixed" -ForegroundColor Green

if ($totalFixed -gt 0) {
 Write-Host ""
 Write-Host " Verifying fixes with yamllint..." -ForegroundColor Yellow
 
 try {
 $yamlLintResult = yamllint $Path --format standard 2>&1  Select-String "trailing spaces"
 if ($yamlLintResult) {
 Write-Host "WARN Still found trailing space issues:" -ForegroundColor Yellow
 $yamlLintResult  ForEach-Object { Write-Host " $_" -ForegroundColor Red }
 } else {
 Write-Host "PASS No trailing space errors found by yamllint" -ForegroundColor Green
 }
 }
 catch {
 Write-Host "WARN Could not verify with yamllint: $_" -ForegroundColor Yellow
 }
}

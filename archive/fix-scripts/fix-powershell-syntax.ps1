






# PowerShell Script Syntax Fixer
# Fixes the Import-Module/Param order issue in all runner scripts

$ErrorActionPreference = 'Stop'

Write-Host "=== PowerShell Script Syntax Fixer ===" -ForegroundColor Cyan
Write-Host "Fixing Import-Module/Param order in runner scripts..." -ForegroundColor Yellow

$scriptsDir = "pwsh/runner_scripts"
$scripts = Get-ChildItem -Path $scriptsDir -Filter "*.ps1"

Write-Host "Found $($scripts.Count) scripts to fix" -ForegroundColor White

$fixedCount = 0
$skippedCount = 0

foreach ($script in $scripts) {
    Write-Host "Processing: $($script.Name)" -ForegroundColor Gray
    
    $content = Get-Content $script.FullName -Raw
    $lines = Get-Content $script.FullName
    
    # Check if this script has the problematic pattern
    if ($lines.Count -ge 2 -and 
        $lines[0] -match "^Import-Module.*LabRunner.*-Force" -and 
        $lines[1] -match "^Param\(") {
        
        Write-Host "  🔧 FIXING: Moving Import-Module after Param block" -ForegroundColor Yellow
        
        # Extract the Import-Module line and Param block
        $importLine = $lines[0]
        
        # Find the end of the Param block
        $paramStart = 1
        $paramEnd = $paramStart
        $parenCount = 0
        $inParam = $false
        
        for ($i = $paramStart; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match "^Param\(") {
                $inParam = $true
            }
            if ($inParam) {
                $parenCount += ($line.Split('(').Count - 1)
                $parenCount -= ($line.Split(')').Count - 1)
                if ($parenCount -eq 0) {
                    $paramEnd = $i
                    break
                }
            }
        }
        
        # Build the corrected content
        $newLines = @()
        
        # Add Param block first
        for ($i = $paramStart; $i -le $paramEnd; $i++) {
            $newLines += $lines[$i]
        }
        
        # Add Import-Module after Param block
        $newLines += $importLine
        
        # Add the rest of the file (skip original import and param)
        for ($i = $paramEnd + 1; $i -lt $lines.Count; $i++) {
            $newLines += $lines[$i]
        }
        
        # Write the fixed content
        $newContent = $newLines -join "`n"
        Set-Content -Path $script.FullName -Value $newContent -NoNewline
        
        Write-Host "  ✅ FIXED: $($script.Name)" -ForegroundColor Green
        $fixedCount++
        
    } else {
        Write-Host "  ⏭️  SKIPPED: No fix needed for $($script.Name)" -ForegroundColor Gray
        $skippedCount++
    }
}

Write-Host "`n=== Fix Complete ===" -ForegroundColor Cyan
Write-Host "✅ Fixed: $fixedCount scripts" -ForegroundColor Green
Write-Host "⏭️  Skipped: $skippedCount scripts" -ForegroundColor Gray
Write-Host "🎯 All PowerShell syntax errors should now be resolved!" -ForegroundColor Green -BackgroundColor Black
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/""/CodeFixer.psd1") -Force






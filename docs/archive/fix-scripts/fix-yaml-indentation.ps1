<#
VALIDATION-ONLY MODE: This script has been converted to validation-only.
It will only report issues and create GitHub issues for tracking.
No automatic file modifications or repairs are performed.
Use PatchManager for explicit file changes when needed.
#>
#!/usr/bin/env pwsh
<#
.SYNOPSIS
Fix common YAML indentation issues in GitHub workflow files

.DESCRIPTION
This script fixes the most common YAML structural issues found in GitHub Actions workflow files:
- Incorrect job indentation
- Missing proper step indentation
- Improper run block formatting
#>

$ErrorActionPreference = "Stop"

Write-Host "Fixing common YAML indentation issues..." -ForegroundColor Cyan

$workflowDir = ".github/workflows"
$workflowFiles = Get-ChildItem -Path $workflowDir -Filter "*.yml" -ErrorAction SilentlyContinue

foreach ($file in $workflowFiles) {
    Write-Host "Processing: $($file.Name)" -ForegroundColor Yellow
    
    $content = Get-Content $file.FullName -Raw
    $lines = Get-Content $file.FullName
    
    # Skip already properly formatted files
    if ($file.Name -in @("mega-consolidated.yml", "mega-consolidated-fixed.yml")) {
        Write-Host "  Skipping $($file.Name) - already properly formatted" -ForegroundColor Green
        continue
    }
    
    $fixedLines = @()
    $inRunBlock = $false
    $jobsSection = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines$i
        
        # Detect jobs section
        if ($line -match '^jobs:') {
            $jobsSection = $true
            $fixedLines += $line
            continue
        }
        
        # Fix job indentation (should be 2 spaces under jobs:)
        if ($jobsSection -and $line -match '^ a-zA-Z-+:' -and $line -notmatch '^  a-zA-Z-+:') {
            $jobName = $line.Trim()
            $fixedLines += "  $jobName"
            continue
        }
        
        # Fix job properties (should be 4 spaces under job)
        if ($jobsSection -and $line -match '^ (nameruns-onifneedsstrategypermissionsenv):') {
            $property = $line.Trim()
            $fixedLines += "    $property"
            continue
        }
        
        # Fix steps section (should be 4 spaces under job)
        if ($jobsSection -and $line -match '^ steps:') {
            $fixedLines += "    steps:"
            continue
        }
        
        # Fix step items (should be 6 spaces under steps:)
        if ($jobsSection -and $line -match '^ - name:') {
            $stepLine = $line.TrimStart(' ').TrimStart('-').Trim()
            $fixedLines += "      - name: $($stepLine.Substring(5).Trim())"
            continue
        }
        
        # Fix step properties (should be 8 spaces under step)
        if ($jobsSection -and $line -match '^ (usesrunwithenvidif):') {
            $property = $line.Trim()
            $fixedLines += "        $property"
            continue
        }
        
        # Fix run blocks
        if ($line -match '^ +run: \') {
            $fixedLines += "        run: "
            $inRunBlock = $true
            continue
        }
        
        # Fix run block content
        if ($inRunBlock -and $line -match '^ ^ ') {
            $runContent = $line.TrimStart(' ')
            $fixedLines += "          $runContent"
            continue
        }
        
        # Exit run block
        if ($inRunBlock -and ($line -match '^ - name:' -or $line -match '^ a-zA-Z-+:' -or $line.Trim() -eq '')) {
            $inRunBlock = $false
        }
        
        # Default: keep line as-is
        $fixedLines += $line
    }
    
    # Write the fixed content back to file
    $fixedContent = $fixedLines -join "`n"
    if ($fixedContent -ne $content) {
        # DISABLED: # DISABLED: Set-Content -Path $file.FullName -Value $fixedContent -NoNewline
        Write-Host "  Fixed indentation issues in $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed for $($file.Name)" -ForegroundColor Gray
    }
}

Write-Host "YAML indentation fix completed!" -ForegroundColor Green

#!/usr/bin/env pwsh
# scripts/utilities/create-github-issues.ps1
# Automatically create GitHub issues for unresolved critical problems

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$AutoCreate,
    
    [Parameter()]
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Continue'

# Load current health data
$healthFile = "$ProjectRoot/docs/reports/project-status/current-health.json"
if (-not (Test-Path $healthFile)) {
    Write-Host "No health data found, nothing to report" -ForegroundColor Yellow
    return
}

try {
    $health = Get-Content $healthFile | ConvertFrom-Json
} catch {
    Write-Error "Could not parse health data: $_"
    return
}

# Only create issues for high/critical severity problems
$criticalIssues = $health.Issues | Where-Object { $_.Severity -in @("High", "Critical") }

if ($criticalIssues.Count -eq 0) {
    Write-Host "No critical issues found, no GitHub issues needed" -ForegroundColor Green
    return
}

foreach ($issue in $criticalIssues) {
    $title = "[$($issue.Severity)] $($issue.Description)"
    $body = @"
## Issue Summary
**Category**: $($issue.Category)
**Severity**: $($issue.Severity)
**Affected Files**: $($issue.Count)

## Description
$($issue.Description)

## Recommended Fix
\`\`\`powershell
$($issue.Fix)
\`\`\`

## Sample Affected Files
"@

    if ($issue.Files -and $issue.Files.Count -gt 0) {
        $sampleFiles = $issue.Files | Select-Object -First 10
        foreach ($file in $sampleFiles) {
            $body += "`n- $file"
        }
        
        if ($issue.Files.Count -gt 10) {
            $body += "`n- ...and $($issue.Files.Count - 10) more files"
        }
    }

    $body += @"

## Auto-Generated Report
This issue was automatically created by the unified maintenance system.
- **Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Health Check Mode**: Comprehensive
- **Auto-Fix**: $($AutoCreate -eq $true)

/label maintenance infrastructure
"@

    if ($AutoCreate) {
        try {
            Write-Host "Creating GitHub issue: $title" -ForegroundColor Cyan
            $result = gh issue create --title $title --body $body --label "maintenance,infrastructure,auto-generated"
            Write-Host "Created issue: $result" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to create GitHub issue: $_"
        }
    } else {
        Write-Host "Would create issue: $title" -ForegroundColor Yellow
        Write-Host "Use -AutoCreate to actually create issues" -ForegroundColor Yellow
    }
}

Write-Host "GitHub issue creation completed" -ForegroundColor Green

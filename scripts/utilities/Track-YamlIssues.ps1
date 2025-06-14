#!/usr/bin/env pwsh
# Track YAML validation errors in the issue tracker

param(
 [string]$Mode = "Track"
)

$ErrorActionPreference = "Continue"

# Get current timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Define YAML issue data
$yamlIssues = @{
 "YAML-001" = @{
 Category = "YAML Validation: Trailing Spaces"
 Description = "154 trailing space errors fixed across all workflow files"
 Severity = "Medium"
 Files = @(
 ".github/workflows/system-health-monitor.yml",
 ".github/workflows/unified-ci.yml", 
 ".github/workflows/auto-test-generation-consolidated.yml",
 ".github/workflows/unified-utilities.yml",
 ".github/workflows/release.yml",
 ".github/workflows/archive-legacy-workflows.yml",
 ".github/workflows/unified-testing.yml",
 ".github/workflows/validate-workflows.yml",
 ".github/workflows/copilot-auto-fix.yml"
 )
 Count = 154
 FirstSeen = $timestamp
 LastSeen = $timestamp
 AutoFixable = $true
 Status = "FIXED"
 FixedBy = "Fix-TrailingSpaces.ps1"
 Prevention = "Integrate yamllint auto-fix into pre-commit hooks"
 }
 "YAML-002" = @{
 Category = "YAML Validation: Indentation"
 Description = "Wrong indentation in release.yml fixed"
 Severity = "High"
 Files = @(".github/workflows/release.yml")
 Count = 1
 FirstSeen = $timestamp
 LastSeen = $timestamp
 AutoFixable = $true
 Status = "FIXED"
 FixedBy = "Manual edit to fix steps indentation"
 Prevention = "Validate YAML structure in CI pipeline"
 }
 "YAML-003" = @{
 Category = "YAML Validation: Document Start"
 Description = "Missing document start marker in release.yml fixed"
 Severity = "Low"
 Files = @(".github/workflows/release.yml")
 Count = 1
 FirstSeen = $timestamp
 LastSeen = $timestamp
 AutoFixable = $true
 Status = "FIXED"
 FixedBy = "Added --- document start marker"
 Prevention = "Enforce YAML document start marker"
 }
 "YAML-004" = @{
 Category = "YAML Validation: Truthy Values"
 Description = "GitHub Actions 'on:' keyword flagged as truthy (false positive)"
 Severity = "Low"
 Files = @(".github/workflows/release.yml")
 Count = 1
 FirstSeen = $timestamp
 LastSeen = $timestamp
 AutoFixable = $false
 Status = "WONTFIX"
 FixedBy = "N/A - Valid GitHub Actions syntax"
 Prevention = "Configure yamllint to ignore GitHub Actions keywords"
 }
}

# Create issue tracking output
$issueOutput = @{
 Timestamp = $timestamp
 TotalIssues = $yamlIssues.Count
 Issues = $yamlIssues
}

# Output to issue tracker file
$outputPath = "/workspaces/opentofu-lab-automation/scripts/testing/yaml-issues.json"
$issueOutput | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "=[${timestamp}] [YAML-TRACKER] Tracked $($yamlIssues.Count) YAML validation issues" -ForegroundColor Green
Write-Host "=[${timestamp}] [YAML-TRACKER] Output written to: $outputPath" -ForegroundColor Green

# Also create a summary report
$summaryPath = "/workspaces/opentofu-lab-automation/scripts/testing/yaml-issues-summary.md"
$summary = @"
# YAML Validation Issues Report

Generated: $timestamp

## Summary
- **Total Issues**: $($yamlIssues.Count)
- **Auto-fixable**: $($yamlIssues.Values.Where({$_.AutoFixable}).Count)
- **Critical Files**: 9 workflow files affected

## Issues by Category

"@

foreach ($issueId in $yamlIssues.Keys) {
 $issue = $yamlIssues[$issueId]
 $summary += @"

### $issueId - $($issue.Category)
- **Description**: $($issue.Description)
- **Severity**: $($issue.Severity)
- **Count**: $($issue.Count)
- **Auto-fixable**: $($issue.AutoFixable)
- **Files Affected**: $($issue.Files.Count)
- **Prevention**: $($issue.Prevention)

"@
}

$summary += @"

## Recommended Actions

1. **Immediate**: Run YAML auto-fix via \`scripts/validation/Invoke-YamlValidation.ps1 -Mode Fix\`
2. **Integration**: Add yamllint validation to unified-maintenance.ps1 ([PASS] Already done)
3. **Prevention**: Add pre-commit hooks for YAML validation
4. **Monitoring**: Include YAML validation in CI pipeline health checks

## Auto-Fix Command
\`\`\`bash
pwsh -Command "./scripts/validation/Invoke-YamlValidation.ps1 -Mode Fix"
\`\`\`

"@

$summary | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Host "=[${timestamp}] [YAML-TRACKER] Summary report written to: $summaryPath" -ForegroundColor Green

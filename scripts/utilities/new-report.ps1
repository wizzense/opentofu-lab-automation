#!/usr/bin/env pwsh
# scripts/utilities/new-report.ps1
# Utility to create new reports with proper naming and structure

CmdletBinding()
param(
 Parameter(Mandatory)







 ValidateSet('test-analysis', 'workflow-analysis', 'project-status')
 string$Type,
 
 Parameter(Mandatory)
 string$Title,
 
 string$Date = (Get-Date -Format 'yyyy-MM-dd'),
 
 switch$Open
)

$ErrorActionPreference = 'Stop'

# Generate filename
$safeName = $Title.ToLower() -replace '^a-z0-9+', '-' -replace '^-+-+$'
$fileName = "$Date-$safeName.md"
$filePath = Join-Path $PSScriptRoot "../../docs/reports/$Type" $fileName

# Ensure directory exists
$dir = Split-Path $filePath -Parent
if (-not (Test-Path $dir)) {
 New-Item -ItemType Directory -Path $dir -Force | Out-Null}

# Template based on type
$template = switch ($Type) {
 'test-analysis' {
 @"
# $Title
**Generated**: $Date
**Test Run Duration**: Duration

## Executive Summary

**Test Results:**
- **Pester Tests**: Failed / Passed / Skipped (Total: Total)
- **Python Tests**: Failed / Passed
- **Overall Status**: Status

**Key Findings:**
- Key finding 1
- Key finding 2

---

## CRITICAL ISSUES

### 1. Issue Category
**Impact**: HIGH/MEDIUM/LOW - Brief description
- Issue detail 1
- Issue detail 2

---

## DETAILED BREAKDOWN

### Test Category Results

#### Failed Tests (Number)
- Failure category 1: Details
- Failure category 2: Details

#### Passed Tests (Number)
- Success category 1: Details

---

## ROOT CAUSE ANALYSIS

### Primary Issues
1. Root cause 1
2. Root cause 2

### Secondary Issues
1. Secondary cause 1
2. Secondary cause 2

---

## RECOMMENDED REMEDIATION PLAN

### Phase 1: Critical Fixes (High Priority)
1. **Fix 1**: Description and steps
2. **Fix 2**: Description and steps

### Phase 2: Infrastructure Fixes (Medium Priority)
1. **Fix 3**: Description and steps

---

## IMMEDIATE ACTION ITEMS

### For Next Development Session:
1. PASS **Action 1** - Description
2. PASS **Action 2** - Description

### Success Metrics:
- **Target**: Metric 1
- **Target**: Metric 2

---

*This report provides analysis of scope. Next review scheduled for date.*
"@
 }
 
 'workflow-analysis' {
 @"
# $Title
**Generated**: $Date
**Analysis Period**: Period

## Executive Summary

**Workflow Health:**
- **Success Rate**: X% (Successful/Total workflows)
- **Critical Failures**: Number
- **Overall Status**: Status

---

## WORKFLOW STATUS ANALYSIS

### Failed Workflows (Number/Total)
1. **Workflow Name** - Failure reason
2. **Workflow Name** - Failure reason

### Successful Workflows (Number/Total)
- Workflow 1
- Workflow 2

---

## FAILURE PATTERN ANALYSIS

### Common Error Patterns
1. **Error Type**: Description and frequency
2. **Error Type**: Description and frequency

### Environment Issues
- Environment issue 1
- Environment issue 2

---

## RECOMMENDED IMPROVEMENTS

### Immediate Fixes
1. **Fix 1**: Description
2. **Fix 2**: Description

### Long-term Improvements
1. **Improvement 1**: Description
2. **Improvement 2**: Description

---

*This analysis covers scope. Next review scheduled for date.*
"@
 }
 
 'project-status' {
 @"
# $Title
**Generated**: $Date
**Project Phase**: Phase

## Executive Summary

**Milestone Progress:**
- **Completed**: X% (Completed/Total items)
- **In Progress**: Number items
- **Remaining**: Number items

---

## COMPLETED WORK

### Major Achievements
1. **Achievement 1**: Description
2. **Achievement 2**: Description

### Bug Fixes
- Fix 1: Description
- Fix 2: Description

### Improvements
- Improvement 1: Description
- Improvement 2: Description

---

## IN PROGRESS

### Current Work Items
1. **Work Item 1**: Status and details
2. **Work Item 2**: Status and details

---

## REMAINING WORK

### High Priority
1. **Item 1**: Description and priority
2. **Item 2**: Description and priority

### Medium Priority
- Item 3: Description
- Item 4: Description

---

## TECHNICAL DEBT ASSESSMENT

### Current Debt
- Debt item 1: Impact and effort
- Debt item 2: Impact and effort

### Remediation Plan
1. Plan item 1
2. Plan item 2

---

## NEXT PHASE PLANNING

### Upcoming Milestones
- **Milestone 1**: Target date and scope
- **Milestone 2**: Target date and scope

### Resource Requirements
- Resource 1: Details
- Resource 2: Details

---

*This status report covers scope. Next update scheduled for date.*
"@
 }
}

# Write the template
Set-Content -Path $filePath -Value $template -Encoding UTF8

Write-Host "PASS Created new $Type report: $fileName" -ForegroundColor Green
Write-Host "� Location: $filePath" -ForegroundColor Cyan

if ($Open) {
 if (Get-Command code -ErrorAction SilentlyContinue) {
 code $filePath
 Write-Host " Opened in VS Code" -ForegroundColor Green
 } else {
 Write-Host " Open with: code '$filePath'" -ForegroundColor Yellow
 }
}

# Update the INDEX.md file suggestion
Write-Host ""
Write-Host " Don't forget to update the INDEX.md file with your new report!" -ForegroundColor Yellow
Write-Host "� Location: docs/reports/INDEX.md" -ForegroundColor Cyan





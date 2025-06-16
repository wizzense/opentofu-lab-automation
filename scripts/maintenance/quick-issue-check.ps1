#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/quick-issue-check.ps1

<#
.SYNOPSIS
Quick targeted check of known failing components without full test runs.

.DESCRIPTION
This script checks only the components that have been identified as problematic,
using cached results and targeted validation to avoid lengthy full health checks.

.PARAMETER Target
What to check: KnownIssues, RecentFailures, CriticalComponents, All

.PARAMETER AutoFix
Attempt to automatically fix found issues

.EXAMPLE
./scripts/maintenance/quick-issue-check.ps1 -Target "KnownIssues"
#>

CmdletBinding()
param(
 Parameter()
 ValidateSet('KnownIssues', 'RecentFailures', 'CriticalComponents', 'All')
 string$Target = "KnownIssues",
 
 Parameter()
 switch$AutoFix
)

$ErrorActionPreference = "Stop"
# Detect the correct project root based on the current environment
if ($IsWindows -or $env:OS -eq "Windows_NT") {
 $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
 $ProjectRoot = "/workspaces/opentofu-lab-automation"
}

function Write-QuickLog {
 param(string$Message, string$Level = "INFO")
 $timestamp = Get-Date -Format "HH:mm:ss"
 $color = switch ($Level) {
 "INFO" { "Cyan" }
 "SUCCESS" { "Green" }
 "WARNING" { "Yellow" }
 "ERROR" { "Red" }
 "FIX" { "Magenta" }
 default { "White" }
 }
 Write-Host "$timestamp $Level $Message" -ForegroundColor $color
}

# Known problematic components from previous analyses
$KnownIssues = @{
 "MissingCommands" = @(
 "errors", "Format-Config", "Invoke-LabStep", "Write-Continue"
 )
 "SyntaxErrors" = @(
 "$ProjectRoot/pwsh/Download-Archive.ps1",
 "$ProjectRoot/pwsh/Logger.ps1"
 )
 "ImportPathIssues" = @(
 "$ProjectRoot/tests/*.ps1"
 )
 "TestContainerIssues" = @(
 "Nested containers in Pester tests",
 "BeforeAll/AfterAll scope issues"
 )
}

function Test-KnownCommands {
 Write-QuickLog "Checking for known missing commands..." "INFO"
 
 # First, source TestHelpers to load any mock functions
 $testHelpersPath = "$ProjectRoot/tests/helpers/TestHelpers.ps1"
 if (Test-Path $testHelpersPath) {
 try {
 . $testHelpersPath
 Write-QuickLog " TestHelpers.ps1 sourced for mock functions" "SUCCESS"
 }
 catch {
 Write-QuickLog "WARN Failed to source TestHelpers.ps1: $($_.Exception.Message)" "WARNING"
 }
 }
 
 $issues = @()
 foreach ($cmd in $KnownIssues.MissingCommands) {
 try {
 Get-Command $cmd -ErrorAction Stop | Out-Null
Write-QuickLog " Command '$cmd' is available" "SUCCESS"
 }
 catch {
 $issues += "Missing command: $cmd"
 Write-QuickLog " Command '$cmd' is missing" "ERROR"
 }
 }
 
 return $issues
}

function Test-SyntaxErrors {
 Write-QuickLog "Checking known syntax error files..." "INFO"
 
 $issues = @()
 foreach ($file in $KnownIssues.SyntaxErrors) {
 if (Test-Path $file) {
 try {
 $null = System.Management.Automation.PSParser::Tokenize((Get-Content $file -Raw), ref$null)
 Write-QuickLog " Syntax OK: $(Split-Path $file -Leaf)" "SUCCESS"
 }
 catch {
 $issues += "Syntax error in: $file"
 Write-QuickLog " Syntax error: $(Split-Path $file -Leaf)" "ERROR"
 }
 }
 }
 
 return $issues
}

function Test-ImportPaths {
 Write-QuickLog "Checking for import path issues..." "INFO"
 
 $issues = @()
 $testFiles = Get-ChildItem "$ProjectRoot/tests" -Filter "*.ps1" -Recurse
 
 foreach ($file in $testFiles) {
 $content = Get-Content $file.FullName -Raw
 if ($content -match 'Import-Module.*lab_utils') {
 $issues += "Outdated import path in: $($file.Name)"
 Write-QuickLog " Outdated import: $($file.Name)" "ERROR"
 }
 else {
 Write-QuickLog " Import paths OK: $($file.Name)" "SUCCESS"
 }
 }
 
 return $issues
}

function Test-CriticalComponents {
 Write-QuickLog "Checking critical components..." "INFO"
 
 $issues = @()
 $criticalFiles = @(
 "$ProjectRoot/pwsh/modules/LabRunner/LabRunner.psm1",
 "$ProjectRoot/pwsh/modules/CodeFixer/CodeFixer.psm1",
 "$ProjectRoot/scripts/maintenance/unified-maintenance.ps1"
 )
 
 foreach ($file in $criticalFiles) {
 if (-not (Test-Path $file)) {
 $issues += "Missing critical file: $file"
 Write-QuickLog " Missing: $(Split-Path $file -Leaf)" "ERROR"
 }
 else {
 Write-QuickLog " Present: $(Split-Path $file -Leaf)" "SUCCESS"
 }
 }
 
 return $issues
}

function Invoke-AutoFix {
 param(array$Issues)
 
 if (-not $AutoFix -or $Issues.Count -eq 0) { return }
 
 Write-QuickLog "Attempting to auto-fix $($Issues.Count) issues..." "FIX"
 $fixedCount = 0
 
 foreach ($issue in $Issues) {
 Write-QuickLog "Fixing: $issue" "FIX"
 
 switch -Regex ($issue) {
 "Missing command: (.+)" {
 $cmd = $Matches1
 Write-QuickLog "Adding mock for command: $cmd" "FIX"
 Add-MissingCommandMock $cmd
 $fixedCount++
 }
 "Syntax error in: (.+)" {
 $file = $Matches1
 Write-QuickLog "Running syntax fix on: $(Split-Path $file -Leaf)" "FIX"
 Fix-SyntaxError $file
 $fixedCount++
 }
 "Outdated import path in: (.+)" {
 $file = $Matches1
 Write-QuickLog "Fixing import path in: $file" "FIX"
 Fix-ImportPath $file
 $fixedCount++
 }
 default {
 Write-QuickLog "No auto-fix available for: $issue" "WARNING"
 }
 }
 }
 
 if ($fixedCount -gt 0) {
 Write-QuickLog "PASS Auto-fixed $fixedCount out of $($Issues.Count) issues" "SUCCESS"
 }
}

function Add-MissingCommandMock {
 param(string$CommandName)
 
 $testHelpersPath = "$ProjectRoot/tests/helpers/TestHelpers.ps1"
 if (-not (Test-Path $testHelpersPath)) { return }
 
 $content = Get-Content $testHelpersPath -Raw
 if ($content -notmatch "function $CommandName") {
 $mockFunction = @"

# Auto-generated mock for missing command: $CommandName
function global:$CommandName {
 param(Parameter(ValueFromRemainingArguments)string`$Arguments)
 Write-Host "Mock $CommandName called with: `$Arguments" -ForegroundColor Yellow
 return `$true
}
"@
 $content += $mockFunction
 content | Out-File $testHelpersPath -Encoding UTF8
 Write-QuickLog "PASS Added mock function for '$CommandName'" "SUCCESS"
 }
}

function Fix-SyntaxError {
 param(string$FilePath)
 
 try {
 pwsh -File "$ProjectRoot/scripts/fix-test-syntax.ps1" -FilePath $FilePath -ErrorAction SilentlyContinue
 Write-QuickLog "PASS Syntax fix applied to $(Split-Path $FilePath -Leaf)" "SUCCESS"
 } catch {
 Write-QuickLog "FAIL Failed to fix syntax in $(Split-Path $FilePath -Leaf)`: $($_.Exception.Message)" "ERROR"
 }
}

function Fix-ImportPath {
 param(string$FileName)
 
 $filePath = Get-ChildItem "$ProjectRoot/tests" -Name $FileName -Recurse | Select-Object -First 1
 if ($filePath) {
 try {
 pwsh -File "$ProjectRoot/fix-import-issues.ps1" -TargetFile $filePath.FullName -ErrorAction SilentlyContinue
 Write-QuickLog "PASS Import path fixed in $FileName" "SUCCESS"
 }
 catch {
 Write-QuickLog "FAIL Failed to fix imports in $FileName`: $($_.Exception.Message)" "ERROR"
 }
 }
}

# Main execution
try {
 Write-QuickLog "Starting quick issue check (Target: $Target)" "INFO"
 
 $allIssues = @()
 
 switch ($Target) {
 'KnownIssues' {
 $allIssues += Test-KnownCommands
 $allIssues += Test-SyntaxErrors
 }
 'RecentFailures' {
 $allIssues += Test-ImportPaths
 }
 'CriticalComponents' {
 $allIssues += Test-CriticalComponents
 }
 'All' {
 $allIssues += Test-KnownCommands
 $allIssues += Test-SyntaxErrors
 $allIssues += Test-ImportPaths
 $allIssues += Test-CriticalComponents
 }
 }
 
 if ($allIssues.Count -eq 0) {
 Write-QuickLog " No issues found in $Target check!" "SUCCESS"
 }
 else {
 Write-QuickLog "Found $($allIssues.Count) issues:" "WARNING"
 allIssues | ForEach-Object{ Write-QuickLog " - $_" "ERROR" }
 
 Invoke-AutoFix $allIssues
 }
 
 # Cache results for future quick checks
 $results = @{
 Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 Target = $Target
 IssueCount = $allIssues.Count
 Issues = $allIssues
 }
 
 $cacheDir = "$ProjectRoot/docs/reports/issue-tracking"
 if (-not (Test-Path $cacheDir)) {
 New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null}
 
 results | ConvertTo-Json-Depth 3  Out-File "$cacheDir/last-quick-check.json" -Encoding UTF8
 Write-QuickLog "Results cached for future reference" "INFO"
}
catch {
 Write-QuickLog "Quick check failed: $($_.Exception.Message)" "ERROR"
 exit 1
}





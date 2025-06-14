---
description: Perform comprehensive project maintenance including health checks, validation, and cross-platform testing
mode: agent
tools: ["codebase", "run_in_terminal", "github_repo"]
---

# Project Maintenance and Health Check

You are tasked with performing comprehensive project maintenance for the OpenTofu Lab Automation project.

## Start General, Then Get Specific

### Step 1: General Health Assessment
Begin with a broad health check to understand the current project state:

```powershell
# Run the unified maintenance system for initial assessment
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
```

Based on the results, drill down into specific areas that need attention.

### Step 2: Specific Validation Based on Findings
If the initial assessment reveals issues, target them specifically:

**PowerShell Issues Found:**
```powershell
Import-Module "/pwsh/modules/CodeFixer/" -Force
Invoke-PowerShellLint -Path "." -Parallel -OutputFormat "Detailed"
```

**YAML Issues Found:**
```powershell
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"
```

**Module Import Issues Found:**
```powershell
Invoke-ImportAnalysis -Path "." -AutoFix
```

**Test Framework Issues Found:**
```powershell
./tests/Setup-TestingFramework.ps1 -ValidateOnly
```

## Provide Examples of Expected Outcomes

### Example 1: Healthy Project State
```
Health Check Results:
- PowerShell Linting: PASSED (0 errors, 2 warnings auto-fixed)
- YAML Validation: PASSED (all workflow files valid)
- Module Imports: PASSED (LabRunner and CodeFixer load correctly)
- Test Framework: PASSED (all test helpers functional)
- Performance: PASSED (health check completed in 45 seconds)
- Cross-Platform: PASSED (GitHub Actions workflows green)
```

### Example 2: Issues Detected and Fixed
```
Health Check Results:
- PowerShell Linting: FIXED (15 syntax errors in 3 files corrected)
- YAML Validation: FIXED (workflow indentation corrected)
- Module Imports: WARNING (deprecated paths updated automatically)
- Test Framework: FIXED (missing test helper functions regenerated)
- Performance: WARNING (health check took 2.1 minutes - investigating)
- Cross-Platform: PENDING (triggered GitHub Actions for validation)
```

## Break Down Complex Tasks

### Task 1: Core System Validation
Validate fundamental project components:
- Module availability and loading
- Script syntax and imports
- Configuration file integrity
- Test framework functionality

### Task 2: Apply Safe Fixes with Validation
Use the fix-with-validation pattern:
- Create backup before fixes
- Apply automated corrections
- Validate fixes work correctly
- Revert failed fixes automatically

### Task 3: Cross-Platform Validation
Trigger multi-OS validation when possible:
- Push changes to feature branch
- Monitor GitHub Actions workflows
- Validate results across Windows, Linux, macOS
- Only proceed if all platforms pass

### Task 4: Project File Synchronization
Keep project files current:
- Update PROJECT-MANIFEST.json with changes
- Regenerate project indexes
- Update health metrics and performance data
- Create maintenance log entries

### Task 5: Performance Assessment and Optimization
Measure and improve performance:
- Track health check execution time
- Identify bottlenecks in validation
- Optimize parallel processing usage
- Update performance benchmarks

## Provide Context from Codebase

Reference the current project state using #codebase to:
- Understand existing project structure
- Identify recent changes that might affect health
- Find related files that might need attention
- Ensure fixes align with project standards

## Iterate and Refine Your Approach

Use follow-up prompts to refine the maintenance process:

1. **Initial Assessment**: "Perform basic health check and identify top 3 priority issues"
2. **Targeted Fixes**: "Apply automated fixes for the PowerShell linting errors found, but validate each fix works"
3. **Validation**: "Run cross-platform validation to ensure fixes work on Windows, Linux, and macOS"
4. **Documentation**: "Update project documentation to reflect the maintenance performed and current health status"

## Safety Requirements - Fix with Validation Pattern

ALWAYS follow the safe fix application pattern:

```powershell
# Before applying any fix:
1. Create backup of affected files
2. Apply fix using Invoke-SafeFixApplication
3. Validate fix works correctly
4. Run comprehensive validation
5. Test on multiple platforms if possible
6. Revert automatically if validation fails
```

Never leave the project in a broken state. If a fix causes issues, it should be automatically reverted.

## Expected Deliverables

Generate a comprehensive maintenance report that includes:

### 1. Executive Summary
- Overall project health score (percentage)
- Critical issues resolved
- Performance improvements achieved
- Cross-platform compatibility status

### 2. Detailed Validation Results
- PowerShell linting: errors found and fixed
- YAML validation: syntax and format corrections
- Module imports: path updates and availability
- Test framework: functionality verification
- Security scan: vulnerabilities addressed

### 3. Applied Changes
- List of files modified during maintenance
- Backup locations for easy rollback
- Validation results for each applied fix
- Any fixes that were reverted and why

### 4. Performance Metrics
- Health check execution time (target: < 1 minute)
- Validation speed improvements
- Resource usage optimization
- Benchmark comparisons

### 5. Cross-Platform Results
- GitHub Actions workflow status
- Windows, Linux, macOS compatibility
- Any platform-specific issues found
- Multi-OS test execution results

### 6. Recommendations
- Preventive maintenance suggestions
- Performance optimization opportunities
- Infrastructure improvements needed
- Best practices to implement

## Context and Tools Usage

Use the right context for accurate maintenance:
- #codebase for understanding project structure
- run_in_terminal for executing maintenance commands
- github_repo if accessing external templates or examples
- Reference current PROJECT-MANIFEST.json state
- Include recent commit history context

Keep chat history relevant by focusing on the current maintenance session and removing outdated context that might confuse the maintenance process.

### PROJECT-MANIFEST.json Maintenance
```powershell
# Read and update project manifest
$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json

# Update metadata
$manifest.project.lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$manifest.project.version = Get-NextVersion -Current $manifest.project.version -Type ${input:versionType}

# Update module information
foreach ($moduleName in @("CodeFixer", "LabRunner")) {
    $modulePath = "/pwsh/modules/$moduleName/"
    if (Test-Path $modulePath) {
        $moduleInfo = Get-ModuleInfo -Path $modulePath
        $manifest.core.modules.$moduleName.lastUpdated = Get-Date -Format "yyyy-MM-dd"
        $manifest.core.modules.$moduleName.keyFunctions = $moduleInfo.ExportedFunctions
        $manifest.core.modules.$moduleName.version = $moduleInfo.Version
    }
}

# Update project statistics
$manifest.statistics = @{
    totalFiles = (Get-ChildItem -Recurse -File | Measure-Object).Count
    powershellFiles = (Get-ChildItem -Recurse -Filter "*.ps1" | Measure-Object).Count
    testFiles = (Get-ChildItem -Path "./tests/" -Filter "*.ps1" | Measure-Object).Count
    workflowFiles = (Get-ChildItem -Path "./.github/workflows/" -Filter "*.yml" | Measure-Object).Count
    lastHealthCheck = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# Save updated manifest
$manifest | ConvertTo-Json -Depth 10 | Set-Content "./PROJECT-MANIFEST.json"

# Validate manifest structure
Test-JsonConfig -Path "./PROJECT-MANIFEST.json"
```

### Index File Management
```powershell
# Create/update module index
$moduleIndex = @{
    lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    modules = @{}
}

# Scan all modules
Get-ChildItem -Path "./pwsh/modules/" -Directory | ForEach-Object {
    $moduleName = $_.Name
    $manifestPath = Join-Path $_.FullName "$moduleName.psd1"
    
    if (Test-Path $manifestPath) {
        try {
            Import-Module $_.FullName -Force
            $commands = Get-Command -Module $moduleName
            
            $moduleIndex.modules[$moduleName] = @{
                path = "/pwsh/modules/$moduleName/"
                manifestPath = $manifestPath
                functionCount = $commands.Count
                functions = $commands.Name
                lastModified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                version = (Get-Module $moduleName).Version.ToString()
            }
        } catch {
            Write-CustomLog "Failed to analyze module $moduleName: $_" "WARN"
        }
    }
}

$moduleIndex | ConvertTo-Json -Depth 5 | Set-Content "./MODULE-INDEX.json"
```

### Documentation Index Updates
```powershell
# Update documentation index
$docIndex = @{
    lastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    documents = @{}
}

# Scan documentation files
Get-ChildItem -Path "./docs/" -Filter "*.md" -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace((Get-Location).Path, "").TrimStart("\", "/")
    $content = Get-Content $_.FullName -Raw
    
    # Extract title from first heading
    $title = if ($content -match "^# (.+)$") { $matches[1] } else { $_.BaseName }
    
    # Extract description from content
    $description = if ($content -match "(?m)^## (?:Overview|Description)\s*\n(.+)$") { 
        $matches[1].Trim() 
    } else { 
        "Documentation for $($_.BaseName)" 
    }
    
    $docIndex.documents[$relativePath] = @{
        title = $title
        description = $description
        lastModified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        size = $_.Length
    }
}

$docIndex | ConvertTo-Json -Depth 5 | Set-Content "./DOCUMENTATION-INDEX.json"
```

## Cleanup and Organization

### Automated File Organization
```powershell
# Clean temporary files
Write-Host " Cleaning temporary files..." -ForegroundColor Yellow

# Remove temporary files
Get-ChildItem -Path "." -Recurse -Filter "*.tmp" | Remove-Item -Force
Get-ChildItem -Path "." -Recurse -Filter "*.bak" | Remove-Item -Force
Get-ChildItem -Path "." -Recurse -Filter "*~" | Remove-Item -Force

# Clean old log files (older than 7 days)
Get-ChildItem -Path "." -Recurse -Filter "*.log" | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-7)
} | Remove-Item -Force

# Archive old test results
$archiveThreshold = (Get-Date).AddDays(-30)
$archivePath = "./archive/test-results/$(Get-Date -Format 'yyyy-MM')"

Get-ChildItem -Path "./coverage/" -Recurse -Filter "*.xml" | Where-Object {
    $_.LastWriteTime -lt $archiveThreshold
} | ForEach-Object {
    if (-not (Test-Path $archivePath)) {
        New-Item -ItemType Directory -Path $archivePath -Force
    }
    Move-Item $_.FullName -Destination $archivePath
}

# Clean up duplicate files
./scripts/maintenance/Remove-DuplicateFiles.ps1 -Path "." -WhatIf:${input:whatIf}
```

### Backup Critical Files
```powershell
# Create timestamped backup
$backupPath = "./backups/maintenance-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force

# Backup critical files
$criticalFiles = @(
    "./PROJECT-MANIFEST.json",
    "./.vscode/settings.json", 
    "./configs/lab_config.yaml",
    "./.github/copilot-instructions.md"
)

foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
        Copy-Item $file -Destination $backupPath
        Write-CustomLog "Backed up: $file" "INFO"
    }
}

# Backup entire .github directory
Copy-Item "./.github/" -Destination "$backupPath/.github/" -Recurse

Write-CustomLog "Created backup at: $backupPath" "INFO"
```

## Health Monitoring and Logging

### Comprehensive Health Check
```powershell
# Run comprehensive health assessment
function Invoke-ProjectHealthCheck {
    Write-Host " Running comprehensive health check..." -ForegroundColor Cyan
    
    $healthReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        results = @{}
        issues = @()
        recommendations = @()
        overallScore = 0
    }
    
    # 1. Module Health
    try {
        Import-Module "/pwsh/modules/LabRunner/" -Force
        Import-Module "/pwsh/modules/CodeFixer/" -Force
        $healthReport.results.modules = @{
            status = "healthy"
            labRunner = (Get-Module LabRunner).Version.ToString()
            codeFixer = (Get-Module CodeFixer).Version.ToString()
        }
    } catch {
        $healthReport.results.modules = @{ status = "failed"; error = $_.Exception.Message }
        $healthReport.issues += "Module loading failed"
    }
    
    # 2. File Structure Health
    $expectedPaths = @(
        "./pwsh/modules/LabRunner/",
        "./pwsh/modules/CodeFixer/", 
        "./tests/helpers/",
        "./.github/workflows/",
        "./scripts/maintenance/"
    )
    
    $missingPaths = $expectedPaths | Where-Object { -not (Test-Path $_) }
    if ($missingPaths.Count -eq 0) {
        $healthReport.results.structure = @{ status = "healthy" }
    } else {
        $healthReport.results.structure = @{ status = "issues"; missing = $missingPaths }
        $healthReport.issues += "Missing critical directories: $($missingPaths -join ', ')"
    }
    
    # 3. Configuration Health
    try {
        $manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json
        Test-JsonConfig -Path "./PROJECT-MANIFEST.json"
        $healthReport.results.configuration = @{ status = "healthy"; version = $manifest.project.version }
    } catch {
        $healthReport.results.configuration = @{ status = "failed"; error = $_.Exception.Message }
        $healthReport.issues += "Configuration validation failed"
    }
    
    # 4. Code Quality Health
    try {
        $lintResult = Invoke-PowerShellLint -Path "./pwsh/" -PassThru -OutputFormat "JSON"
        $errorCount = ($lintResult | Where-Object { $_.Severity -eq "Error" }).Count
        $warningCount = ($lintResult | Where-Object { $_.Severity -eq "Warning" }).Count
        
        $healthReport.results.codeQuality = @{
            status = if ($errorCount -eq 0) { "healthy" } else { "issues" }
            errors = $errorCount
            warnings = $warningCount
        }
        
        if ($errorCount -gt 0) {
            $healthReport.issues += "Code quality issues: $errorCount errors, $warningCount warnings"
        }
    } catch {
        $healthReport.results.codeQuality = @{ status = "failed"; error = $_.Exception.Message }
    }
    
    # 5. Test Health
    try {
        $testFiles = Get-ChildItem -Path "./tests/" -Filter "*.ps1" | Measure-Object
        $healthReport.results.tests = @{
            status = "healthy"
            testFileCount = $testFiles.Count
        }
    } catch {
        $healthReport.results.tests = @{ status = "failed"; error = $_.Exception.Message }
    }
    
    # Calculate overall score
    $healthyComponents = ($healthReport.results.Values | Where-Object { $_.status -eq "healthy" }).Count
    $totalComponents = $healthReport.results.Count
    $healthReport.overallScore = [math]::Round(($healthyComponents / $totalComponents) * 100, 2)
    
    # Generate recommendations
    if ($healthReport.overallScore -lt 100) {
        $healthReport.recommendations += "Run './scripts/maintenance/unified-maintenance.ps1 -Mode All -AutoFix'"
        $healthReport.recommendations += "Address identified issues in priority order"
        $healthReport.recommendations += "Re-run health check after fixes"
    }
    
    # Save health report
    $healthReport | ConvertTo-Json -Depth 5 | Set-Content "./HEALTH-REPORT.json"
    
    # Log results
    Write-CustomLog "Health check completed. Score: $($healthReport.overallScore)%" "INFO"
    if ($healthReport.issues.Count -gt 0) {
        Write-CustomLog "Issues found: $($healthReport.issues -join '; ')" "WARN"
    }
    
    return $healthReport
}

# Run health check
$healthResult = Invoke-ProjectHealthCheck
```

### Issue Tracking Integration
```powershell
# Create maintenance issues for tracking
function New-MaintenanceIssue {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Severity = "Medium",
        [string[]]$AffectedFiles = @(),
        [string]$Category = "Maintenance"
    )
    
    $issueId = [Guid]::NewGuid().ToString("N")[0..7] -join ""
    $issue = @{
        id = $issueId
        title = $Title
        description = $Description
        severity = $Severity
        category = $Category
        affectedFiles = $AffectedFiles
        createdDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "Open"
        assignedTo = $env:USERNAME
        resolution = $null
        resolvedDate = $null
    }
    
    # Load existing issues
    $issuesFile = "./PROJECT-ISSUES.json"
    $issues = if (Test-Path $issuesFile) {
        Get-Content $issuesFile | ConvertFrom-Json
    } else {
        @()
    }
    
    # Add new issue
    $issues = @($issues) + $issue
    $issues | ConvertTo-Json -Depth 5 | Set-Content $issuesFile
    
    Write-CustomLog "Created maintenance issue: $Title (ID: $issueId)" "WARN"
    return $issueId
}

# Auto-create issues for health check problems
if ($healthResult.issues.Count -gt 0) {
    foreach ($issue in $healthResult.issues) {
        New-MaintenanceIssue -Title "Health Check Issue" -Description $issue -Severity "High" -Category "Health"
    }
}
```

## Continuous Validation

### Self-Validation Checks
```powershell
# Validate maintenance operation results
function Test-MaintenanceResults {
    param([string]$OperationType = "maintenance")
    
    Write-Host " Validating maintenance results..." -ForegroundColor Cyan
    
    $validationResults = @{
        operationType = $OperationType
        timestamp = Get-Date
        checks = @{}
        overallSuccess = $true
    }
    
    # 1. Verify modules still load correctly
    try {
        Remove-Module LabRunner, CodeFixer -Force -ErrorAction SilentlyContinue
        Import-Module "/pwsh/modules/LabRunner/" -Force
        Import-Module "/pwsh/modules/CodeFixer/" -Force
        $validationResults.checks.moduleLoading = $true
    } catch {
        $validationResults.checks.moduleLoading = $false
        $validationResults.overallSuccess = $false
        Write-CustomLog "Module loading validation failed: $_" "ERROR"
    }
    
    # 2. Verify configuration files are valid
    try {
        Test-JsonConfig -Path "./PROJECT-MANIFEST.json"
        $validationResults.checks.configValidation = $true
    } catch {
        $validationResults.checks.configValidation = $false
        $validationResults.overallSuccess = $false
        Write-CustomLog "Configuration validation failed: $_" "ERROR"
    }
    
    # 3. Verify critical paths exist
    $criticalPaths = @("./pwsh/modules/", "./tests/", "./.github/", "./scripts/")
    $allPathsExist = $criticalPaths | ForEach-Object { Test-Path $_ } | Where-Object { $_ -eq $false }
    $validationResults.checks.pathValidation = ($allPathsExist.Count -eq 0)
    
    if (-not $validationResults.checks.pathValidation) {
        $validationResults.overallSuccess = $false
        Write-CustomLog "Critical path validation failed" "ERROR"
    }
    
    # 4. Quick syntax check
    try {
        $syntaxErrors = Get-ChildItem -Path "./pwsh/" -Filter "*.ps1" -Recurse | ForEach-Object {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors)
            $errors
        } | Where-Object { $_ }
        
        $validationResults.checks.syntaxValidation = ($syntaxErrors.Count -eq 0)
        if ($syntaxErrors.Count -gt 0) {
            $validationResults.overallSuccess = $false
            Write-CustomLog "Syntax validation found $($syntaxErrors.Count) errors" "ERROR"
        }
    } catch {
        $validationResults.checks.syntaxValidation = $false
        $validationResults.overallSuccess = $false
    }
    
    # Save validation results
    $validationResults | ConvertTo-Json -Depth 5 | Set-Content "./MAINTENANCE-VALIDATION.json"
    
    # Log results
    if ($validationResults.overallSuccess) {
        Write-CustomLog "Maintenance validation passed" "INFO"
    } else {
        Write-CustomLog "Maintenance validation failed - issues detected" "ERROR"
        New-MaintenanceIssue -Title "Maintenance Validation Failed" -Description "Post-maintenance validation detected issues" -Severity "Critical"
    }
    
    return $validationResults
}

# Run validation after maintenance
$validationResult = Test-MaintenanceResults -OperationType ${input:operationType}
```

## Input Variables

- `${input:maintenanceLevel}`: Level of maintenance (quick, comprehensive, deep)
- `${input:operationType}`: Type of operation being performed
- `${input:versionType}`: Version increment type (patch, minor, major)
- `${input:whatIf}`: Whether to run in preview mode
- `${input:autoFix}`: Whether to apply automatic fixes

## Reference Instructions

This prompt references:
- [Maintenance Standards](../instructions/maintenance-standards.instructions.md)
- [PowerShell Standards](../instructions/powershell-standards.instructions.md)
- [Configuration Standards](../instructions/configuration-standards.instructions.md)

Please specify:
1. Level of maintenance needed (quick, comprehensive, deep)
2. Specific areas to focus on (modules, configuration, cleanup, validation)
3. Whether to apply automatic fixes or run in preview mode
4. Any specific issues or areas of concern to address

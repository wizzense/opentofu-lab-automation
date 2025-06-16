---
applyTo: "**"
description: Project maintenance, health checking, and continuous validation guidelines
---

# Project Maintenance Instructions

## Quick Reference

### Health Check Commands
| **Command**                                | **Purpose**                     |
|-------------------------------------------|----------------------------------|
| `./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"` | Quick health assessment         |
| `./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix` | Comprehensive health check      |
| `./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"` | YAML validation and formatting  |
| `Invoke-GitControlledPatch -DirectCommit -AutoCommitUncommitted` | Safe maintenance with proper change control |
| `Invoke-QuickRollback -RollbackType "Emergency" -Force` | Emergency recovery (respects branch protection) |

### Validation Sequence
Run:
```powershell
Import-Module "/pwsh/modules/CodeFixer/" -Force
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
Invoke-PowerShellLint -Path "./scripts/" -Parallel
Update-ProjectManifest -Changes $Changes
```

## Detailed Instructions

### Continuous Validation
After every change:
1. Import modules:
   ```powershell
   Import-Module "/pwsh/modules/LabRunner/" -Force
   Import-Module "/pwsh/modules/CodeFixer/" -Force
   ```
2. Run health checks:
   ```powershell
   ./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
   ```
3. Validate changes:
   ```powershell
   Invoke-PowerShellLint -Path $ChangedFiles -PassThru
   ```
4. Update manifest:
   ```powershell
   Update-ProjectManifest -Changes $Changes
   ```

## Project File Management

### PROJECT-MANIFEST.json Updates
Always update the project manifest after changes:

```powershell
# Read current manifest
$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json

# Update last modified
$manifest.project.lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Update module information if modules changed
if ($ModuleChanges) {
    $manifest.core.modules.$ModuleName.lastUpdated = (Get-Date -Format "yyyy-MM-dd")
    $manifest.core.modules.$ModuleName.keyFunctions = $UpdatedFunctions
}

# Save updated manifest
$manifest | ConvertTo-Json -Depth 10 | Set-Content "./PROJECT-MANIFEST.json"

# Validate manifest structure
Test-JsonConfig -Path "./PROJECT-MANIFEST.json"
```

### Index File Maintenance
Update project index files for discoverability:

```powershell
# Update module index
$moduleIndex = @{
    LastUpdated = Get-Date -Format "yyyy-MM-dd"
    Modules = @{
        CodeFixer = @{
            Path = "/pwsh/modules/CodeFixer/"
            Functions = (Get-Command -Module CodeFixer).Name
            LastModified = (Get-Item "/pwsh/modules/CodeFixer/").LastWriteTime
        }
        LabRunner = @{
            Path = "/pwsh/modules/LabRunner/"
            Functions = (Get-Command -Module LabRunner).Name
            LastModified = (Get-Item "/pwsh/modules/LabRunner/").LastWriteTime
        }
    }
}

$moduleIndex | ConvertTo-Json -Depth 5 | Set-Content "./MODULE-INDEX.json"
```

## Cleanup and Organization

### Automated Cleanup Procedures
```powershell
# 1. Clean temporary files
Get-ChildItem -Path "." -Recurse -Filter "*.tmp" | Remove-Item -Force
Get-ChildItem -Path "." -Recurse -Filter "*.log" -OlderThan (Get-Date).AddDays(-7) | Remove-Item -Force

# 2. Organize archive files
$archiveThreshold = (Get-Date).AddDays(-30)
Get-ChildItem -Path "./coverage/" -Recurse -File | Where-Object { 
    $_.LastWriteTime -lt $archiveThreshold 
} | Move-Item -Destination "./archive/coverage/"

# 3. Clean up test artifacts
Remove-Item "./TestResults*.xml" -Force -ErrorAction SilentlyContinue
Remove-Item "./coverage/lcov.info" -Force -ErrorAction SilentlyContinue

# 4. Validate file organization
./scripts/maintenance/organize-project-files.ps1 -ValidateOnly
```

### Backup Critical Files
```powershell
# Backup critical configuration
$backupPath = "./backups/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force

# Backup key files
Copy-Item "./PROJECT-MANIFEST.json" "$backupPath/"
Copy-Item "./.vscode/settings.json" "$backupPath/"
Copy-Item "./configs/" "$backupPath/" -Recurse
Copy-Item "./.github/" "$backupPath/" -Recurse

Write-CustomLog "Created backup at $backupPath" "INFO"
```

## Modern Change Control with PatchManager

### Reduced Backup Requirements
With PatchManager's advanced rollback capabilities, traditional backup frequency can be reduced:

#### Traditional Approach (High Backup Frequency)
- **Daily backups** required for safety
- **Manual rollback** process prone to errors
- **No audit trail** of changes
- **Limited recovery options**

#### PatchManager Approach (Low Backup Frequency)
- **Git-based change control** provides automatic versioning
- **Instant rollback** capabilities with multiple strategies
- **Complete audit trail** of all operations
- **Automated safety checks** before destructive operations

### Change Control Workflow
```powershell
# Standard workflow with built-in safety
Import-Module "/pwsh/modules/PatchManager/" -Force

# Apply changes with automatic backup
Invoke-GitControlledPatch -PatchDescription "maintenance: optimize performance" -PatchOperation {
    Optimize-SystemPerformance
} -DirectCommit -Force -CleanupMode "Standard"

# If issues detected, instant rollback
if (Test-SystemIssues) {
    Invoke-PatchRollback -RollbackTarget "LastCommit" -Force -ValidateAfterRollback
}
```

### Emergency Recovery Procedures
```powershell
# Level 1: Last commit rollback (safest)
Invoke-PatchRollback -RollbackTarget "LastCommit" -Force

# Level 2: Last working state (finds last validated commit)
Invoke-PatchRollback -RollbackTarget "LastWorkingState" -CreateBackup

# Level 3: Emergency rollback (resets to known good state)
Invoke-PatchRollback -RollbackTarget "Emergency" -Force -ValidateAfterRollback

# Level 4: Selective file recovery
Invoke-PatchRollback -RollbackTarget "SelectiveFiles" -AffectedFiles @("critical-file.ps1")
```

### Backup Strategy with PatchManager
| **Component** | **Traditional** | **With PatchManager** |
|---------------|----------------|----------------------|
| **Frequency** | Daily | Weekly (or on-demand) |
| **Scope** | Full system | Critical config only |
| **Recovery Time** | Hours | Seconds |
| **Accuracy** | Manual, error-prone | Automated, validated |
| **Audit Trail** | Limited | Complete |

## Logging and Issue Tracking

### Standardized Logging
```powershell
# Use Write-CustomLog for all operations
Import-Module "/pwsh/modules/LabRunner/" -Force

# Log maintenance operations
Write-CustomLog "Starting maintenance operation: $OperationType" "INFO"
Write-CustomLog "Processing files: $($Files.Count)" "INFO"

# Log validation results
Write-CustomLog "Validation completed: $PassedTests passed, $FailedTests failed" "INFO"

# Log errors with context
Write-CustomLog "Operation failed: $($_.Exception.Message)" "ERROR"
Write-CustomLog "Context: File=$CurrentFile, Line=$LineNumber" "DEBUG"
```

### Issue Tracking Integration
```powershell
# Create issue tracking entries
function New-MaintenanceIssue {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Severity = "Medium",
        [string[]]$AffectedFiles
    )
    
    $issue = @{
        Id = [Guid]::NewGuid().ToString()
        Title = $Title
        Description = $Description
        Severity = $Severity
        AffectedFiles = $AffectedFiles
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Status = "Open"
        AssignedTo = $env:USERNAME
    }
    
    $issuesFile = "./PROJECT-ISSUES.json"
    $issues = if (Test-Path $issuesFile) {
        Get-Content $issuesFile | ConvertFrom-Json
    } else {
        @()
    }
    
    $issues += $issue
    $issues | ConvertTo-Json -Depth 5 | Set-Content $issuesFile
    
    Write-CustomLog "Created issue: $Title (ID: $($issue.Id))" "WARN"
}

# Example usage
if ($ValidationErrors.Count -gt 0) {
    New-MaintenanceIssue -Title "Validation Errors Found" -Description "Multiple validation errors detected during maintenance" -Severity "High" -AffectedFiles $ErrorFiles
}
```

## Self-Validation Checks

### Validate Own Work
```powershell
# After any maintenance operation, validate the results
function Test-MaintenanceResults {
    param([string]$OperationType)
    
    Write-Host "Validating maintenance results..." -ForegroundColor Cyan
    
    # 1. Check project structure
    $structureValid = Test-ProjectStructure
    
    # 2. Validate modules still load
    try {
        Import-Module "/pwsh/modules/LabRunner/" -Force
        Import-Module "/pwsh/modules/CodeFixer/" -Force
        $modulesValid = $true
    } catch {
        $modulesValid = $false
        Write-CustomLog "Module loading failed after maintenance: $_" "ERROR"
    }
    
    # 3. Run quick syntax validation
    $syntaxValid = Invoke-PowerShellLint -Path "." -OutputFormat "JSON" -PassThru
    
    # 4. Validate configuration files
    $configValid = Test-JsonConfig -Path "./PROJECT-MANIFEST.json"
    
    # 5. Check test framework
    $testsValid = ./tests/Setup-TestingFramework.ps1 -Validate
    
    $results = @{
        OperationType = $OperationType
        Timestamp = Get-Date
        StructureValid = $structureValid
        ModulesValid = $modulesValid
        SyntaxValid = ($syntaxValid.Count -eq 0)
        ConfigValid = $configValid
        TestsValid = $testsValid
        OverallSuccess = ($structureValid -and $modulesValid -and $configValid -and $testsValid)
    }
    
    # Log results
    if ($results.OverallSuccess) {
        Write-CustomLog "Maintenance validation passed for $OperationType" "INFO"
    } else {
        Write-CustomLog "Maintenance validation failed for $OperationType" "ERROR"
        New-MaintenanceIssue -Title "Maintenance Validation Failed" -Description "Post-maintenance validation detected issues" -Severity "Critical"
    }
    
    return $results
}
```

### Performance Monitoring
```powershell
# Monitor maintenance operation performance
function Measure-MaintenancePerformance {
    param(
        [ScriptBlock]$Operation,
        [string]$OperationName
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $memoryBefore = [GC]::GetTotalMemory($false)
    
    try {
        $result = & $Operation
        $success = $true
    } catch {
        $success = $false
        $error = $_.Exception.Message
    }
    
    $stopwatch.Stop()
    $memoryAfter = [GC]::GetTotalMemory($false)
    
    $performance = @{
        OperationName = $OperationName
        Duration = $stopwatch.Elapsed
        MemoryUsed = $memoryAfter - $memoryBefore
        Success = $success
        Error = $error
        Timestamp = Get-Date
    }
    
    # Log performance metrics
    Write-CustomLog "Performance: $OperationName completed in $($performance.Duration.TotalSeconds)s" "INFO"
    
    if ($performance.Duration.TotalMinutes -gt 1) {
        Write-CustomLog "Performance warning: $OperationName took longer than expected" "WARN"
    }
    
    return $performance
}
```

## Quality Assurance Checks

### Pre-Commit Validation
```powershell
# Run before any commit
function Invoke-PreCommitValidation {
    Write-Host "Running pre-commit validation..." -ForegroundColor Green
    
    # 1. Lint all changed PowerShell files
    $changedFiles = git diff --name-only --cached | Where-Object { $_ -match '\.ps1$' }
    if ($changedFiles) {
        Invoke-PowerShellLint -Files $changedFiles -OutputFormat "CI"
    }
    
    # 2. Validate YAML files
    $changedYaml = git diff --name-only --cached | Where-Object { $_ -match '\.(yml|yaml)$' }
    if ($changedYaml) {
        foreach ($file in $changedYaml) {
            ./scripts/validation/Invoke-YamlValidation.ps1 -Path $file
        }
    }
    
    # 3. Update project manifest
    Update-ProjectManifest -IncrementalUpdate
    
    # 4. Run relevant tests
    $affectedModules = Get-AffectedModules -ChangedFiles $changedFiles
    if ($affectedModules) {
        Invoke-Pester -Path "./tests/" -Tag $affectedModules
    }
    
    # 5. Validate project health
    $healthCheck = ./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
    
    if ($healthCheck.TotalErrors -eq 0) {
        Write-Host "Pre-commit validation passed" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Pre-commit validation failed" -ForegroundColor Red
        return $false
    }
}
```

### Post-Operation Cleanup
```powershell
# Always run after maintenance operations
function Invoke-PostOperationCleanup {
    param([string]$OperationType)
    
    # 1. Clean temporary files created during operation
    Get-ChildItem -Path "." -Recurse -Filter "*.$OperationType.tmp" | Remove-Item -Force
    
    # 2. Reset any test artifacts
    Remove-Item "./TestResults*.xml" -Force -ErrorAction SilentlyContinue
    
    # 3. Update project statistics
    Update-ProjectStatistics
    
    # 4. Validate project health
    $validation = Test-MaintenanceResults -OperationType $OperationType
    
    # 5. Log completion
    Write-CustomLog "Completed $OperationType operation with cleanup" "INFO"
    
    return $validation
}
```

## Integration with CI/CD

### Continuous Integration Hooks
```powershell
# For GitHub Actions integration
function Invoke-CIValidation {
    # Run the same validation locally as in CI
    $env:CI = "true"
    
    # 1. Health check
    ./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -CI
    
    # 2. Comprehensive validation
    Import-Module "/pwsh/modules/CodeFixer/" -Force
    Invoke-ComprehensiveValidation -OutputFormat "CI" -FailOnWarning
    
    # 3. Security validation
    ./scripts/security/Invoke-SecurityValidation.ps1 -CI
    
    # 4. Performance benchmarks
    ./scripts/performance/Invoke-PerformanceBenchmarks.ps1
}
```

## GitHub Actions Integration and Cross-Platform Validation

### Multi-Platform Validation Workflow
Always validate changes across multiple operating systems using GitHub Actions:

```powershell
# Pre-commit GitHub Actions validation
function Invoke-CrossPlatformValidation {
    param(
        [string[]]$ChangedFiles,
        [string]$BranchName = (git branch --show-current)
    )
    
    Write-Host "Starting cross-platform validation..." -ForegroundColor Cyan
    
    # 1. Local validation first (fail fast)
    Write-Host "Running local validation..." -ForegroundColor Yellow
    $localResult = Invoke-LocalValidation -Files $ChangedFiles
    
    if (-not $localResult.Success) {
        throw "Local validation failed. Fix issues before GitHub Actions validation."
    }
    
    # 2. Push to trigger GitHub Actions workflows
    Write-Host "Pushing to GitHub to trigger workflows..." -ForegroundColor Yellow
    git push origin $BranchName
    
    # 3. Monitor workflow execution
    $workflowResult = Wait-ForWorkflowCompletion -Branch $BranchName -TimeoutMinutes 15
    
    if (-not $workflowResult.Success) {
        Write-Host "GitHub Actions validation failed:" -ForegroundColor Red
        foreach ($failure in $workflowResult.Failures) {
            Write-Host "  FAILED: $($failure.WorkflowName) - $($failure.Reason)" -ForegroundColor Red
        }
        return $false
    }
    
    Write-Host "Cross-platform validation completed successfully" -ForegroundColor Green
    return $true
}

function Wait-ForWorkflowCompletion {
    param(
        [string]$Branch,
        [int]$TimeoutMinutes = 15
    )
    
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $checkInterval = 30 # seconds
    
    do {
        try {
            # Get latest workflow runs for the branch
            $runs = gh run list --branch $Branch --limit 10 --json status,conclusion,workflowName,url
            
            if (-not $runs) {
                Write-Host "No workflow runs found yet..." -ForegroundColor Yellow
                Start-Sleep $checkInterval
                continue
            }
            
            $inProgress = $runs | Where-Object { $_.status -eq "in_progress" -or $_.status -eq "queued" }
            
            if ($inProgress.Count -eq 0) {
                # All workflows completed
                $failed = $runs | Where-Object { $_.conclusion -eq "failure" }
                $cancelled = $runs | Where-Object { $_.conclusion -eq "cancelled" }
                
                if ($failed.Count -gt 0 -or $cancelled.Count -gt 0) {
                    $failures = @()
                    foreach ($fail in $failed) {
                        $failures += @{
                            WorkflowName = $fail.workflowName
                            Reason = "Workflow failed"
                            Url = $fail.url
                        }
                    }
                    foreach ($cancel in $cancelled) {
                        $failures += @{
                            WorkflowName = $cancel.workflowName
                            Reason = "Workflow cancelled"
                            Url = $cancel.url
                        }
                    }
                    
                    return @{ Success = $false; Failures = $failures }
                } else {
                    return @{ Success = $true; Failures = @() }
                }
            }
            
            Write-Host "Waiting for $($inProgress.Count) workflow(s) to complete..." -ForegroundColor Yellow
            Start-Sleep $checkInterval
            
        } catch {
            Write-Host "Error checking workflow status: $_" -ForegroundColor Red
            Start-Sleep $checkInterval
        }
        
    } while ((Get-Date) -lt $timeout)
    
    return @{ 
        Success = $false
        Failures = @(@{ WorkflowName = "TIMEOUT"; Reason = "Workflow validation timed out after $TimeoutMinutes minutes" })
    }
}
```

### Fix-with-Validation Pattern
Always validate fixes before applying and revert if validation fails:

```powershell
# Safe fix application with automatic rollback
function Invoke-SafeFixApplication {
    param(
        [scriptblock]$FixOperation,
        [scriptblock]$ValidationOperation,
        [string]$FixDescription,
        [string[]]$AffectedFiles
    )
    
    Write-Host "Applying fix: $FixDescription" -ForegroundColor Cyan
    
    # 1. Create backup before applying fix
    $backupPath = New-MaintenanceBackup -BackupReason "Before fix: $FixDescription"
    
    # 2. Record current state
    $beforeState = Get-ProjectState -Files $AffectedFiles
    
    try {
        # 3. Apply the fix
        Write-Host "Executing fix operation..." -ForegroundColor Yellow
        $fixResult = & $FixOperation
        
        # 4. Validate the fix
        Write-Host "Validating fix results..." -ForegroundColor Yellow
        $validationResult = & $ValidationOperation
        
        if (-not $validationResult.Success) {
            throw "Fix validation failed: $($validationResult.Errors -join '; ')"
        }
        
        # 5. Run comprehensive validation
        Write-Host "Running comprehensive validation..." -ForegroundColor Yellow
        $comprehensiveResult = Invoke-ComprehensiveValidation -Path "." -AutoFix:$false
        
        if ($comprehensiveResult.TotalErrors -gt 0) {
            throw "Comprehensive validation failed with $($comprehensiveResult.TotalErrors) errors"
        }
        
        # 6. Test on multiple platforms if possible
        if (Test-GitHubActionsAvailable) {
            Write-Host "Triggering cross-platform validation..." -ForegroundColor Yellow
            $crossPlatformResult = Invoke-CrossPlatformValidation -ChangedFiles $AffectedFiles
            
            if (-not $crossPlatformResult) {
                throw "Cross-platform validation failed"
            }
        }
        
        Write-Host "Fix applied and validated successfully: $FixDescription" -ForegroundColor Green
        return @{ Success = $true; BackupPath = $backupPath }
        
    } catch {
        Write-Host "Fix failed validation: $_" -ForegroundColor Red
        Write-Host "Reverting changes..." -ForegroundColor Yellow
        
        # Revert changes
        Restore-FromBackup -BackupPath $backupPath -RestoreFiles $AffectedFiles
        
        # Log the failure
        Write-CustomLog "Fix failed and was reverted: $FixDescription - $_" "ERROR"
        New-MaintenanceIssue -IssueType "FixFailure" -Description "Fix failed validation: $FixDescription" -Severity "High" -Context @{
            Error = $_.Exception.Message
            AffectedFiles = $AffectedFiles
            BackupPath = $backupPath
        }
        
        return @{ Success = $false; Error = $_.Exception.Message; BackupPath = $backupPath }
    }
}

function Get-ProjectState {
    param([string[]]$Files)
    
    $state = @{
    }
    foreach ($file in $Files) {
        if (Test-Path $file) {
            $state[$file] = @{
                Hash = Get-FileHash $file -Algorithm SHA256
                LastWriteTime = (Get-Item $file).LastWriteTime
                Size = (Get-Item $file).Length
            }
        }
    }
    return $state
}

function Restore-FromBackup {
    param(
        [string]$BackupPath,
        [string[]]$RestoreFiles
    )
    
    foreach ($file in $RestoreFiles) {
        $backupFile = Join-Path $BackupPath (Split-Path $file -Leaf)
        if (Test-Path $backupFile) {
            Copy-Item $backupFile $file -Force
            Write-Host "Restored: $file" -ForegroundColor Yellow
        }
    }
}

function Test-GitHubActionsAvailable {
    try {
        $null = gh auth status 2>$null
        return $true
    } catch {
        return $false
    }
}
```

### Comprehensive Validation Integration
Integrate with existing validation systems:

```powershell
# Enhanced comprehensive validation with GitHub Actions
function Invoke-EnhancedValidation {
    param(
        [string]$Path = ".",
        [switch]$IncludeCrossPlatform,
        [switch]$AutoFix,
        [string]$OutputFormat = "Detailed"
    )
    
    $results = @{
        LocalValidation = $null
        CrossPlatformValidation = $null
        OverallSuccess = $false
        Timestamp = Get-Date
    }
    
    # 1. Local comprehensive validation
    Write-Host "Running local comprehensive validation..." -ForegroundColor Cyan
    $localResult = Invoke-ComprehensiveValidation -Path $Path -AutoFix:$AutoFix -OutputFormat $OutputFormat
    $results.LocalValidation = $localResult
    
    if ($localResult.TotalErrors -gt 0 -and -not $AutoFix) {
        Write-Host "Local validation failed. Use -AutoFix to attempt fixes." -ForegroundColor Red
        return $results
    }
    
    # 2. Cross-platform validation if requested and available
    if ($IncludeCrossPlatform -and (Test-GitHubActionsAvailable)) {
        Write-Host "Running cross-platform validation..." -ForegroundColor Cyan
        
        $changedFiles = git diff --name-only HEAD~1 HEAD
        if (-not $changedFiles) {
            $changedFiles = git diff --name-only --cached
        }
        
        if ($changedFiles) {
            $crossPlatformResult = Invoke-CrossPlatformValidation -ChangedFiles $changedFiles
            $results.CrossPlatformValidation = @{ Success = $crossPlatformResult }
        } else {
            Write-Host "No changed files detected for cross-platform validation" -ForegroundColor Yellow
            $results.CrossPlatformValidation = @{ Success = $true; Message = "No changes to validate" }
        }
    }
    
    # 3. Determine overall success
    $results.OverallSuccess = (
        $localResult.TotalErrors -eq 0 -and
        ($results.CrossPlatformValidation -eq $null -or $results.CrossPlatformValidation.Success)
    )
    
    if ($results.OverallSuccess) {
        Write-Host "Enhanced validation completed successfully" -ForegroundColor Green
    } else {
        Write-Host "Enhanced validation failed" -ForegroundColor Red
    }
    
    return $results
}
```

## Validation Standards with Multi-Platform Testing

### Cross-Platform Validation Requirements
All validation must work across Windows, Linux, and macOS:

```powershell
# Platform-specific validation patterns
function Invoke-PlatformSpecificValidation {
    param([string]$Platform = (Get-Platform))
    
    switch ($Platform) {
        "Windows" {
            # Windows-specific validations
            Test-WindowsPowerShellCompatibility
            Test-WindowsPathHandling
            Test-WindowsServiceIntegration
        }
        "Linux" {
            # Linux-specific validations
            Test-LinuxShellCompatibility
            Test-LinuxPermissions
            Test-LinuxPackageManagement
        }
        "macOS" {
            # macOS-specific validations
            Test-macOSCompatibility
            Test-macOSPermissions
            Test-macOSPackageManagement
        }
    }
}

function Test-WindowsPowerShellCompatibility {
    # Test both PowerShell Core and Windows PowerShell
    $powershellVersions = @("pwsh", "powershell")
    
    foreach ($ps in $powershellVersions) {
        if (Get-Command $ps -ErrorAction SilentlyContinue) {
            Write-Host "Testing with $ps..." -ForegroundColor Yellow
            $testResult = & $ps -Command "Import-Module '/pwsh/modules/LabRunner/' -Force; Get-Module LabRunner"
            if (-not $testResult) {
                throw "$ps compatibility test failed"
            }
        }
    }
}

function Test-LinuxShellCompatibility {
    # Test bash and sh compatibility
    $shells = @("bash", "sh")
    
    foreach ($shell in $shells) {
        if (Get-Command $shell -ErrorAction SilentlyContinue) {
            Write-Host "Testing with $shell..." -ForegroundColor Yellow
            $testScript = "#!/bin/$shell`necho 'Shell test successful'"
            $testScript | Set-Content "/tmp/shell-test.sh"
            chmod +x "/tmp/shell-test.sh"
            $result = & $shell "/tmp/shell-test.sh"
            if ($result -ne "Shell test successful") {
                throw "$shell compatibility test failed"
            }
        }
    }
}
```

### GitHub Actions Validation Integration
Validate commits by monitoring GitHub Actions workflow results:

```powershell
# Check GitHub Actions status before proceeding
function Test-GitHubActionsStatus {
    param(
        [string]$CommitSha,
        [string]$Repository = "origin"
    )
    
    Write-CustomLog "Checking GitHub Actions status for commit $CommitSha" "INFO"
    
    # Use GitHub CLI to check workflow status
    $workflowRuns = gh run list --commit $CommitSha --json status,conclusion,name
    $workflowData = $workflowRuns | ConvertFrom-Json
    
    $failedWorkflows = $workflowData | Where-Object { 
        $_.status -eq "completed" -and $_.conclusion -ne "success" 
    }
    
    if ($failedWorkflows.Count -gt 0) {
        Write-CustomLog "GitHub Actions validation failed for workflows: $($failedWorkflows.name -join ', ')" "ERROR"
        return $false
    }
    
    $pendingWorkflows = $workflowData | Where-Object { $_.status -ne "completed" }
    if ($pendingWorkflows.Count -gt 0) {
        Write-CustomLog "Waiting for GitHub Actions workflows to complete: $($pendingWorkflows.name -join ', ')" "WARN"
        return $null  # Pending status
    }
    
    Write-CustomLog "All GitHub Actions workflows passed" "INFO"
    return $true
}

# Validate fixes across multiple platforms via GitHub Actions
function Test-CrossPlatformFixes {
    param(
        [string[]]$ModifiedFiles,
        [string]$FixDescription
    )
    
    # Create backup before applying fixes
    $backupPath = New-MaintenanceBackup -BackupReason "Pre-fix validation backup"
    
    try {
        Write-CustomLog "Testing fixes across platforms via GitHub Actions" "INFO"
        
        # Apply fixes locally first
        foreach ($file in $ModifiedFiles) {
            Write-CustomLog "Applying fix to $file" "INFO"
            # Apply fix logic here
        }
        
        # Commit changes temporarily
        $tempCommitSha = git rev-parse HEAD
        git add .
        git commit -m "temp: Test fixes for validation - $FixDescription"
        git push origin HEAD
        
        # Wait for and check GitHub Actions
        Start-Sleep 30  # Allow workflows to start
        
        $maxWaitTime = 600  # 10 minutes maximum wait
        $waitTime = 0
        
        do {
            $status = Test-GitHubActionsStatus -CommitSha (git rev-parse HEAD)
            
            if ($status -eq $true) {
                Write-CustomLog "Cross-platform validation passed - fixes are valid" "INFO"
                return $true
            } elseif ($status -eq $false) {
                Write-CustomLog "Cross-platform validation failed - reverting fixes" "ERROR"
                
                # Revert changes
                git reset --hard $tempCommitSha
                git push origin HEAD --force
                
                # Restore from backup if needed
                Restore-MaintenanceBackup -BackupPath $backupPath
                
                return $false
            }
            
            # Still pending - wait more
            Start-Sleep 30
            $waitTime += 30
            
        } while ($waitTime -lt $maxWaitTime)
        
        Write-CustomLog "GitHub Actions validation timed out - reverting as safety measure" "WARN"
        git reset --hard $tempCommitSha
        git push origin HEAD --force
        return $false
        
    } catch {
        Write-CustomLog "Error during cross-platform validation: $($_.Exception.Message)" "ERROR"
        
        # Emergency rollback
        if (Test-Path $backupPath) {
            Restore-MaintenanceBackup -BackupPath $backupPath
        }
        
        throw
    }
}
```

### Comprehensive Fix Validation Pipeline
Implement comprehensive validation with automatic revert on failure:

```powershell
# Comprehensive fix validation with revert capability
function Invoke-ValidatedFix {
    param(
        [scriptblock]$FixOperation,
        [string]$FixDescription,
        [string[]]$AffectedFiles,
        [switch]$RequireCrossPlatform
    )
    
    Write-CustomLog "Starting validated fix operation: $FixDescription" "INFO"
    
    # Phase 1: Create backup and baseline
    $backupPath = New-MaintenanceBackup -BackupReason "Validated fix: $FixDescription"
    $baselineHealth = ./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
    
    try {
        # Phase 2: Apply fix
        Write-CustomLog "Applying fix: $FixDescription" "INFO"
        $fixResult = & $FixOperation
        
        # Phase 3: Local validation
        Write-CustomLog "Running local validation" "INFO"
        
        # Syntax validation
        foreach ($file in $AffectedFiles) {
            if ($file -match '\.ps1$') {
                $syntaxValid = Test-PowerShellSyntax -Path $file
                if (-not $syntaxValid) {
                    throw "PowerShell syntax validation failed for $file"
                }
            }
        }
        
        # Module import validation
        try {
            Import-Module "/pwsh/modules/LabRunner/" -Force
            Import-Module "/pwsh/modules/CodeFixer/" -Force
        } catch {
            throw "Module import validation failed after fix: $($_.Exception.Message)"
        }
        
        # Health check validation
        $postFixHealth = ./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
        if ($postFixHealth.TotalErrors -gt $baselineHealth.TotalErrors) {
            throw "Health check regression detected: errors increased from $($baselineHealth.TotalErrors) to $($postFixHealth.TotalErrors)"
        }
        
        # Phase 4: Cross-platform validation (if required)
        if ($RequireCrossPlatform) {
            Write-CustomLog "Running cross-platform validation via GitHub Actions" "INFO"
            $crossPlatformValid = Test-CrossPlatformFixes -ModifiedFiles $AffectedFiles -FixDescription $FixDescription
            
            if (-not $crossPlatformValid) {
                throw "Cross-platform validation failed"
            }
        }
        
        # Phase 5: Integration testing
        Write-CustomLog "Running integration tests" "INFO"
        $testResults = Invoke-Pester -Path "./tests/" -Tag "Integration" -PassThru
        if ($testResults.FailedCount -gt 0) {
            throw "Integration tests failed: $($testResults.FailedCount) failures"
        }
        
        # Success - cleanup backup
        Remove-Item $backupPath -Recurse -Force
        Write-CustomLog "Fix validation completed successfully: $FixDescription" "INFO"
        
        return @{
            Success = $true
            FixResult = $fixResult
            HealthImprovement = $baselineHealth.TotalErrors - $postFixHealth.TotalErrors
        }
        
    } catch {
        Write-CustomLog "Fix validation failed: $($_.Exception.Message)" "ERROR"
        Write-CustomLog "Reverting changes and restoring from backup" "WARN"
        
        # Revert changes
        try {
            Restore-MaintenanceBackup -BackupPath $backupPath
            
            # Verify restoration
            $restoredHealth = ./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
            if ($restoredHealth.TotalErrors -le $baselineHealth.TotalErrors) {
                Write-CustomLog "Successfully reverted to baseline state" "INFO"
            } else {
                Write-CustomLog "WARNING: Restoration may be incomplete" "ERROR"
            }
            
        } catch {
            Write-CustomLog "CRITICAL: Failed to restore from backup: $($_.Exception.Message)" "ERROR"
            throw "Fix failed and restoration failed - manual intervention required"
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            BackupRestored = $true
        }
    }
}

# Usage example for validated fixes
$fixResult = Invoke-ValidatedFix -FixOperation {
    # Your fix operation here
    Invoke-PowerShellLint -Path "./scripts/" -AutoFix
} -FixDescription "PowerShell linting auto-fixes" -AffectedFiles @("./scripts/") -RequireCrossPlatform

if (-not $fixResult.Success) {
    Write-CustomLog "Fix operation failed and was reverted: $($fixResult.Error)" "ERROR"
}
```

## YAML Workflow Validation

### Current Status
The project uses two primary workflow files that are fully validated:
- `mega-consolidated.yml` - Main consolidated workflow (YAML valid)
- `mega-consolidated-fixed.yml` - Alternative consolidated workflow (YAML valid)

### Legacy Workflow Files
Several legacy workflow files in `.github/workflows/` have structural YAML syntax errors:
- `archive-legacy-workflows.yml`
- `auto-merge.yml` 
- `changelog.yml`
- `copilot-auto-fix.yml`
- `issue-on-fail.yml`
- `package-labctl.yml`
- `release.yml`
- `validate-workflows.yml`

These files should be considered for archival or complete rewrite as they contain fundamental YAML structure issues that prevent proper parsing.

### YAML Validation Integration
YAML validation is integrated into maintenance scripts but **AUTO-FIX IS DISABLED** due to previous corruption issues:

- **Pre-commit validation**: `git diff --cached | grep -E '\.(yml|yaml)$'` files validated (check only)
- **Maintenance scripts**: `./scripts/maintenance/unified-maintenance.ps1` includes YAML validation (check only)  
- **Health checks**: `./scripts/validation/health-check.ps1` includes YAML validation (check only)
- **Final validation**: `./scripts/final-validation.ps1` includes YAML validation (check only)
- **VS Code tasks**: YAML validation available through task runner (check only)

[WARN]️ **IMPORTANT**: YAML auto-fix is permanently disabled due to corruption issues. Use manual fixes only.

### Validation Commands
```powershell
# SAFE: Check YAML syntax only
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Check" -Path ".github/workflows"

# SAFE: Use yamllint directly
yamllint ".github/workflows/mega-consolidated.yml"

# SAFE: Comprehensive maintenance (auto-fix disabled)
./scripts/maintenance/unified-maintenance.ps1 -Mode "All"

# DANGEROUS: Never use auto-fix mode (disabled)
# ./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"  # DISABLED
```

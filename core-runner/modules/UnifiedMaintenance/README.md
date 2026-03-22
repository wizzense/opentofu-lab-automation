# UnifiedMaintenance Module

Unified maintenance module for OpenTofu Lab Automation with integrated testing, health monitoring, issue tracking, and continuous monitoring capabilities.

## Overview

The UnifiedMaintenance module provides a centralized interface for all maintenance operations across the project. It orchestrates testing, health checks, issue tracking, and continuous monitoring, integrating with all other modules.

## Features

- **Unified maintenance workflows** - Single interface for all maintenance tasks
- **Automated test execution** - Integrated testing workflows
- **Infrastructure health monitoring** - System health checks
- **Recurring issue tracking** - Identify and track recurring problems
- **Continuous monitoring** - Long-running health monitoring
- **Module integration** - Coordinates all project modules
- **Automated reporting** - Generate maintenance reports

## Installation

```powershell
Import-Module "./core-runner/modules/UnifiedMaintenance" -Force
```

## Functions

### Invoke-UnifiedMaintenance

Main entry point for all maintenance operations.

```powershell
# Run all maintenance tasks
Invoke-UnifiedMaintenance -Mode "All"

# Run specific maintenance mode
Invoke-UnifiedMaintenance -Mode "Quick"
Invoke-UnifiedMaintenance -Mode "Full"
Invoke-UnifiedMaintenance -Mode "Emergency"

# Run with auto-fix enabled
Invoke-UnifiedMaintenance -Mode "Full" -AutoFix

# Generate report
Invoke-UnifiedMaintenance -Mode "All" -GenerateReport -ReportPath "./reports/maintenance-report.html"

# Dry run (preview only)
Invoke-UnifiedMaintenance -Mode "Full" -WhatIf
```

**Maintenance Modes:**
- **Quick**: Basic health checks and quick tests
- **Full**: Comprehensive maintenance including backups, tests, and health checks
- **Emergency**: Aggressive cleanup and recovery operations
- **All**: Everything including long-running operations

**Parameters:**
- **Mode** (Required): Maintenance mode to run
- **AutoFix**: Automatically fix issues when possible
- **GenerateReport**: Create maintenance report
- **ReportPath**: Path for generated report
- **WhatIf**: Preview operations without executing

### Invoke-AutomatedTestWorkflow

Executes automated testing workflows.

```powershell
# Run complete test workflow
Invoke-AutomatedTestWorkflow

# Run with parallel execution
Invoke-AutomatedTestWorkflow -EnableParallel -MaxThreads 4

# Run specific test suite
Invoke-AutomatedTestWorkflow -TestSuite "Unit"

# Run with coverage report
Invoke-AutomatedTestWorkflow -GenerateCoverage -CoverageThreshold 80
```

**Test Workflow Includes:**
- Unit tests
- Integration tests
- Syntax validation
- Module tests
- Coverage analysis

### Invoke-InfrastructureHealth

Performs infrastructure health checks.

```powershell
# Check infrastructure health
$health = Invoke-InfrastructureHealth

# Display health status
Write-Host "Overall Health: $($health.Status)"
$health.Checks | ForEach-Object {
    $color = if ($_.Passed) { "Green" } else { "Red" }
    Write-Host "  $($_.Name): $($_.Status)" -ForegroundColor $color
}

# Health check with auto-repair
Invoke-InfrastructureHealth -AutoRepair

# Detailed health check
Invoke-InfrastructureHealth -Detailed
```

**Health Checks:**
- Module availability and loading
- Configuration file validity
- Disk space and resources
- Service status
- Network connectivity
- Git repository health

### Invoke-RecurringIssueTracking

Identifies and tracks recurring issues.

```powershell
# Track recurring issues
$issues = Invoke-RecurringIssueTracking

# Display recurring issues
$issues | ForEach-Object {
    Write-Host "Issue: $($_.Description)"
    Write-Host "  Occurrences: $($_.Count)"
    Write-Host "  Last seen: $($_.LastOccurrence)"
}

# Track with auto-create GitHub issues
Invoke-RecurringIssueTracking -CreateGitHubIssues

# Track for specific timeframe
Invoke-RecurringIssueTracking -Since (Get-Date).AddDays(-7)
```

**Tracks:**
- Test failures
- Build failures
- Module import errors
- Configuration issues
- Resource exhaustion

### Start-ContinuousMonitoring

Starts continuous health monitoring in the background.

```powershell
# Start monitoring with default interval (5 minutes)
Start-ContinuousMonitoring

# Start with custom interval
Start-ContinuousMonitoring -IntervalMinutes 10

# Start with alerting
Start-ContinuousMonitoring -EnableAlerts -AlertThreshold "Warning"

# Start with custom checks
Start-ContinuousMonitoring -Checks @("DiskSpace", "Services", "ModuleHealth")
```

**Monitoring Features:**
- Background execution
- Periodic health checks
- Alert generation
- Log collection
- Automatic issue creation

## Usage Examples

### Daily Maintenance Routine

```powershell
# Import module
Import-Module "./core-runner/modules/UnifiedMaintenance" -Force

Write-Host "Starting daily maintenance..." -ForegroundColor Cyan

# Run full maintenance with auto-fix
$result = Invoke-UnifiedMaintenance -Mode "Full" -AutoFix -GenerateReport

# Check results
if ($result.Status -eq "Success") {
    Write-Host "Maintenance completed successfully" -ForegroundColor Green
} else {
    Write-Warning "Maintenance completed with issues"
    $result.Issues | ForEach-Object {
        Write-Warning "  $_"
    }
}

# Check for recurring issues
Write-Host "`nChecking for recurring issues..." -ForegroundColor Cyan
$recurringIssues = Invoke-RecurringIssueTracking

if ($recurringIssues.Count -gt 0) {
    Write-Warning "Found $($recurringIssues.Count) recurring issues"
    Invoke-RecurringIssueTracking -CreateGitHubIssues
}
```

### Quick Health Check

```powershell
# Quick health check before deployment
Write-Host "Performing pre-deployment health check..." -ForegroundColor Cyan

$health = Invoke-InfrastructureHealth

if ($health.Status -eq "Healthy") {
    Write-Host "System healthy - ready for deployment" -ForegroundColor Green
    
    # Proceed with deployment
    # ...
} else {
    Write-Error "Health check failed - aborting deployment"
    $health.Checks | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Error "  Failed: $($_.Name) - $($_.Message)"
    }
    
    exit 1
}
```

### Automated Test Workflow

```powershell
# Complete test workflow
Write-Host "Running automated test workflow..." -ForegroundColor Cyan

$testResult = Invoke-AutomatedTestWorkflow `
    -EnableParallel `
    -MaxThreads 4 `
    -GenerateCoverage `
    -CoverageThreshold 80

# Report results
Write-Host "`nTest Results:" -ForegroundColor Cyan
Write-Host "  Total: $($testResult.TotalCount)"
Write-Host "  Passed: $($testResult.PassedCount)" -ForegroundColor Green
Write-Host "  Failed: $($testResult.FailedCount)" -ForegroundColor $(if ($testResult.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Coverage: $($testResult.CodeCoverage)%"

if ($testResult.CodeCoverage -lt 80) {
    Write-Warning "Code coverage below threshold (80%)"
}
```

### Emergency Recovery

```powershell
# Emergency maintenance and recovery
Write-Host "Running emergency recovery..." -ForegroundColor Red

try {
    # Emergency mode with auto-fix
    $result = Invoke-UnifiedMaintenance -Mode "Emergency" -AutoFix
    
    # Verify recovery
    $health = Invoke-InfrastructureHealth
    
    if ($health.Status -eq "Healthy") {
        Write-Host "Recovery successful" -ForegroundColor Green
    } else {
        Write-Warning "Manual intervention may be required"
        $health.Checks | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Warning "  Issue: $($_.Name)"
        }
    }
} catch {
    Write-Error "Emergency recovery failed: $($_.Exception.Message)"
    Write-Host "Please review logs and perform manual recovery"
}
```

### Continuous Monitoring Setup

```powershell
# Set up continuous monitoring for production
Write-Host "Starting continuous monitoring..." -ForegroundColor Cyan

Start-ContinuousMonitoring `
    -IntervalMinutes 5 `
    -EnableAlerts `
    -AlertThreshold "Warning" `
    -Checks @(
        "DiskSpace",
        "Services",
        "ModuleHealth",
        "NetworkConnectivity",
        "ResourceUsage"
    )

Write-Host "Monitoring started - running in background" -ForegroundColor Green
Write-Host "Alerts will be generated for any issues detected"

# Monitor will continue running until stopped
# To stop: Stop-ContinuousMonitoring
```

## Maintenance Workflows

### Quick Maintenance Workflow

```
1. Module health check
2. Configuration validation
3. Quick smoke tests
4. Disk space check
5. Generate summary report
```

### Full Maintenance Workflow

```
1. Backup critical files
2. Clean old backups
3. Module health check
4. Configuration validation
5. Full test suite execution
6. Infrastructure health check
7. Log file rotation
8. Update .gitignore/.psakfile
9. Generate comprehensive report
```

### Emergency Maintenance Workflow

```
1. Stop non-critical services
2. Clean temporary files
3. Reset problematic modules
4. Restore from backups if needed
5. Force module reload
6. Clear caches
7. Restart services
8. Verify system health
```

## Integration with Other Modules

### BackupManager Integration

```powershell
# Maintenance includes backup operations
Invoke-UnifiedMaintenance -Mode "Full"
# Automatically runs:
# - Invoke-BackupConsolidation
# - Invoke-PermanentCleanup
# - Get-BackupStatistics
```

### TestingFramework Integration

```powershell
# Maintenance includes test execution
Invoke-AutomatedTestWorkflow
# Automatically runs:
# - Invoke-UnifiedTestExecution
# - Invoke-ParallelTests
# - Generate test reports
```

### PatchManager Integration

```powershell
# Track recurring issues and create patches
Invoke-RecurringIssueTracking -CreateGitHubIssues
# Automatically:
# - Identifies recurring problems
# - Creates GitHub issues
# - Can trigger patch workflows
```

## Reporting

### Generate Maintenance Report

```powershell
# Generate HTML report
Invoke-UnifiedMaintenance -Mode "Full" -GenerateReport -ReportPath "./reports/maintenance.html"

# Report includes:
# - Maintenance tasks performed
# - Test results
# - Health check status
# - Issues found and fixed
# - Recommendations
```

### Report Formats

- **HTML**: Comprehensive web-based report
- **JSON**: Machine-readable for automation
- **Markdown**: Documentation-friendly format
- **Text**: Simple console output

## Scheduling Maintenance

### Windows Task Scheduler

```powershell
# Create scheduled task for daily maintenance
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File C:/automation/run-maintenance.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "DailyMaintenance" -Action $action -Trigger $trigger
```

### Linux Cron

```bash
# Add to crontab for daily 2am execution
0 2 * * * pwsh -File /opt/automation/run-maintenance.ps1
```

### CI/CD Integration

```yaml
# GitHub Actions workflow
name: Maintenance
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2am
jobs:
  maintenance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Maintenance
        run: pwsh -File ./run-maintenance.ps1
```

## Best Practices

1. **Run Quick maintenance daily** for routine health checks
2. **Run Full maintenance weekly** for comprehensive upkeep
3. **Reserve Emergency mode** for actual emergencies only
4. **Enable auto-fix** for automated scenarios
5. **Generate reports** for audit trails
6. **Monitor continuously** in production environments
7. **Track recurring issues** to identify patterns
8. **Review reports regularly** to catch trends

## Troubleshooting

### Maintenance fails
- Check logs in `./logs/`
- Review health check results
- Verify module availability
- Check disk space and permissions

### Tests fail during maintenance
- Run tests individually to isolate issue
- Check test configuration
- Verify test data availability
- Review test logs

### Monitoring not alerting
- Verify alert configuration
- Check monitoring is running: `Get-Job`
- Review alert thresholds
- Test alert mechanisms

## Version History

- **1.0.0**: Initial release with integrated maintenance, testing, and monitoring

## Related Modules

- [BackupManager](../BackupManager/) - Backup and cleanup operations
- [TestingFramework](../TestingFramework/) - Test execution and reporting
- [LabRunner](../LabRunner/) - Lab automation operations
- [Logging](../Logging/) - Centralized logging
- [PatchManager](../PatchManager/) - Issue tracking and patching

## Contributing

When adding maintenance features:

1. Integrate with existing workflows
2. Support all maintenance modes
3. Include comprehensive logging
4. Test automated scenarios
5. Update this README and maintenance documentation

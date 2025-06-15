# OpenTofu Lab Automation - Copilot Configuration

## Health Check and Maintenance Commands

### Quick Validation
```powershell
./scripts/maintenance/Invoke-UnifiedHealthCheck.ps1 -Mode Quick
```

### Full Analysis with Auto-Fix
```powershell
./scripts/maintenance/Invoke-UnifiedHealthCheck.ps1 -Mode All -AutoFix
```

### Infrastructure-Only Check
```powershell
./scripts/maintenance/Invoke-UnifiedHealthCheck.ps1 -Mode Infrastructure
```

### Workflow-Only Check
```powershell
./scripts/maintenance/Invoke-UnifiedHealthCheck.ps1 -Mode Workflow
```

## Report Locations
- Unified Health Reports: `./reports/unified-health/`
- Infrastructure Reports: `./reports/infrastructure-health/`
- Workflow Reports: `./reports/workflow-health/`

## Available Tools
1. `Analyze-InfrastructureHealth.ps1` - Deep infrastructure analysis
2. `Analyze-WorkflowHealth.ps1` - GitHub Actions workflow analysis
3. `Invoke-UnifiedHealthCheck.ps1` - Combined health check system

## VS Code Tasks
- "Quick Health Check" - Basic validation
- "Full Health Analysis" - Comprehensive check with fixes
- "Run Infrastructure Health" - Infrastructure focus
- "Run Workflow Health" - Workflow focus

## GitHub Actions Integration
The `unified-health-monitor.yml` workflow automates health checks:
- Runs quick checks on push/PR
- Full analysis every 6 hours
- Manual trigger available
- Creates issues for failures

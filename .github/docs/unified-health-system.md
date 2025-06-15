# OpenTofu Lab Automation - Health Check & Maintenance System

## Overview
The project uses a unified health check and maintenance system through the following key components:

1. **Invoke-UnifiedHealthCheck.ps1** - Single entry point for all health checks
2. **Analyze-InfrastructureHealth.ps1** - Infrastructure analysis
3. **Analyze-WorkflowHealth.ps1** - Workflow analysis
4. **unified-maintenance.ps1** - Maintenance automation

## Quick Commands

### Basic Health Check
```powershell
./scripts/maintenance/Invoke-UnifiedHealthCheck.ps1 -Mode Quick
```

### Full System Analysis
```powershell
./scripts/maintenance/Invoke-UnifiedHealthCheck.ps1 -Mode All -AutoFix
```

### CI/CD Integration
The `unified-health-monitor.yml` workflow automatically runs health checks:
- Quick check on pushes and PRs
- Full check every 6 hours
- Manual trigger available

## Health Check Modes

| Mode | Description |
|------|-------------|
| Quick | Basic validation of critical components |
| Full | Comprehensive check of infrastructure and workflows |
| Infrastructure | Focus on codebase and module health |
| Workflow | Focus on GitHub Actions workflows |
| All | Complete analysis with detailed reporting |

## AutoFix Capabilities

The `-AutoFix` parameter enables automatic fixes for common issues:
- Import path corrections
- Module reference updates
- Workflow syntax fixes
- Configuration standardization

## Report Formats

Reports can be generated in multiple formats:
- Markdown (default)
- JSON
- Console output

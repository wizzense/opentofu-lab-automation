# Root Directory Cleanup Summary - 2025-06-13

## Scripts Moved/Archived

### Organization Scripts → archive/maintenance-scripts/
- organize-project.ps1
- organize-project-fixed.ps1  
- cleanup-remaining.ps1

### Empty Scripts → Removed
- clean-workflows.ps1 (empty)
- comprehensive-syntax-checker.ps1 (empty)
- enhanced-fix-labrunner.ps1 (empty)
- fix-*.ps1 files (empty/obsolete)
- run-*.ps1 files (empty/obsolete)
- test-*.ps1 files (empty/obsolete)

### Configuration Files → Appropriate Locations
- test-config-errors.json → tests/data/
- workflow-optimization-report.json → reports/

### Backup Directories → backups/
- cleanup-backup-* directories moved to backups/

## Files That Should Remain in Root

### Essential Project Files
- AGENTS.md, CHANGELOG.md, README.md, LICENSE
- .gitignore, .github/, .vscode/

### Primary Directories
- docs/, scripts/, tests/, pwsh/, py/, tools/
- configs/, archive/, backups/

### Legacy Directories (to be gradually cleaned)
- LabRunner/ (old location - being migrated)
- reports/ (old location - content moved to docs/reports/)

## Maintenance Commands

Use the unified maintenance system instead of individual scripts:

```powershell
# Quick health check
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Quick"

# Full maintenance
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix

# Issue tracking  
./scripts/maintenance/track-recurring-issues.ps1 -Mode "All"
```

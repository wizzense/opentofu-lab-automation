# AGENTS.md (Optimized for Cross-Platform & Automation)

## Project Agent & Automation Guidelines

### Key Principles
- **Always use platform-agnostic paths** (PowerShell: `Join-Path`, Python: `os.path.join`).
- **Run all maintenance and validation via unified scripts** in `/scripts/maintenance/`.
- **Never hardcode Linux or Windows paths**; always detect platform or use relative paths.
- **Automate issue tracking**: All test/maintenance failures should be logged to the issues tracker.
- **Menu/CLI/GUI must support repo re-clone and refresh.**

### Daily Agent Workflow
```powershell
# Quick health check (cross-platform)
pwsh -File scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Full maintenance with fixes
pwsh -File scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix

# Run all tests
pwsh -File scripts/testing/run-all-tests.ps1
```

### Maintenance & Cleanup
- Use `unified-maintenance.ps1` for all cleanup and validation.
- Use `cleanup-root-scripts.ps1` and `cleanup-duplicate-directories.ps1` for deep cleanup.
- Always generate a report after major maintenance:  
  `pwsh -File scripts/utilities/new-report.ps1 -Type "test-analysis" -Title "Maintenance Report"`

### Issue Tracking
- All test failures and maintenance warnings should be parsed and logged to the issues tracker automatically.
- Manual issues should be added only for new/unknown problems.

### Cross-Platform Notes
- All scripts must work on both Windows and Linux.
- Use `$PSScriptRoot` and `Join-Path` in PowerShell for all file operations.
- Use `os.path.join` in Python.
- **Test for platform at runtime** and adjust paths accordingly.

### Repo Refresh
- Add a CLI and GUI menu option to re-clone the repo and refresh the menu.

---
## 🕒 Agent Running Log
- **2025-06-13 23:30** – Updated agent guidelines for cross-platform, clarified automation, and added running log section. Next: ensure all scripts/platforms are supported and issue tracking is automated.

---
*Last updated: 2025-06-13 by GitHub Copilot*

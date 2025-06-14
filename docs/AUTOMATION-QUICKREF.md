# Automation Quick Reference

Quick reference for AI agents, developers, and automated systems working on the OpenTofu Lab Automation project.

## Critical Rules

### [FAIL] NEVER DO
- Create `.md` summary files in project root directory
- Use deprecated `pwsh/lab_utils/` import paths
- Edit files without running validation afterwards
- Skip report generation for significant changes (>5 files)

### [PASS] ALWAYS DO
- Use report utility: `./scripts/utilities/new-report.ps1`
- Validate after changes: Run appropriate validation scripts
- Update CHANGELOG.md for major changes
- Import modules with full paths: `/workspaces/opentofu-lab-automation/pwsh/modules/ModuleName`

## Quick Commands

### Create New Report
```powershell
# Test analysis report
./scripts/utilities/new-report.ps1 -Type "test-analysis" -Title "Test Infrastructure Updates" -Template "test"

# Workflow analysis report 
./scripts/utilities/new-report.ps1 -Type "workflow-analysis" -Title "CI Pipeline Optimization" -Template "workflow"

# Project status report
./scripts/utilities/new-report.ps1 -Type "project-status" -Title "Module Integration Complete" -Template "project"
```

### Project Validation
```powershell
# Quick validation
./run-final-validation.ps1

# Comprehensive validation
./scripts/maintenance/auto-maintenance.ps1 -Task "validate"

# Full maintenance cycle
./scripts/maintenance/auto-maintenance.ps1 -Task "full" -GenerateReport
```

### Fix Common Issues
```powershell
# Load CodeFixer and fix imports
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer"
Invoke-ImportAnalysis -AutoFix
Invoke-ComprehensiveValidation

# Automated import fixes
./scripts/maintenance/auto-maintenance.ps1 -Task "fix-imports"
```

### Health Monitoring
```powershell
# Project health check with report
./scripts/maintenance/auto-maintenance.ps1 -Task "check-health" -GenerateReport

# Workflow health check
./scripts/workflow-health-check.sh

# Test health check
./run-comprehensive-tests.ps1
```

## � Directory Structure (Key Paths)

```
/workspaces/opentofu-lab-automation/
├── docs/reports/ # [PASS] All reports go here
│ ├── test-analysis/ # Test & validation reports
│ ├── workflow-analysis/ # CI/CD & workflow reports 
│ ├── project-status/ # Milestone & status reports
│ ├── README.md # Report templates & guidelines
│ └── INDEX.md # Report index & quick links
├── pwsh/modules/ # [PASS] Current module location
│ ├── LabRunner/ # [PASS] Use this path
│ └── CodeFixer/ # [PASS] Use this path
├── pwsh/lab_utils/ # [FAIL] DEPRECATED - Don't use
├── scripts/
│ ├── utilities/new-report.ps1 # [PASS] Report generation utility
│ ├── maintenance/auto-maintenance.ps1 # [PASS] Automated maintenance
│ └── validation/ # Validation scripts
└── .github/copilot-instructions.md # Agent guidelines
```

## Workflow Integration

### After Module Changes
1. `Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer"`
2. `Invoke-ComprehensiveValidation`
3. `Invoke-ImportAnalysis -AutoFix`
4. Generate report if significant issues found

### After Test Changes
1. `./run-comprehensive-tests.ps1`
2. `./scripts/validation/validate-powershell-scripts.ps1`
3. Generate test analysis report if >5 test failures

### After Workflow Changes
1. `./scripts/workflow-health-check.sh`
2. `./scripts/validate-workflows.py`
3. Generate workflow analysis report if pipeline affected

### Before Committing
1. `./run-final-validation.ps1`
2. Ensure no summary files in root directory
3. Update CHANGELOG.md if major changes

## Agent Decision Tree

```
Change Type?
├── Module/Code → Run CodeFixer validation → Generate test report if needed
├── Tests → Run test validation → Generate test analysis if >5 failures 
├── Workflows → Run workflow validation → Generate workflow analysis if pipeline affected
├── Documentation → Update INDEX.md if adding reports → Update CHANGELOG.md if major
└── Major Feature → Run full maintenance → Generate project status report
```

## � Support Commands

```powershell
# Get current project health
./scripts/maintenance/auto-maintenance.ps1 -Task "check-health" -Verbose

# Emergency cleanup
./scripts/maintenance/auto-maintenance.ps1 -Task "cleanup"

# Full diagnostic
./scripts/maintenance/auto-maintenance.ps1 -Task "full" -GenerateReport -Verbose
```

---

*Keep this reference handy for consistent project maintenance! *

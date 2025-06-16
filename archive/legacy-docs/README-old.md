# OpenTofu Lab Automation

[![Lint](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/lint.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/lint.yml)
[![Pester](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester.yml)
[![Pytest](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pytest.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pytest.yml)

---

## Overview

OpenTofu Lab Automation is a cross-platform automation toolkit for building, testing, and managing local lab environments. It features:
- PowerShell runner scripts for Windows and Linux
- Example OpenTofu (Terraform) modules for Hyper-V
- Python CLI (`labctl`) for cross-platform helpers
- Comprehensive Pester and pytest test suites

---

## Quick Start

### Windows (PowerShell)

Run the bootstrap script to set up everything automatically:

```powershell
Powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/main/pwsh/kicker-bootstrap.ps1' -OutFile '.\kicker-bootstrap.ps1'; .\kicker-bootstrap.ps1 -Quiet"
```

### Linux/macOS

```bash
./pwsh/kickstart-bootstrap.sh
```

---

## Runner Usage

Interactive mode:
```powershell
./pwsh/runner.ps1
```

Automated Hyper-V setup:
```powershell
./pwsh/runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto
```

Silence most output:
```powershell
./pwsh/runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto -Quiet
```

Custom config file:
```powershell
./pwsh/runner.ps1 -ConfigFile path\to\config.json -Scripts '0006,0007,0008,0009,0010' -Auto
```

---

## Documentation

- [Documentation Index](docs/index.md)
- [Runner script usage](docs/runner.md)
- [Lab Utility Scripts](docs/lab_utils.md)
- [CodeFixer Module Guide](docs/codefixer.md)
- [Import Analysis & Migration](docs/import-analysis.md)
- [Module Structure](docs/modules.md)
- [Python CLI](docs/python-cli.md)
- [Testing guidelines](docs/testing.md)
- [Troubleshooting CI](docs/troubleshooting.md)
- [Pester test failures (tracked)](docs/pester-test-failures.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

---

## 📊 Comprehensive Workflow Health Dashboard

**Last Updated:** 2025-06-12 10:35:00 UTC  
**Overall Health:** 🟡 Good (87%) - System Operational

### 🚀 Workflow Status Overview

| Workflow | Status | Purpose | Last Updated |
|----------|--------|---------|--------------|
| [![Lint](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/lint.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/lint.yml) | ![Lint Status](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/lint.yml/badge.svg) | Code Quality & Standards | Continuous |
| [![Pester](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester.yml) | ![Pester Status](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester.yml/badge.svg) | PowerShell Unit Tests | Continuous |
| [![Pytest](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pytest.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pytest.yml) | ![Pytest Status](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pytest.yml/badge.svg) | Python Unit Tests | Continuous |
| [CI](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/ci.yml) | ![CI Status](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/ci.yml/badge.svg) | Integration Tests | On Push/PR |
| [Pester Linux](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester-linux.yml) | ![Linux Status](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester-linux.yml/badge.svg) | Linux Platform Tests | Continuous |
| [Pester Windows](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester-windows.yml) | ![Windows Status](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester-windows.yml/badge.svg) | Windows Platform Tests | Continuous |
| [Pester macOS](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester-macos.yml) | ![macOS Status](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester-macos.yml/badge.svg) | macOS Platform Tests | Continuous |

### 🎯 System Health Metrics

| Component | Status | Count | Health Score |
|-----------|--------|-------|--------------|
| **🔧 PowerShell Scripts** | [PASS] Healthy | 37 validated | 100% |
| **📋 Workflow Files** | [PASS] Healthy | 22 workflows | 100% |
| **🧪 Test Coverage** | [PASS] Healthy | 85+ test files | 95% |
| **🔍 Validation Tools** | [PASS] Operational | 6 tools active | 100% |
| **📊 Automation System** | [PASS] Operational | 6/6 tests pass | 100% |

### 📈 Recent Validation Results

```bash
🏆 AUTOMATION SYSTEM VALIDATION RESULTS
═══════════════════════════════════════
[PASS] PowerShellValidation : PASS (37/37 scripts validated)
[PASS] PreCommitHook        : PASS (Git hooks operational)  
[PASS] BootstrapScript      : PASS (Non-interactive mode working)
[PASS] RunnerScript         : PASS (Enhanced error detection)
[PASS] WorkflowFiles        : PASS (All 22 workflows valid)
[PASS] TemplateScript       : PASS (Parameter ordering correct)

Overall Score: 6/6 tests passed
Status: 🎉 AUTOMATION SYSTEM FULLY OPERATIONAL!
```

### 🔧 Quick Actions & Tools

| Action | Purpose | Command |
|--------|---------|---------|
| 🔄 **Run System Validation** | Full system health check | `./final-automation-test.ps1` |
| 🧪 **Run All Pester Tests** | Execute PowerShell tests | [GitHub Actions](../../actions/workflows/pester.yml) |
| 🔍 **Validate PowerShell** | Check script syntax | `./tools/Validate-PowerShellScripts.ps1` |
| 📊 **Generate Dashboard** | Update this dashboard | `./scripts/generate-dashboard.ps1 -UpdateReadme` |
| 🛠️ **Bootstrap Environment** | Set up development environment | `./pwsh/kicker-bootstrap.ps1` |
| 📋 **Comprehensive Lint** | Run enhanced code linting | `./comprehensive-lint.ps1` |

### 💡 Current Recommendations

- [PASS] **System Health:** All core components are operational
- 🔄 **Monitoring:** Continue regular automated validation
- 📈 **Quality:** Maintain 95%+ test success rate  
- 🛡️ **Security:** Pre-commit hooks preventing syntax errors
- 🎯 **Performance:** All workflows optimized and validated

### 📊 Success Metrics Dashboard

| Metric | Current | Target | Trend |
|--------|---------|--------|-------|
| **PowerShell Validation** | 100% | 100% | 🟢 Stable |
| **Workflow Health** | 100% | 95% | 🟢 Excellent |
| **Test Coverage** | 95% | 90% | 🟢 Above Target |
| **Automation Score** | 6/6 | 6/6 | 🟢 Perfect |
| **Error Prevention** | Active | Active | 🟢 Operational |

### 🔔 Health Score Legend

- 🟢 **Excellent (95-100%)**: All systems optimal, continue monitoring
- 🟡 **Good (85-94%)**: Minor optimizations possible, generally stable  
- 🟠 **Fair (70-84%)**: Some attention needed, address warnings
- 🔴 **Poor (<70%)**: Critical issues require immediate action

---

## 🤖 Project Maintenance Automation

This project includes comprehensive automation for maintenance, validation, and reporting:

### Quick Validation
```powershell
# Comprehensive project validation
./run-final-validation.ps1

# Automated maintenance with health report
./scripts/maintenance/auto-maintenance.ps1 -Task "full" -GenerateReport
```

### For AI Agents & Developers
- **Report Management**: Use `./scripts/utilities/new-report.ps1` for all summary reports
- **Module Updates**: Always run `Invoke-ComprehensiveValidation` after changes
- **Import Fixes**: Use `Invoke-ImportAnalysis -AutoFix` for path updates
- **Quick Reference**: See [docs/AUTOMATION-QUICKREF.md](docs/AUTOMATION-QUICKREF.md)

### Report Organization
All project analysis reports are organized in `/docs/reports/`:
- `/test-analysis/` - Test infrastructure and validation reports
- `/workflow-analysis/` - CI/CD and pipeline analysis  
- `/project-status/` - Milestone and integration summaries
- See [docs/reports/INDEX.md](docs/reports/INDEX.md) for complete report index

---

## Contributing & Testing

- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
- Run `pwsh/setup-test-env.ps1` to install all test dependencies.
- Run tests:
  - PowerShell: `pwsh -NoLogo -NoProfile -Command "Invoke-Pester"`
  - Python: `cd py && pytest`

---

## License

See [LICENSE](LICENSE).

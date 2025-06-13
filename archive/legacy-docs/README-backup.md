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
- [Python CLI](docs/python-cli.md)
- [Testing guidelines](docs/testing.md)
- [Troubleshooting CI](docs/troubleshooting.md)
- [Pester test failures (tracked)](docs/pester-test-failures.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

---

## Workflow Dashboard

This project uses GitHub Actions for continuous integration and testing. Below is the current status of the workflows:

| Workflow Name       | Status                                                                 |
|---------------------|------------------------------------------------------------------------|
| Pester (Linux)      | ![Pester Linux](https://github.com/opentofu-lab-automation/actions/workflows/pester-linux.yml/badge.svg) |
| Pester (macOS)      | ![Pester macOS](https://github.com/opentofu-lab-automation/actions/workflows/pester-macos.yml/badge.svg) |
| Pester (Windows)    | ![Pester Windows](https://github.com/opentofu-lab-automation/actions/workflows/pester-windows.yml/badge.svg) |
| Update Path Index   | ![Update Path Index](https://github.com/opentofu-lab-automation/actions/workflows/update-path-index.yml/badge.svg) |
| CI                  | ![CI](https://github.com/opentofu-lab-automation/actions/workflows/ci.yml/badge.svg) |

### Recommendations
- Monitor the workflow statuses regularly to ensure all tests pass.
- Address any failures promptly to maintain the health of the CI/CD pipeline.

### Health Score
The overall health score of the workflows is calculated based on the success rate of recent runs. Use the `workflow-health-check.sh` script to generate a detailed report.

---  
**Overall Health:** 🔴 Poor (60%)

### 🚀 Current Status

| Component | Status | Details |
|-----------|--------|---------|| Workflow Files | ✅ Healthy | 22 workflows found |
| Test Coverage | ✅ Healthy | 85 test files found |
| PowerShell Scripts | ✅ Healthy | 37 scripts found |

### 🧪 Test Results Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | 0 |
| **Passed** | 0 ✅ |
| **Failed** | 0 ❌ |
| **Skipped** | 0 ⏭️ |
| **Success Rate** | 0% |
| **Last Run** | 2025-06-12 10:15:33 |

### 📈 Health Metrics

```
🎯 Overall Health Score: 60%
🧪 Test Success Rate: 0%
📅 Last Updated: 2025-06-12 10:24:26 UTC
```

### 🔧 Quick Actions

- 🔄 [Run Final Automation Test](../../final-automation-test.ps1)
- 🧪 [Run Pester Tests](../../actions/workflows/pester.yml) 
- 🔍 [Run PowerShell Validation](../../tools/Validate-PowerShellScripts.ps1)
- 📊 [Generate Health Report](../../scripts/generate-dashboard.ps1)

### 💡 Recommendations
- 🧪 Set up Pester tests for better code quality monitoring
- ⚡ Overall system health needs improvement - focus on critical issues first

### 📋 Health Score Legend

- 🟢 **Excellent (95-100%)**: All systems operational
- 🟡 **Good (85-94%)**: Minor issues, generally stable  
- 🟠 **Fair (70-84%)**: Some issues need attention
- 🔴 **Poor (<70%)**: Critical issues require immediate attention

<!-- DASHBOARD END -->

## Contributing & Testing

- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
- Run `pwsh/setup-test-env.ps1` to install all test dependencies.
- Run tests:
  - PowerShell: `pwsh -NoLogo -NoProfile -Command "Invoke-Pester"`
  - Python: `cd py && pytest`

---

## License

See [LICENSE](LICENSE).




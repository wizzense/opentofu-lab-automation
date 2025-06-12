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

## 📊 Workflow Dashboard

### Workflow Summary
| Workflow Name                  | Platforms              | Features                |
|-------------------------------|-----------------------|-------------------------|
| auto-merge                   | Linux                 | Basic                   |
| auto-test-generation-execution | N/A                   | Artifacts               |
| auto-test-generation-reporting | Linux                 | Artifacts               |
| auto-test-generation-setup    | Linux                 | Artifacts               |
| auto-test-generation          | Windows, Linux, macOS | Basic                   |
| changelog                    | Linux                 | Cache                   |
| ci                           | Linux                 | Matrix                  |
| copilot-auto-fix             | Linux                 | Basic                   |
| issue-on-fail                | Linux                 | Basic                   |
| lint                         | Windows, Linux, macOS | Matrix, Cache, Artifacts|
| package-labctl               | Windows               | Cache, Artifacts        |
| pester-linux                 | Linux                 | Cache, Artifacts        |
| pester-macos                 | macOS                 | Cache, Artifacts        |
| pester-windows               | Windows               | Cache, Artifacts        |
| pester                       | Windows, Linux, macOS | Matrix, Cache, Artifacts|
| pytest                       | Windows, Linux, macOS | Matrix, Cache, Artifacts|
| test                         | Windows, Linux        | Cache, Artifacts        |
| update-path-index            | Linux                 | Basic                   |
| update-pester-failures-doc   | Linux                 | Basic                   |

### Recent Workflow Activity
| Workflow Name                  | Status     | Last Run Time |
|-------------------------------|------------|---------------|
| Example Infrastructure        | ✅ Success | 06/12 05:28   |
| pester-windows.yml            | ❌ Failure | 06/12 05:28   |
| auto-test-generation-setup.yml| ❌ Failure | 06/12 05:28   |
| auto-test-generation-execution.yml | ❌ Failure | 06/12 05:28   |
| pester-linux.yml              | ❌ Failure | 06/12 05:28   |
| auto-test-generation-reporting.yml | ❌ Failure | 06/12 05:28   |
| pester-macos.yml              | ❌ Failure | 06/12 05:28   |
| Example Infrastructure        | ✅ Success | 06/12 05:17   |
| pester-linux.yml              | ❌ Failure | 06/12 05:17   |
| pester-macos.yml              | ❌ Failure | 06/12 05:17   |

### Recommendations
- 💡 Add caching to more workflows to improve performance.
- 💡 Split long workflows into smaller, more manageable files.
- 💡 Address high failure rates in workflows like `pester-linux.yml` and `pester-macos.yml`.

### Health Score
- 🟡 **50/100** - Good, but improvements needed.

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


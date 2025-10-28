# OpenTofu Lab Automation

Cross-platform PowerShell automation framework for OpenTofu/Terraform infrastructure management with comprehensive testing and modular architecture.

## 🚀 Quick Start

### One-Line Installation

**Windows PowerShell 5.1:**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/kicker-git.ps1' -OutFile '.\kicker-git.ps1'; .\kicker-git.ps1"
```

**PowerShell 7+ (Cross-platform):**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/kicker-git.ps1' -OutFile '.\kicker-git.ps1'; .\kicker-git.ps1"
```

### Bootstrap Options

```powershell
# Interactive setup with detailed logging
.\kicker-git.ps1 -Verbosity detailed

# Automation-friendly silent mode
.\kicker-git.ps1 -NonInteractive -Verbosity silent

# Development branch setup
.\kicker-git.ps1 -TargetBranch "develop"

# Preview changes without executing
.\kicker-git.ps1 -WhatIf
```

## 📋 Key Features

- **Cross-Platform**: Windows, Linux, and macOS support
- **Modular Architecture**: 9 specialized PowerShell modules
- **Infrastructure as Code**: OpenTofu/Terraform configurations for lab environments
- **Comprehensive Testing**: Bulletproof testing with Pester integration
- **Parallel Execution**: Runspace-based concurrent processing
- **Git Integration**: Automated patch management with GitHub integration
- **Enterprise Logging**: Multi-level logging with performance tracing
- **CI/CD Ready**: GitHub Actions workflows and automation support

## 🏗️ Project Structure

```
opentofu-lab-automation/
├── core-runner/                    # Main automation framework
│   ├── core_app/                   # Core application
│   │   ├── core-runner.ps1         # Main runner script
│   │   ├── default-config.json     # Default configuration
│   │   └── scripts/                # Automation scripts (0000-0114)
│   └── modules/                    # PowerShell modules
│       ├── BackupManager/          # Backup and cleanup operations
│       ├── DevEnvironment/         # Development environment setup
│       ├── LabRunner/              # Lab automation orchestration
│       ├── Logging/                # Enterprise logging system
│       ├── ParallelExecution/      # Parallel processing utilities
│       ├── PatchManager/           # Git and patch management
│       ├── ScriptManager/          # Script management
│       ├── TestingFramework/       # Unified testing framework
│       └── UnifiedMaintenance/     # Maintenance orchestration
├── configs/                        # Configuration files
├── docs/                           # Documentation
├── tests/                          # Comprehensive test suite
├── tools/                          # Utility tools
└── opentofu/                       # Infrastructure as Code
```

## 🔧 PowerShell Modules

All modules have comprehensive README files with usage examples:

| Module | Purpose | Documentation |
|--------|---------|---------------|
| **BackupManager** | Backup file consolidation and cleanup | [README](core-runner/modules/BackupManager/README.md) |
| **DevEnvironment** | Development environment setup and management | [README](core-runner/modules/DevEnvironment/README.md) |
| **LabRunner** | Lab automation and script execution orchestration | [README](core-runner/modules/LabRunner/README.md) |
| **Logging** | Enterprise-grade centralized logging | [README](core-runner/modules/Logging/README.md) |
| **ParallelExecution** | Parallel processing with runspaces | [README](core-runner/modules/ParallelExecution/README.md) |
| **PatchManager** | Git operations and patch management | [README](core-runner/modules/PatchManager/README.md) |
| **ScriptManager** | One-off script management | [README](core-runner/modules/ScriptManager/README.md) |
| **TestingFramework** | Unified test execution and reporting | [README](core-runner/modules/TestingFramework/README.md) |
| **UnifiedMaintenance** | Maintenance operation orchestration | [README](core-runner/modules/UnifiedMaintenance/README.md) |

### Quick Module Usage

```powershell
# Import a module
Import-Module "./core-runner/modules/Logging" -Force

# Use centralized logging
Write-CustomLog -Level 'INFO' -Message 'Starting automation'

# Run unified tests
Import-Module "./core-runner/modules/TestingFramework" -Force
Invoke-UnifiedTestExecution -TestSuite "All"

# Manage patches
Import-Module "./core-runner/modules/PatchManager" -Force
Invoke-PatchWorkflow -PatchDescription "Fix bug" -CreatePR -PatchOperation {
    # Your changes here
}
```

## 🎯 Core Runner Scripts

The core runner executes numbered automation scripts:

### Core Infrastructure Scripts
- **0006** - Install validation tools (cosign)
- **0007** - Install Go language
- **0008** - Install OpenTofu with verification
- **0009** - Initialize OpenTofu infrastructure
- **0010** - Prepare Hyper-V host configuration

### Administrative Scripts (0100-0116)
- **0100** - Enable WinRM
- **0101** - Enable Remote Desktop
- **0102** - Configure Firewall
- **0103** - Change Computer Name
- **0104** - Install Certificate Authority
- **0105** - Install Hyper-V
- **0106** - Install Windows Admin Center
- Plus DNS, PXE, and other administrative configurations

### Running Scripts

```powershell
# Run specific scripts
./core-runner.ps1 -Scripts "0006,0007,0008,0009,0010"

# Run all scripts
./core-runner.ps1 -Auto

# Run with detailed logging
./core-runner.ps1 -Scripts "0200" -Verbosity detailed

# Non-interactive mode for automation
./core-runner.ps1 -NonInteractive -Auto -Verbosity silent
```

## 🧪 Testing

### Run Tests

```powershell
# Bulletproof test suite
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "All"

# Module tests in parallel
pwsh -File "./tests/Run-AllModuleTests.ps1" -Parallel

# Non-interactive mode testing
pwsh -File "./test-noninteractive-fix.ps1" -TestMode "All"

# Unified test execution
Import-Module "./core-runner/modules/TestingFramework" -Force
Invoke-UnifiedTestExecution -TestSuite "All" -EnableParallel
```

### Test Coverage

- **17/17 bulletproof tests** passing consistently
- **Unit tests** for all modules
- **Integration tests** for module interactions
- **Syntax validation** for all PowerShell files
- **CI/CD integration** with GitHub Actions

## 📚 Documentation

### Primary Documentation
- **[Project Overview](docs/overview.md)** - Comprehensive project architecture
- **[Bulletproof Testing Guide](docs/BULLETPROOF-TESTING-GUIDE.md)** - Testing strategy and execution
- **[Module Documentation](core-runner/modules/)** - Individual module README files

### GitHub Resources
- **[GitHub Instructions](.github/instructions/)** - Copilot guidelines and workflows
- **[Agent Personas](.github/agents/)** - Team agent configurations
- **[Prompts](.github/prompts/)** - Reusable prompt templates

### Historical Reference
- **[Documentation Archive](docs/archive/)** - Completed work summaries and historical records

## 🔄 Development Workflow

### Setup Development Environment

```powershell
# Initialize development environment
Import-Module "./core-runner/modules/DevEnvironment" -Force
Initialize-DevelopmentEnvironment

# Install pre-commit hooks
Install-PreCommitHook
```

### Make Changes with PatchManager

```powershell
# Create patch with automatic tracking
Invoke-PatchWorkflow -PatchDescription "Add new feature" -CreatePR -PatchOperation {
    # Your code changes
    Add-Content "./Module.psm1" -Value "function New-Feature { }"
}
```

### Run Maintenance

```powershell
# Daily maintenance
Import-Module "./core-runner/modules/UnifiedMaintenance" -Force
Invoke-UnifiedMaintenance -Mode "Full" -AutoFix
```

## 🌐 OpenTofu Infrastructure

### Example Infrastructure Repository
[tofu-base-lab](https://github.com/wizzense/tofu-base-lab.git) - Base lab infrastructure

### Infrastructure Code Location
- **OpenTofu modules**: `./opentofu/modules/`
- **Example configurations**: `./opentofu/examples/`
- **Provider configurations**: Hyper-V, others as needed

### Setup OpenTofu Environment

```powershell
# Run essential setup scripts
./core-runner.ps1 -Scripts "0006,0007,0008,0009,0010"

# Navigate to infrastructure
cd opentofu/examples/hyperv

# Initialize and apply
tofu init
tofu plan
tofu apply
```

## 🔒 Configuration

### Configuration Files
- `./configs/default-config.json` - Default settings
- `./configs/core-runner-config.json` - Core runner specific
- `./core-runner/core_app/default-config.json` - Application defaults

### Environment Variables
- `$env:PROJECT_ROOT` - Project root directory
- `$env:PWSH_MODULES_PATH` - Module search paths

## 🤝 Contributing

### Development Standards
- **PowerShell 7.0+** cross-platform syntax
- **Forward slashes** for all file paths
- **OTBS style** (One True Brace Style)
- **Comprehensive logging** with Write-CustomLog
- **Error handling** with try-catch blocks
- **Module imports** with -Force parameter

### Before Committing
```powershell
# Run pre-commit checks
Test-PreCommitHook

# Run tests
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "Quick"

# Check syntax
Invoke-SyntaxValidation -Path "./"
```

## 📊 Project Status

### Latest Release
Check [Releases](https://github.com/wizzense/opentofu-lab-automation/releases) for the latest version

### Build Status
GitHub Actions workflows automatically test all changes

### Test Coverage
- Unit tests: Comprehensive module coverage
- Integration tests: Cross-module workflows
- Syntax validation: All PowerShell files

## 🆘 Troubleshooting

### Common Issues

**Module Import Failures**
```powershell
# Diagnose and fix module issues
Import-Module "./core-runner/modules/DevEnvironment" -Force
Resolve-ModuleImportIssues -ModuleName "LabRunner" -AutoFix
```

**Core Runner Issues**
```powershell
# Run with detailed logging
./core-runner.ps1 -Verbosity detailed

# Check system health
Import-Module "./core-runner/modules/UnifiedMaintenance" -Force
Invoke-InfrastructureHealth
```

**Test Failures**
```powershell
# Run specific test file
Invoke-PesterTests -Path "./tests/unit/specific.Tests.ps1"

# Check test configuration
Get-TestConfiguration
```

### Getting Help

1. **Check module README** for specific module issues
2. **Review logs** in `./logs/` directory
3. **Run health checks** with UnifiedMaintenance module
4. **Check documentation** in `./docs/` directory
5. **Open GitHub issue** for unresolved problems

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with:
- **PowerShell 7+** - Cross-platform automation
- **OpenTofu** - Infrastructure as Code
- **Pester** - PowerShell testing framework
- **GitHub Actions** - CI/CD automation

---

**Quick Links:**
- [Project Overview](docs/overview.md)
- [Testing Guide](docs/BULLETPROOF-TESTING-GUIDE.md)
- [Module Documentation](core-runner/modules/)
- [GitHub Instructions](.github/instructions/)
- [Roadmap](docs/roadmap/)

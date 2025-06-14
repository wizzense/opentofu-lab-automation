# OpenTofu Lab Automation

🚀 **One-click infrastructure lab deployment** - Cross-platform automation for OpenTofu (Terraform alternative) environments.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python Version](https://img.shields.io/badge/python-3.7%2B-blue)](https://python.org)
[![PowerShell](https://img.shields.io/badge/powershell-7%2B-blue)](https://github.com/PowerShell/PowerShell)

## 🎯 Quick Start (30 seconds)

### One Command - Any Platform

**🚀 Universal Quick Start (Recommended):**

**🪟 Windows (PowerShell):**
```powershell
# Download and run (recommended)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-start.py" -OutFile "quick-start.py"
python quick-start.py

# Alternative: One-line using curl if available
curl -sSL -o quick-start.py https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-start.py && python quick-start.py
```

**🐧 Linux/macOS:**
```bash
# One-line install
curl -sSL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-start.sh | bash

# Alternative: Download Python version directly
curl -sSL -o quick-start.py https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-start.py
python3 quick-start.py
```

**📋 Requirements:**
- Python 3.7+ (included on most systems)
- Internet connection
- Git (recommended, but optional)

That's it! The quick-start script will:
1. ✅ Check your system
2. 📥 Download the project
3. 🚀 Launch the interactive menu

## 🌟 Enhanced Features (NEW!)

### Enhanced Launcher with Advanced Configuration
For users who want more control and better error handling, use the enhanced launcher:

```bash
# Enhanced interactive menu with comprehensive features
python enhanced_launcher.py

# Launch enhanced GUI with detailed configuration builder
python enhanced_launcher.py --gui

# Command-line configuration builder with help text and validation
python enhanced_launcher.py --config-builder

# Enhanced deployment with working directory enforcement
python enhanced_launcher.py --deploy

# Complete system compatibility check
python enhanced_launcher.py --check
```

### 🔧 Enhanced Configuration Builder
- **📋 Organized Sections**: Repository, System, Security, Tools, Infrastructure
- **💡 Help Text**: Detailed explanations for every configuration option
- **✅ Validation**: Real-time validation with helpful error messages
- **🎯 Smart Defaults**: Platform-specific recommended values
- **📁 Working Directory Enforcement**: Always uses proper temp directories

### 🛡️ Improved Reliability
- **🌐 Cross-Platform PowerShell**: Enhanced PowerShell executor with proper encoding
- **⚡ Non-Interactive Modes**: Prevents hanging on automated deployments
- **🔒 Working Directory Control**: Forces `C:\temp\opentofu-lab-automation` (Windows) or `/tmp/opentofu-lab-automation` (Linux)
- **📝 Better Error Messages**: Clear, actionable error descriptions
- **🔍 Comprehensive Validation**: Checks dependencies, paths, and configuration

### 📊 Enhanced User Experience
- **🎨 Tabbed Interface**: Organized configuration sections
- **⏱️ Real-time Progress**: Live deployment monitoring
- **📱 Responsive Design**: Works across different screen sizes
- **🌍 Platform Detection**: Automatic platform-specific optimizations

## 🚀 Standard Quick Start

If you prefer the original quick start experience:

# Linux/macOS with curl:
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/launcher.py
python3 launcher.py

# Linux/macOS with wget:
wget https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/launcher.py
python3 launcher.py

# Available commands (all platforms):
python launcher.py          # Interactive menu
python launcher.py deploy   # Deploy lab environment
python launcher.py gui      # Launch GUI interface  
python launcher.py health   # Run health check
python launcher.py validate # Validate setup
```

**📱 Platform Shortcuts:**
```bash
# Windows
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/start.bat" -OutFile "start.bat"
start.bat

# Linux/macOS  
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/start.sh
chmod +x start.sh && ./start.sh

# PowerShell (all platforms)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/start.ps1" -OutFile "start.ps1"
./start.ps1
```

### Option 3: Git Clone (Full Repository)

**For Development/Full Features:**
```bash
git clone https://github.com/wizzense/opentofu-lab-automation.git
cd opentofu-lab-automation

# Quick start
python3 launcher.py

# Or use platform shortcuts
./start.sh          # Linux/macOS
start.bat           # Windows
./start.ps1         # PowerShell (any platform)
```

## 🌟 Key Features

### 🎮 **Interactive GUI & CLI**
- **Modern GUI** with real-time progress monitoring
- **Cross-platform** - Works on Windows, Linux, macOS
- **Configuration builder** with validation and templates
- **CLI interface** for automation and scripting

### 🚀 **One-Click Deployment**
- **Zero-configuration** quick start
- **Platform detection** and automatic setup
- **Prerequisite checking** with guided installation
- **Health monitoring** and validation

### 🔧 **Advanced Automation**
- **PowerShell modules** for batch processing and validation
- **Python CLI tools** for cross-platform management  
- **Automated testing** with Pester and custom frameworks
- **CI/CD integration** with GitHub Actions

### 🏗️ **Infrastructure Components**
- **OpenTofu/Terraform** configurations
- **Virtual machine** provisioning and management
- **Network automation** and configuration
- **Monitoring and logging** setup

## 📦 What's Included

### Core Components
- **🚀 Unified Launcher** (`launcher.py`) - Single entry point for all operations
- **🎮 GUI Interface** (`gui.py`) - Visual configuration and monitoring
- **⚙️  Deploy Script** (`deploy.py`) - Core deployment engine
- **🔧 PowerShell Modules** - Advanced automation and validation
- **📋 Configuration Templates** - Pre-built lab configurations

### Platform Support
- **Windows 10/11** (Desktop & Server Core)
- **Windows Server 2016+** (GUI & Core)
- **Ubuntu/Debian Linux** (18.04+)
- **CentOS/RHEL** (7+)
- **macOS** (10.14+)
- **WSL/WSL2** (Windows Subsystem for Linux)

### Prerequisites
- **Python 3.7+** (automatically detected and guided installation)
- **PowerShell 7+** (recommended, but optional)
- **tkinter** (for GUI - usually included with Python)
- **Internet connection** (for downloads and updates)

## 🔧 Installation Methods

### Method 1: Automatic Installer (Recommended)
The automatic installers handle all platform differences and dependencies:

- **Windows**: Uses PowerShell's built-in `Invoke-WebRequest` (no curl needed)
- **Linux/macOS**: Supports both `curl` and `wget`
- **Cross-platform**: Detects Python, checks prerequisites, launches interactive menu

### Method 2: Manual Download
Download individual components for custom setups:

- **Unified Launcher**: Single Python script that handles everything
- **Legacy Components**: Individual deploy.py and gui.py scripts
- **Platform Wrappers**: Batch, shell, and PowerShell shortcuts

### Method 3: Git Clone
Full repository clone for development and advanced usage:

- Complete source code and development tools
- Testing frameworks and validation scripts
- Documentation and examples

## 🏃‍♂️ Usage Examples

### Quick Deployment
```bash
# Download and run with one command
curl -sSL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/install.sh | bash

# Follow the interactive menu:
# 1. Deploy Lab Environment
# 2. Configure settings
# 3. Monitor progress
```

### GUI Mode
```bash
# Launch visual interface
python launcher.py gui

# Features:
# - Configuration builder
# - Real-time progress monitoring  
# - Log viewing and debugging
# - Resource management
```

### Automation/Scripting
```bash
# Silent deployment with defaults
python launcher.py deploy --quick

# Health check and validation
python launcher.py health
python launcher.py validate

# Custom configuration
python launcher.py deploy --config my-config.json
```

### PowerShell Integration
```powershell
# Import and use PowerShell modules
Import-Module "./pwsh/modules/LabRunner"
Import-Module "./pwsh/modules/CodeFixer"

# Run comprehensive validation
Invoke-ComprehensiveValidation

# Parallel lab execution
Invoke-ParallelLabRunner -Config "custom-config.yaml"
```

## 🛠️ Advanced Configuration

### Configuration Files
- **YAML configs** in `configs/config_files/`
- **JSON templates** for different lab types
- **Environment-specific** settings
- **Custom resource** definitions

### Customization
- **Modular architecture** - enable/disable components
- **Plugin system** for extensions
- **Template system** for custom deployments
- **Hook system** for custom validation

### Integration
- **CI/CD pipelines** with GitHub Actions
- **Monitoring systems** integration
- **Logging and alerting** setup
- **Backup and recovery** automation

## 📚 Documentation

### User Guides
- [Getting Started](docs/index.md) - Comprehensive setup guide
- [GUI Interface](docs/python-cli.md) - Visual interface documentation
- [CLI Reference](docs/runner.md) - Command-line usage
- [Configuration](docs/lab_utils.md) - Settings and customization

### Developer Resources
- [Contributing](docs/CONTRIBUTING.md) - Development guidelines
- [Testing Framework](docs/testing-framework.md) - Validation and testing
- [Module Development](docs/CODEFIXER-GUIDE.md) - PowerShell modules
- [Architecture](docs/AUTOMATION-QUICKREF.md) - System overview

### Troubleshooting
- [Common Issues](docs/pester-test-failures.md) - Solutions and workarounds
- [Platform-Specific](docs/copilot-codespaces.md) - OS-specific guides
- [Performance](docs/testing.md) - Optimization and tuning

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
# Clone repository
git clone https://github.com/wizzense/opentofu-lab-automation.git
cd opentofu-lab-automation

# Install development dependencies
pip install -r requirements.txt  # If exists
pwsh -Command "Install-Module -Name Pester, PSScriptAnalyzer -Force"

# Run tests
python launcher.py validate
pwsh -Command "./scripts/maintenance/unified-maintenance.ps1 -Mode All"
```

### Testing
- **Python tests** with pytest and custom frameworks
- **PowerShell tests** with Pester
- **YAML validation** with yamllint
- **Cross-platform** compatibility testing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenTofu](https://opentofu.org/) - Open-source Terraform alternative
- [PowerShell](https://github.com/PowerShell/PowerShell) - Cross-platform automation
- [Python](https://python.org) - Cross-platform scripting
- Community contributors and testers

---

**🚀 Ready to get started?** Run the one-line installer for your platform above!

**💡 Need help?** Check the [documentation](docs/) or open an [issue](https://github.com/wizzense/opentofu-lab-automation/issues).

**🔧 Want to contribute?** See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.









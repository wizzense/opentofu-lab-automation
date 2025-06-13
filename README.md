# OpenTofu Lab Automation

🚀 **One-click infrastructure lab deployment** - Cross-platform automation for OpenTofu (Terraform alternative) environments.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python Version](https://img.shields.io/badge/python-3.7%2B-blue)](https://python.org)
[![PowerShell](https://img.shields.io/badge/powershell-7%2B-blue)](https://github.com/PowerShell/PowerShell)

## 🎯 Quick Start (30 seconds)

### Option 1: Download & Run (No Git Required)

**🎯 Smart Download (Auto-detects branch):**
```bash
# Intelligent downloader that adapts to current branch
curl -sL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-download.sh | bash

# Or download the script first for multiple uses:
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/quick-download.sh
chmod +x quick-download.sh

./quick-download.sh        # Download deploy.py
./quick-download.sh gui.py  # Download GUI  
./quick-download.sh all     # Download everything
```

**📥 Manual Download:**
```bash
# Download main deployment script
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py
# OR with wget:
wget https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py

python3 deploy.py

# Download GUI launcher
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/gui.py
# OR with wget:
wget https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/gui.py

python3 gui.py

# Download platform-specific launchers
# Windows:
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.bat
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/launch-gui.bat

# Linux/macOS:
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.sh
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/launch-gui.sh
chmod +x *.sh
```

**Quick download & run:**
```bash
# One-liner CLI deployment
curl -sL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py | python3

# One-liner GUI launcher
curl -sL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/gui.py | python3
```

**PowerShell (Windows):**
```powershell
# Download and run deployment script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py" -OutFile "deploy.py"
python deploy.py

# Download and run GUI
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/gui.py" -OutFile "gui.py"
python gui.py

# Download Windows launchers
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.bat" -OutFile "deploy.bat"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/launch-gui.bat" -OutFile "launch-gui.bat"
```

**What each file does:**
- `deploy.py` - Main deployment script with CLI interface
- `gui.py` - Cross-platform GUI with visual config builder
- `deploy.bat/.sh` - Platform-specific wrappers for easy double-click execution
- `launch-gui.bat/.sh` - GUI launchers with dependency checking

> **📝 Branch Notes**: 
> - URLs with `/HEAD/` automatically use the repository's default branch
> - The `quick-download.sh` script auto-detects your current git branch for testing
> - For testing latest features, manually replace `/HEAD/` with `/feature/deployment-wrapper-gui/`
> - Once merged, all URLs will work with the main branch

### Option 2: One-Click Deployment (Full Clone)

**Windows:**
```cmd
# GUI Interface (Double-click):
launch-gui.bat

# Command Line:
deploy.bat
```

**Linux/macOS:**
```bash
# GUI Interface:
./launch-gui.sh

# Command Line:
./deploy.sh
# OR
python3 deploy.py
```

### Option 3: GUI Configuration & Deployment
```bash
# Cross-platform GUI with config builder
python gui.py
# OR
python deploy.py --gui
```

### Option 4: Interactive CLI Setup
```bash
# Clone and deploy
git clone https://github.com/wizzense/opentofu-lab-automation.git
cd opentofu-lab-automation
python deploy.py
```

### Option 5: Quick Deploy (No Questions)
```bash
python deploy.py --quick
```

## 🛠️ What This Does

This automation framework:
- ✅ **Installs prerequisites** (PowerShell, Git, OpenTofu, etc.)
- ✅ **Sets up lab infrastructure** (Hyper-V, networking, certificates)
- ✅ **Configures development tools** (VS Code, Python, Node.js)
- ✅ **Deploys OpenTofu modules** for infrastructure as code
- ✅ **Creates ready-to-use lab environment** in minutes

## 🔧 Prerequisites

**Minimum Requirements:**
- **Internet connection**
- **Administrator/sudo access**
- **Python 3.7+** (usually pre-installed on Linux/macOS)

**That's it!** Everything else is installed automatically.

## 📋 Deployment Options

### GUI Mode (Visual Interface)
```bash
# Launch graphical interface
python gui.py
# OR
python deploy.py --gui
# OR double-click: launch-gui.bat (Windows) / launch-gui.sh (Unix)
```
- **Visual configuration builder** with form fields and file browsers
- **Real-time deployment progress** monitoring with live output
- **Configuration file management** (load, save, edit existing configs)
- **Prerequisites checking** with detailed system information
- **Cross-platform compatibility** (Windows, Linux, macOS)

**GUI Features:**
- 🔧 **Config Builder**: Visual form for all deployment settings
- 📁 **File Browsers**: Easy directory and file selection
- 🚀 **One-Click Deploy**: Start deployment with visual progress
- 📊 **Real-Time Output**: Live deployment logs and status updates
- 💾 **Config Management**: Load, save, and edit configuration files
- 🔍 **Prerequisites Check**: System compatibility verification

### Interactive Mode (Default)
```bash
python deploy.py
```
- Asks configuration questions
- Shows progress and logs
- Best for first-time users

### Headless Mode (CI/CD)
```bash
python deploy.py --quick --non-interactive --quiet
```
- No user interaction required
- Minimal output
- Perfect for automation

### Custom Configuration
```bash
python deploy.py --config my-lab-config.json
```
- Use your own configuration file
- See `configs/config_files/` for examples

### Check Prerequisites Only
```bash
python deploy.py --check
```
- Verify system compatibility
- No installation or changes made

## 🗂️ Configuration

### Basic Config (`configs/config_files/default-config.json`)
```json
{
  "RepoUrl": "https://github.com/wizzense/tofu-base-lab.git",
  "LocalPath": "C:\\Temp\\lab",
  "RunnerScriptName": "runner.ps1",
  "InfraRepoUrl": "https://github.com/wizzense/base-infra.git"
}
```

### Platform-Specific Paths
- **Windows**: `C:\Temp\lab`
- **Linux/macOS**: `/tmp/lab`

## 🎮 Advanced Usage

### Direct PowerShell (After Prerequisites)
```powershell
# Main entry point
.\pwsh\kicker-bootstrap.ps1

# With custom config
.\pwsh\kicker-bootstrap.ps1 -ConfigFile "my-config.json"

# Quiet mode
.\pwsh\kicker-bootstrap.ps1 -Quiet -NonInteractive

# Preview mode (no changes)
.\pwsh\kicker-bootstrap.ps1 -WhatIf
```

### Manual Step Execution
```powershell
# Run specific deployment step
.\pwsh\runner.ps1 -Step "0001_Reset-Git"

# Skip to specific step number
.\pwsh\runner.ps1 -StartStep 5
```

## 🏗️ What Gets Installed

### Core Infrastructure
- **PowerShell 7+** (cross-platform scripting)
- **Git** (version control)
- **OpenTofu** (infrastructure as code)
- **Go** (OpenTofu dependency)

### Windows-Specific
- **Hyper-V** (virtualization)
- **Windows Admin Center** (server management)
- **Windows Features** (containers, networking)

### Development Tools (Optional)
- **VS Code** (code editor)
- **Python & Poetry** (package management)
- **Node.js & npm** (web development)
- **Docker Desktop** (containerization)
- **Azure CLI, AWS CLI** (cloud tools)

### Security & Networking
- **SSL certificates** (lab CA setup)
- **Firewall configuration** (lab access)
- **DNS configuration** (local resolution)
- **Trusted hosts** (PowerShell remoting)

## 🚨 Troubleshooting

### Common Issues

**Python not found:**
- **Windows**: Install from [python.org](https://python.org) and check "Add to PATH"
- **Linux**: `sudo apt install python3` or `sudo yum install python3`
- **macOS**: `brew install python3`

**PowerShell execution policy:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Permission denied (Linux/macOS):**
```bash
chmod +x deploy.sh
sudo ./deploy.sh  # If admin access needed
```

**Behind corporate firewall:**
- Configure proxy settings in your terminal
- May need to whitelist GitHub and Microsoft domains

### Getting Help

1. **Check logs**: Look for error details in terminal output
2. **Run check mode**: `python deploy.py --check`
3. **Review config**: Verify your configuration file
4. **Open issue**: [GitHub Issues](https://github.com/wizzense/opentofu-lab-automation/issues)

## 🎯 Use Cases

### Development Labs
- Local OpenTofu testing
- Infrastructure prototyping
- Module development
- CI/CD pipeline testing

### Training Environments
- Infrastructure as Code workshops
- OpenTofu/Terraform training
- DevOps bootcamps
- Certification prep

### Production Staging
- Pre-production testing
- Disaster recovery testing
- Change validation
- Performance testing

## 📚 Documentation

- **[Configuration Guide](docs/AUTOMATION-QUICKREF.md)** - Detailed setup options
- **[Troubleshooting](docs/troubleshooting.md)** - Common problems and solutions
- **[Development](docs/CONTRIBUTING.md)** - Contributing to the project
- **[Testing Framework](docs/testing-framework.md)** - Running and writing tests

## 🤝 Contributing

We welcome contributions! Quick start:

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test: `python deploy.py --check`
4. Submit pull request

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenTofu Community** - Excellent Terraform alternative
- **PowerShell Team** - Cross-platform automation platform
- **Contributors** - Making this project possible

---

## 🚀 Ready to Deploy?

**Just run one command:**

```bash
# Quick deployment (30 seconds)
python deploy.py --quick
```

**Or double-click:**
- Windows: `deploy.bat`
- Linux/macOS: `deploy.sh`

Your lab environment will be ready in minutes! 🎉

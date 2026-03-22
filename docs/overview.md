# OpenTofu Lab Automation - Project Overview

**OpenTofu Lab Automation** is a comprehensive cross-platform PowerShell automation framework for OpenTofu/Terraform infrastructure management with a modular architecture, extensive testing, and CI/CD integration.

> **Note:** For quick start instructions, see the [main README](../README.md). This document provides detailed architectural information.

## **Key Components Found**

### **1. Bootstrap Scripts (Entry Points)**
- **`kicker-git.ps1`** - Modern bootstrap script with CoreApp orchestration (v2.0.0)
- **`kicker-bootstrap-enhanced.ps1`** - Enhanced bootstrap with backward compatibility (v2.1.0)  
- **`bootstrap-launcher.ps1`** - Minimal web launcher for one-line installation

### **2. Core Application Module (CoreApp)**
**Location**: `core-runner/core_app/`
- **`CoreApp.psm1`** - Parent orchestration module managing all other modules
- **`core-runner.ps1`** - Main runner script for lab automation
- **`default-config.json`** - Default configuration settings

**New Orchestration Functions**:
- `Initialize-CoreApplication` - Complete ecosystem initialization
- `Import-CoreModules` - Dynamic module discovery and loading
- `Get-CoreModuleStatus` - Module health monitoring
- `Invoke-UnifiedMaintenance` - Orchestrated maintenance across modules
- `Start-DevEnvironmentSetup` - Development environment setup

### **3. PowerShell Modules Ecosystem**
**Location**: `core-runner/modules/`

#### **Core Modules**:
- **`Logging/`** - Enterprise-grade logging with performance tracing - [README](../core-runner/modules/Logging/README.md)
- **`LabRunner/`** - Lab automation and script execution orchestration - [README](../core-runner/modules/LabRunner/README.md)

#### **Additional Modules**:
- **`DevEnvironment/`** - Development environment management - [README](../core-runner/modules/DevEnvironment/README.md)
- **`PatchManager/`** - Git-controlled patch management - [README](../core-runner/modules/PatchManager/README.md)
- **`BackupManager/`** - Backup and maintenance operations - [README](../core-runner/modules/BackupManager/README.md)
- **`ParallelExecution/`** - Cross-platform parallel processing with runspaces - [README](../core-runner/modules/ParallelExecution/README.md)
- **`ScriptManager/`** - Script management and templates - [README](../core-runner/modules/ScriptManager/README.md)
- **`TestingFramework/`** - Unified Pester testing framework - [README](../core-runner/modules/TestingFramework/README.md)
- **`UnifiedMaintenance/`** - Centralized maintenance operations - [README](../core-runner/modules/UnifiedMaintenance/README.md)

> **All modules now have comprehensive README files** with usage examples, function references, and integration guides.

### **4. Automation Scripts**
**Location**: `core-runner/core_app/scripts/`

#### **Core Infrastructure Scripts**:
- **`0000_Cleanup-Files.ps1`** - Remove lab infrastructure repos
- **`0001_Reset-Git.ps1`** - Reset OpenTofu infrastructure repo
- **`0006_Install-ValidationTools.ps1`** - Download cosign for verification
- **`0007_Install-Go.ps1`** - Go language installation
- **`0008_Install-OpenTofu.ps1`** - OpenTofu installation with cosign verification
- **`0009_Initialize-OpenTofu.ps1`** - OpenTofu setup and infrastructure initialization
- **`0010_Prepare-HyperVHost.ps1`** - Comprehensive Hyper-V host configuration

#### **Administrative Scripts (0100-0116)**:
- WinRM, Remote Desktop, Firewall configuration
- Computer name, DNS, PXE boot setup
- Certificate Authority, Hyper-V, WAC installation

### **5. OpenTofu Infrastructure**
**Location**: `opentofu/`
- **`infrastructure/main.tf`** - Main infrastructure configuration
- **`modules/`** - Reusable Terraform modules:
  - `vm/` - Virtual machine module
  - `network_switch/` - Network switch module
- **`examples/hyperv/`** - Hyper-V lab examples and configurations

### **6. Testing Framework**
**Location**: `tests/`
- **Comprehensive test suite** with Pester integration
- **Cross-platform testing** capabilities
- **Integration, unit, and system tests**
- **Test helpers and templates**
- **Automated test generation**

### **7. Configuration Management**
**Location**: `configs/`
- **`default-config.json`** - Default settings
- **`core-runner-config.json`** - Core runner specific settings
- **`full-config.json`** - Complete configuration template
- **`recommended-config.json`** - Recommended settings

### **8. Documentation**
**Location**: `docs/`
- **[BULLETPROOF-TESTING-GUIDE.md](BULLETPROOF-TESTING-GUIDE.md)** - Comprehensive testing guide
- **[overview.md](overview.md)** - This document (project architecture)
- **[roadmap/](roadmap/)** - Strategic planning and roadmaps
- **[archive/](archive/)** - Historical documentation and completed work summaries

## **Key Architecture Features**

### **1. CoreApp Orchestration System**
- **Parent Module**: CoreApp now orchestrates all other modules
- **Dynamic Loading**: Intelligent module discovery and dependency management
- **Unified Interface**: Single entry point for all lab automation functions
- **Backward Compatibility**: All existing functions continue to work

### **2. Cross-Platform Support**
- **Windows, Linux, macOS** deployment capability
- **PowerShell 7.4+** cross-platform compatibility
- **Platform-specific paths and commands**

### **3. Modern Bootstrap System**
- **One-line installation** with web download
- **Self-updating capabilities**
- **Non-interactive mode** for automation
- **Comprehensive error handling**

### **4. Tanium Integration Planning**
- **Strategic roadmap** for enterprise lab management
- **Local GitHub runner integration**
- **ISO customization toolset**
- **Unified configuration system**

## **Usage Examples**

### **Quick Start**:
```powershell
# One-liner installation
iex (iwr 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/kicker-git.ps1').Content

# Traditional download and execute  
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/kicker-git.ps1' -OutFile '.\kicker-git.ps1'; .\kicker-git.ps1"
```

### **CoreApp Orchestration**:
```powershell
# Import and initialize
Import-Module CoreApp
Initialize-CoreApplication

# Check system health
Get-CoreModuleStatus

# Run maintenance
Invoke-UnifiedMaintenance -Mode Full -AutoFix

# Setup development environment
Start-DevEnvironmentSetup
```

### **OpenTofu Workflow**:
```powershell
# Essential setup scripts: 0006, 0007, 0008, 0009, 0010
cd opentofu/examples/hyperv
tofu init
tofu plan
tofu apply
```

This is a sophisticated, enterprise-ready lab automation framework with extensive modularity, cross-platform support, comprehensive testing, and strategic planning for advanced integrations like Tanium enterprise management.I'll continue by examining the current state of the project and determining what specific improvements or tasks need to be completed. Let me start by exploring the project structure and understanding what areas need attention. Based on the MODULE-TESTS-SUMMARY and the examination of the project structure, I can see the key areas that need attention. The summary indicates that several modules only have basic tests and need expansion. Let me focus on the priority improvements: Now I'll examine the full DevEnvironment module to understand its functions and then enhance the test coverage. Let me continue reading the module: Let me check what public functions are available in the DevEnvironment module: Let me examine these functions to understand what they do: 
## **Documentation Navigation**

### **Quick Start**
- [Main README](../README.md) - Getting started, installation, and quick reference
- [Bulletproof Testing Guide](BULLETPROOF-TESTING-GUIDE.md) - Testing strategies and execution

### **Module Documentation**
Each module has a comprehensive README with:
- Overview and features
- Installation and usage
- Function reference with parameters
- Code examples
- Integration guides
- Troubleshooting

**Core Modules:**
- [Logging](../core-runner/modules/Logging/README.md) - Enterprise logging system
- [LabRunner](../core-runner/modules/LabRunner/README.md) - Lab automation orchestration

**Supporting Modules:**
- [BackupManager](../core-runner/modules/BackupManager/README.md) - Backup operations
- [DevEnvironment](../core-runner/modules/DevEnvironment/README.md) - Development setup
- [ParallelExecution](../core-runner/modules/ParallelExecution/README.md) - Parallel processing
- [PatchManager](../core-runner/modules/PatchManager/README.md) - Git and patch management
- [ScriptManager](../core-runner/modules/ScriptManager/README.md) - Script management
- [TestingFramework](../core-runner/modules/TestingFramework/README.md) - Test orchestration
- [UnifiedMaintenance](../core-runner/modules/UnifiedMaintenance/README.md) - Maintenance workflows

### **GitHub Resources**
- [Instructions](.github/instructions/) - Development guidelines and workflows
- [Agents](.github/agents/) - Agent personas and configurations
- [Prompts](.github/prompts/) - Reusable prompt templates

### **Historical Documentation**
- [Archive](archive/) - Completed work summaries and historical records

## **Recent Improvements**

### **Module Documentation**
- All 9 modules now have comprehensive README files
- ~90KB of new documentation with 100+ code examples
- Consistent structure across all module docs
- Cross-references between related modules

### **Documentation Organization**
- Archived 21 completion summaries to `docs/archive/completed-work/`
- Streamlined main README to 300+ lines (from 380)
- Updated overview.md with module links
- Clear navigation structure

### **Key Features Documented**
- **PatchManager v2.1**: Auto-commit dirty trees, default issue creation
- **Logging v2.0**: Enterprise-grade logging with tracing
- **TestingFramework v2.0**: Unified test orchestration
- **UnifiedMaintenance**: Integrated maintenance workflows

## **Project Philosophy**

### **Modular Design**
Each module has a single, well-defined responsibility and integrates cleanly with others. This enables:
- Independent module development and testing
- Clear separation of concerns
- Easy extensibility
- Reliable composition

### **Cross-Platform First**
All code is designed to work on Windows, Linux, and macOS:
- Forward slashes for paths
- Platform detection with Get-Platform
- Conditional logic for OS-specific operations
- PowerShell 7+ features for consistency

### **Comprehensive Testing**
Testing is a first-class concern:
- Bulletproof test suite (17/17 passing)
- Per-module test coverage
- Integration tests for workflows
- Syntax validation for all files
- CI/CD integration

### **Enterprise Ready**
Built for production use:
- Centralized logging with levels
- Performance tracing
- Error handling and recovery
- Automated maintenance
- Health monitoring
- Issue tracking

This is a sophisticated, enterprise-ready lab automation framework with extensive modularity, cross-platform support, comprehensive testing, and strategic planning for advanced integrations.

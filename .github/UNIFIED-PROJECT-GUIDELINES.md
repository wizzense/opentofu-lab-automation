---
description: "Unified Project Guidelines - Single Source of Truth for OpenTofu Lab Automation"
version: "3.0.0"
lastUpdated: "2025-06-15"
---

# OpenTofu Lab Automation - Unified Project Guidelines

## **CRITICAL: Single Source of Truth**
This document is the **ONLY** authoritative source for project guidelines. All other instruction files reference this document. **NO CONFLICTING INSTRUCTIONS** are allowed.

---

## **Project Overview**

### Current Architecture
- **3 PowerShell modules**: CodeFixer, LabRunner, BackupManager, PatchManager
- **Cross-platform deployment** via Python scripts  
- **GitHub Actions workflows** for CI/CD
- **Comprehensive validation** system with auto-fix capabilities

### Module Locations (CRITICAL - Always Use These Paths)
```powershell
# Module Import Standards
Import-Module "/pwsh/modules/CodeFixer/" -Force
Import-Module "/pwsh/modules/LabRunner/" -Force  
Import-Module "/pwsh/modules/BackupManager/" -Force
Import-Module "/pwsh/modules/PatchManager/" -Force
```

---

## **Git Workflow & Branch Management**

### **MANDATORY: Use PatchManager for ALL Changes**
```powershell
# Create feature branch with automated PR
Import-Module "/pwsh/modules/PatchManager/" -Force
Invoke-GitControlledPatch -PatchDescription "feat: comprehensive cleanup" -PatchOperation {
    # Your changes here
    Write-Host "Applying comprehensive cleanup..."
} -CreatePullRequest -Force
```

### Branch Naming Conventions
- **Feature**: `feature/add-security-validation`
- **Bug Fix**: `fix/module-loading-error`
- **Documentation**: `docs/update-api-documentation`
- **Maintenance**: `chore/update-dependencies`
- **Hotfix**: `hotfix/critical-security-patch`

### Commit Standards
| **Type** | **Scope** | **Example** |
|----------|-----------|-------------|
| feat | codefixer | feat(codefixer): add parallel processing |
| fix | labrunner | fix(labrunner): resolve path issues |
| docs | readme | docs(readme): update installation guide |
| chore | deps | chore(deps): update dependencies |

---

## **PowerShell Development Standards**

### Script Structure Template
```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER Config
    Configuration object
.EXAMPLE
    ./Script.ps1 -Config $config
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [pscustomobject]$Config
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Import required modules
Import-Module "/pwsh/modules/LabRunner/" -Force

try {
    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Starting operation..." "INFO"
        # Implementation here
        Write-CustomLog "Operation completed successfully" "INFO"
    }
} catch {
    Write-CustomLog "Operation failed: $($_.Exception.Message)" "ERROR"
    throw
}
```

### Error Handling Standards
```powershell
try {
    $result = SomeOperation
    Write-CustomLog "Operation successful: $result" "INFO"
} catch {
    Write-CustomLog "Operation failed: $($_.Exception.Message)" "ERROR"
    throw
}
```

---

## **Maintenance & Validation**

### Pre-Commit Validation (MANDATORY)
```powershell
# 1. Import modules
Import-Module "/pwsh/modules/CodeFixer/" -Force
Import-Module "/pwsh/modules/LabRunner/" -Force

# 2. Run quick health check
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# 3. PowerShell linting
Invoke-PowerShellLint -Path "./scripts/" -Parallel

# 4. Update project manifest
Update-ProjectManifest -Changes $Changes
```

### Health Check Commands
| **Command** | **Purpose** |
|-------------|-------------|
| `./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"` | Quick health assessment |
| `./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix` | Comprehensive health check |
| `./Master-ConsolidatedMaintenance.ps1 -Mode "Quick"` | Master maintenance tool |

### Validation Sequence (After Every Change)
1. **Import modules**: See module import standards above
2. **Health checks**: `./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"`
3. **Validate changes**: `Invoke-PowerShellLint -Path $ChangedFiles -PassThru`
4. **Update manifest**: `Update-ProjectManifest -Changes $Changes`

---

## **Project File Management**

### PROJECT-MANIFEST.json Updates
```powershell
# Read current manifest
$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json

# Update last modified
$manifest.project.lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Update module information if modules changed
if ($ModuleChanges) {
    $manifest.core.modules.$ModuleName.lastUpdated = (Get-Date -Format "yyyy-MM-dd")
    $manifest.core.modules.$ModuleName.keyFunctions = $UpdatedFunctions
}

# Save updated manifest
$manifest | ConvertTo-Json -Depth 10 | Set-Content "./PROJECT-MANIFEST.json"

# Validate manifest structure
Test-JsonConfig -Path "./PROJECT-MANIFEST.json"
```

### Directory Structure
```
/workspaces/opentofu-lab-automation/
├── .github/                    # GitHub configuration
│   ├── UNIFIED-PROJECT-GUIDELINES.md  # This file - single source of truth
│   ├── workflows/              # CI/CD pipelines
│   └── copilot-instructions.md # GitHub Copilot integration
├── pwsh/modules/               # PowerShell modules (CURRENT)
│   ├── CodeFixer/              # Code analysis and repair
│   ├── LabRunner/              # Core lab automation  
│   ├── BackupManager/          # Backup management
│   └── PatchManager/           # Git-controlled patching
├── scripts/                    # Utility scripts
│   ├── maintenance/            # Maintenance scripts
│   ├── validation/             # Validation scripts
│   └── utilities/              # General utilities
├── docs/                       # Documentation
├── tests/                      # Test files
├── configs/                    # Configuration files
├── backups/                    # Backup files
└── PROJECT-MANIFEST.json       # Project metadata
```

---

## **YAML Workflow Standards**

### Current Status
- **Primary workflows**: `mega-consolidated.yml`, `mega-consolidated-fixed.yml` (YAML valid)
- **Legacy workflows**: Multiple files with structural errors (archive candidates)

### YAML Validation (AUTO-FIX DISABLED)
[WARN] **CRITICAL**: YAML auto-fix is permanently disabled due to corruption issues.

```powershell
# SAFE: Check YAML syntax only
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Check" -Path ".github/workflows"

# SAFE: Use yamllint directly  
yamllint ".github/workflows/mega-consolidated.yml"

# DANGEROUS: Never use auto-fix mode (permanently disabled)
# ./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"  # DISABLED
```

---

## **Testing Standards**

### Pester Testing
```powershell
Describe 'ScriptName Tests' {
    BeforeAll {
        Import-Module "/pwsh/modules/LabRunner/" -Force
    }
    
    It 'should import required modules' {
        Get-Module LabRunner | Should -Not -BeNullOrEmpty
    }
    
    It 'should have valid syntax' {
        { $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script:ScriptPath -Raw), [ref]$null) } | Should -Not -Throw
    }
}
```

---

## **VS Code Configuration**

### Required Settings (.vscode/settings.json)
```json
{
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "github.copilot.instructionFiles": [
    {
      "pattern": "**/*",
      "instructionFile": ".github/UNIFIED-PROJECT-GUIDELINES.md"
    },
    {
      "pattern": "pwsh/modules/**/*.ps1",
      "instructionFile": ".github/UNIFIED-PROJECT-GUIDELINES.md"
    },
    {
      "pattern": "scripts/**/*.ps1", 
      "instructionFile": ".github/UNIFIED-PROJECT-GUIDELINES.md"
    },
    {
      "pattern": ".github/workflows/**/*.{yml,yaml}",
      "instructionFile": ".github/UNIFIED-PROJECT-GUIDELINES.md"
    }
  ],
  "files.exclude": {
    "**/backups/**": true,
    "**/*.backup*": true,
    "**/archive/**": true
  },
  "search.exclude": {
    "**/backups/**": true,
    "**/*.backup*": true,
    "**/archive/**": true
  }
}
```

---

## **Module-Specific Guidelines**

### CodeFixer Module
```powershell
# Import and use CodeFixer
Import-Module "/pwsh/modules/CodeFixer/" -Force

# Key functions
Invoke-AutoFix                    # Run all fixers
Invoke-PowerShellLint            # Lint PowerShell files
Invoke-ComprehensiveValidation   # Full validation suite
New-AutoTest                     # Generate tests
Watch-ScriptDirectory            # Monitor for changes
```

### LabRunner Module  
```powershell
# Import and use LabRunner
Import-Module "/pwsh/modules/LabRunner/" -Force

# Key functions
Invoke-ParallelLabRunner         # Run labs in parallel
Write-CustomLog                  # Standardized logging
Test-RunnerScriptSafety-Fixed    # Validate scripts
```

### BackupManager Module
```powershell
# Import and use BackupManager
Import-Module "/pwsh/modules/BackupManager/" -Force

# Key functions
Invoke-BackupMaintenance         # Manage backups
Invoke-BackupConsolidation       # Consolidate backup files
Get-BackupStatistics             # Backup analytics
Invoke-PermanentCleanup          # Remove old backups
```

### PatchManager Module (MANDATORY for changes)
```powershell
# Import and use PatchManager
Import-Module "/pwsh/modules/PatchManager/" -Force

# Key functions
Invoke-GitControlledPatch        # Apply patches with Git control
Invoke-SelfHeal                  # Self-healing operations
Test-PatchingRequirements        # Validate patching environment
```

---

## **Security & Best Practices**

### Secrets Management
- **No hardcoded secrets** in any files
- Use **GitHub Secrets** for sensitive data
- **Validate inputs** before processing
- **Log all operations** for audit trail

### Performance Standards
- **Health checks**: < 1 minute completion time
- **Module imports**: < 5 seconds per module
- **Validation runs**: < 30 seconds for quick mode

---

## **Integration Points**

### GitHub Actions Integration
- All workflows validated with yamllint (check only)
- PowerShell scripts syntax-checked before commit
- Cross-platform testing on Windows, Linux, macOS
- Automated deployment workflows available

### AI/Copilot Integration
- This file serves as the **single instruction source**
- All AI agents must reference these guidelines
- Consistent patterns across all generated code
- Automatic validation after AI-generated changes

---

## **Troubleshooting**

### Common Issues
1. **Module import failures**: Verify paths match guidelines above
2. **YAML validation errors**: Use check-only mode, no auto-fix
3. **Git workflow issues**: Use PatchManager for all changes
4. **Test failures**: Follow Pester testing standards

### Emergency Recovery
```powershell
# Emergency system fix
./scripts/utilities/emergency-system-fix.ps1

# Master maintenance tool
./Master-ConsolidatedMaintenance.ps1 -Mode "Emergency" -Force
```

---

## **Compliance Checklist**

### Before Every Commit
- [ ] Used PatchManager for branch creation
- [ ] Pre-commit validation passed
- [ ] PowerShell linting completed
- [ ] YAML validation checked (no auto-fix)
- [ ] PROJECT-MANIFEST.json updated
- [ ] No emoji characters in any files
- [ ] All modules import successfully

### Before Every Release
- [ ] Full health check completed
- [ ] Cross-platform testing passed
- [ ] Documentation updated
- [ ] Security validation completed
- [ ] Backup systems tested

---

## **Version History**

- **3.0.0** (2025-06-15): Unified guidelines, single source of truth
- **2.x.x**: Multiple instruction files (deprecated)
- **1.x.x**: Initial project guidelines

---

**IMPORTANT**: This document supersedes all other instruction files. Any conflicts should be resolved by updating other files to match these guidelines.

**Last Updated**: 2025-06-15 by Comprehensive Guidelines Consolidation
**Next Review**: 2025-07-15

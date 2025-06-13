# Project Maintenance Automation Guidelines

This document provides guidelines for AI agents and developers working on the OpenTofu Lab Automation project to maintain consistency, automate routine tasks, and ensure proper documentation.

## 📋 PROJECT MANIFEST REFERENCE

**CRITICAL**: All AI agents and developers should reference the comprehensive project manifest:
- **Location**: `/PROJECT-MANIFEST.json`
- **Purpose**: Complete dependency mapping, component inventory, and system architecture
- **Auto-Updated**: Reflects current state of all major components and their relationships
- **Usage**: Consult before making changes to understand impact across the system

```powershell
# Quick manifest reference in PowerShell
Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json | Format-List
```

The manifest contains:
- **Complete module dependency mapping**
- **All maintenance system entry points**
- **Validation and testing framework details**
- **Performance metrics and capabilities**
- **Integration points for AI automation**

## 🧹 ROOT DIRECTORY CLEANUP AUTOMATION (CRITICAL)

### NEVER CREATE FILES IN ROOT DIRECTORY
**AI agents and developers MUST follow these rules:**

1. **NO MORE ROOT CLUTTER**: All temporary files, reports, and fix scripts go in proper directories
2. **USE AUTOMATED CLEANUP**: Always run cleanup after making changes
3. **FOLLOW FILE ORGANIZATION**: Scripts → `/scripts/`, Reports → `/docs/reports/`, Tools → `/tools/`

### Automated Cleanup Commands
```powershell
# ALWAYS run after making any changes
./scripts/maintenance/cleanup-root-scripts.ps1

# For comprehensive cleanup with backup
./scripts/maintenance/unified-maintenance.ps1 -Mode "Cleanup" -AutoFix

# Emergency cleanup if root gets cluttered
./cleanup-root-fixes.ps1  # This is the ONLY exception in root
```

### File Placement Rules
- **Fix scripts**: `/scripts/maintenance/` or `/tools/`
- **Reports/summaries**: `/docs/reports/` using `./scripts/utilities/new-report.ps1`
- **Temporary files**: Use `/tmp/` or proper temp directories
- **Backups**: `/backups/` with timestamps
- **Archives**: `/archive/` for old files

### Violation Detection
The maintenance system automatically detects root directory violations and suggests proper locations.

## 🚀 Unified Maintenance System (NEW - 2025-06-13)

### Quick Health Checks & Issue Tracking
**Use the unified maintenance system for fast, automated project health monitoring:**

```powershell
# Quick health check (30 seconds) - NO test execution required
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Quick"

# Full infrastructure analysis with auto-fixes
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "All" -AutoFix

# Comprehensive maintenance cycle (includes tests)
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix -UpdateChangelog

# Track recurring issues from existing test results
./scripts/maintenance/track-recurring-issues.ps1 -Mode "All"
```

### Key Benefits for AI Agents
- **No Test Reruns Required**: Analyze infrastructure health instantly
- **Pattern Recognition**: Automatically categorizes common errors (missing mocks, syntax issues, import problems)
- **Specific Fix Commands**: Each issue includes exact command to resolve
- **Prevention Tracking**: Monitor effectiveness of fixes over time
- **Changelog Integration**: Automatic maintenance tracking

### When to Use Each Mode

#### Daily/Frequent Checks
```powershell
# Before making changes - quick validation
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Quick"

# After making changes - comprehensive fixes
./scripts/maintenance/unified-maintenance.ps1 -Mode "Full" -AutoFix
```

#### Weekly/Comprehensive Maintenance
```powershell
# Complete maintenance with tests and reports
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix -UpdateChangelog
```

#### Emergency/Problem Resolution
```powershell
# When something breaks - immediate fixes
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "All"

# Analyze what went wrong
./scripts/maintenance/track-recurring-issues.ps1 -Mode "Analyze"
```

### Issue Categories Automatically Detected
1. **Missing Command Errors** → Auto-add mock functions to TestHelpers.ps1
2. **PowerShell Syntax Errors** → Run `fix-test-syntax.ps1`
3. **Import Path Issues** → Update to new module structure
4. **Test Container Problems** → Fix nested Describe/Context issues
5. **Environment Dependencies** → Add appropriate skip conditions

## 🧰 COMPREHENSIVE FEATURE INVENTORY

### Core Modules & Their Capabilities

#### CodeFixer Module (`/pwsh/modules/CodeFixer/`)
**Purpose**: Automated code analysis, fixing, and validation
- **Invoke-PowerShellLint**: Batch processing with dynamic CPU optimization (350+ files)
- **Invoke-AutoFix**: Multi-type automated fixing (syntax, imports, test structure)
- **Invoke-ComprehensiveValidation**: Full project validation with reporting
- **Invoke-ImportAnalysis**: Dependency path validation and auto-updates
- **Invoke-ParallelScriptAnalyzer**: High-performance parallel analysis
- **New-AutoTest**: Intelligent test generation for PowerShell scripts
- **Test-JsonConfig**: Configuration file validation

#### LabRunner Module (`/pwsh/modules/LabRunner/`)
**Purpose**: Lab environment automation and cross-platform management
- **Get-LabConfig**: Environment configuration management
- **Write-CustomLog**: Structured logging infrastructure
- **Read-LoggedInput**: Interactive user input with logging
- **Get-MenuSelection**: User interface utilities

### Unified Maintenance System

#### Infrastructure Health Check (`infrastructure-health-check.ps1`)
- **Real-time Analysis**: 350+ PowerShell files in under 1 minute
- **Zero Dependencies**: No test execution required
- **Smart Categorization**: Automatic issue classification by severity
- **Auto-Fix Integration**: Pattern-based problem resolution
- **JSON Persistence**: Historical health data tracking

#### Issue Tracking System (`track-recurring-issues.ps1`)
- **Pattern Recognition**: Identifies recurring problem categories
- **Prevention Tracking**: Monitors effectiveness of applied fixes  
- **Historical Analysis**: Trend tracking with JSON-based persistence
- **Severity Classification**: Critical/High/Medium/Low prioritization
- **Automated Reporting**: GitHub-ready markdown with fix commands

#### Emergency Fixes (`fix-infrastructure-issues.ps1`)
- **Targeted Repairs**: Specific fix categories (CodeFixer, MissingCommands, TestContainers, etc.)
- **Dry-Run Capability**: Preview changes before applying
- **Smart Pattern Matching**: Detects and resolves common infrastructure issues
- **Integration Ready**: Works with maintenance system and CI/CD

### Validation & Testing Framework

#### Pre-Commit Hook System
- **Batch Processing**: Dynamic CPU-based scaling for optimal performance
- **Syntax Prevention**: Blocks commits with PowerShell syntax errors
- **Structure Validation**: Ensures proper Param/Import-Module ordering in runner scripts
- **Smart File Detection**: Only processes staged PowerShell files

#### Test Framework Integration  
- **Pester 5.0+**: Modern testing with comprehensive mock support
- **Auto-Test Generation**: CodeFixer can generate tests for new functions
- **Cross-Platform Mocks**: Handles Windows/Linux/macOS differences automatically
- **TestHelpers Integration**: Centralized mock management and module loading

### AI Agent Integration Points

#### Automated Maintenance Commands
```powershell
# Quick health assessment (30 seconds)
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Quick"

# Full automated maintenance cycle
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix -UpdateChangelog

# Emergency problem resolution
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "All"

# Dependency analysis and fixes
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer"
Invoke-ImportAnalysis -AutoFix
```

#### Performance Metrics & Capabilities
- **Analysis Speed**: 350+ files analyzed in < 1 minute
- **Batch Optimization**: Dynamic sizing based on file count and CPU cores
- **Parallel Processing**: Up to 12 concurrent analysis jobs
- **Memory Efficient**: Streaming analysis for large codebases
- **Auto-Scaling**: Intelligent batch size adjustment (3-5 files per batch)

#### Smart Problem Detection
- **Syntax Errors**: AST parsing for PowerShell validation
- **Import Issues**: Detects outdated module paths automatically  
- **Missing Mocks**: Identifies test functions needing mock implementations
- **Structure Problems**: Validates Param block positioning and Import-Module order
- **Environment Dependencies**: Flags platform-specific code needing skip conditions

## 🔗 DEPENDENCY MAPPING & AUTO-TRACKING

### Module Dependency System
The project manifest automatically tracks all dependencies:

```powershell
# View current dependency mapping
$manifest = Get-Content "./PROJECT-MANIFEST.json" | ConvertFrom-Json
$manifest.dependencies.internal.moduleStructure  # Internal dependencies
$manifest.dependencies.external  # External package dependencies
```

#### Automatic Dependency Updates
- **Import Path Changes**: CodeFixer detects and updates module references
- **Version Tracking**: External packages automatically tracked in manifest
- **Dependency Health**: Validates that all required modules are available
- **Circular Dependency Detection**: Prevents problematic dependency loops

#### Critical Dependencies
1. **PSScriptAnalyzer**: Auto-installed by CodeFixer for linting
2. **Pester 5.0+**: Required for testing framework
3. **LabRunner Module**: Core lab automation functionality
4. **CodeFixer Module**: Central validation and fixing system

### Component Relationship Mapping

#### Module Consumers
- **LabRunner Module** used by:
  - All test files (`/tests/`)
  - Runner scripts (`/pwsh/runner_scripts/`)
  - TestHelpers.ps1
  - Cross-platform automation

- **CodeFixer Module** used by:
  - Maintenance scripts (`/scripts/maintenance/`)
  - Validation workflows (`.github/workflows/`)
  - Pre-commit hooks
  - CI/CD pipelines

#### Auto-Update Triggers
When these files change, dependencies auto-update:
- `PROJECT-MANIFEST.json` → Updates documentation references
- Module `.psd1` files → Updates version tracking
- Import statements → Updates dependency mapping
- Test files → Updates mock requirements

### Performance Impact Tracking
```powershell
# Current performance metrics (auto-updated)
$manifest.metrics.performance
# {
#   "healthCheckTime": "< 1 minute",
#   "fullMaintenanceTime": "2-5 minutes", 
#   "batchProcessingOptimization": "Dynamic CPU scaling"
# }
```

## Report Management System

### Creating New Reports
**ALWAYS use the report generation utility instead of manually creating report files:**

```powershell
# For test analysis reports
./scripts/utilities/new-report.ps1 -Type "test-analysis" -Title "Test Performance Analysis" -Template "test"

# For workflow analysis reports  
./scripts/utilities/new-report.ps1 -Type "workflow-analysis" -Title "CI Pipeline Optimization" -Template "workflow"

# For project status reports
./scripts/utilities/new-report.ps1 -Type "project-status" -Title "Module Refactoring Complete" -Template "project"
```

### Report Organization Rules
1. **Never create .md summary files in the project root directory**
2. **All reports must go in `/docs/reports/` with proper categorization:**
   - `/docs/reports/test-analysis/` - Test infrastructure, Pester, validation reports
   - `/docs/reports/workflow-analysis/` - GitHub Actions, CI/CD, pipeline reports  
   - `/docs/reports/project-status/` - Milestones, integration, completion reports
3. **Use standardized naming:** `YYYY-MM-DD-descriptive-name.md`
4. **Update `/docs/reports/INDEX.md` when adding significant reports**
5. **Reference major reports in main `CHANGELOG.md`**

## Project Maintenance Automation

### Required Actions After Major Changes

#### 1. Module Structure Changes
```powershell
# Run CodeFixer validation
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer"
Invoke-ComprehensiveValidation

# Fix import issues automatically
Invoke-ImportAnalysis -AutoFix
```

#### 2. Test Infrastructure Changes
```powershell
# Validate PowerShell syntax
./scripts/validation/validate-powershell-scripts.ps1

# Run comprehensive test suite
./run-comprehensive-tests.ps1

# Generate test analysis report if significant issues found
./scripts/utilities/new-report.ps1 -Type "test-analysis" -Title "Test Infrastructure Updates" -Template "test"
```

#### 3. Workflow Changes
```powershell
# Validate workflows
./scripts/validate-workflows.py

# Test workflow health
./scripts/workflow-health-check.sh

# Generate workflow analysis if changes affect CI/CD
./scripts/utilities/new-report.ps1 -Type "workflow-analysis" -Title "Workflow Configuration Updates" -Template "workflow"
```

### Automated Validation Scripts

#### Available Utilities
- **`/scripts/validation/validate-powershell-scripts.ps1`** - PowerShell syntax validation
- **`/scripts/workflow-health-check.sh`** - GitHub Actions workflow validation
- **`/scripts/validate-workflows.py`** - Comprehensive workflow analysis
- **`/tools/pre-commit-hook.ps1`** - Git pre-commit validation

#### Integration Commands
```powershell
# Deploy CodeFixer enhancements
./scripts/Deploy-CodeFixerModule.ps1

# Organize project files
./scripts/Organize-ProjectFiles.ps1

# Clean up deprecated files
./scripts/Cleanup-DeprecatedFiles.ps1
```

## Documentation Standards

### When to Create Reports
1. **Test Analysis Reports** - After fixing >10 test failures, performance improvements, or infrastructure changes
2. **Workflow Analysis Reports** - After workflow optimizations, CI/CD changes, or build pipeline modifications
3. **Project Status Reports** - At major milestones, integration completions, or significant refactoring

### Required Documentation Updates
1. **CHANGELOG.md** - Summary of major changes with report references
2. **README.md** - Update if project structure or setup process changes
3. **docs/reports/INDEX.md** - Add entries for significant new reports
4. **Module documentation** - Update when module interfaces change

## AI Agent Automation Rules

### Before Making Changes
1. Check current project status: `./run-final-validation.ps1`
2. Review latest test analysis: Check `/docs/reports/test-analysis/` for most recent report
3. Validate module paths are current (LabRunner in `/pwsh/modules/LabRunner/`)

### After Making Changes
1. Run appropriate validation scripts based on change type
2. Create report if changes are significant (>5 files modified or major functionality)
3. Update CHANGELOG.md with summary and report reference
4. Verify no summary files were created in project root

### Code Generation Standards
1. **Always import modules using full paths:** `Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/ModuleName"`
2. **Use CodeFixer integration:** `Invoke-ImportAnalysis -AutoFix` for import issues
3. **Follow PowerShell best practices:** Use approved verbs, proper parameter binding
4. **Test integration:** Use `InModuleScope` tests with correct module references

### Error Prevention
1. **Never use deprecated paths:** No references to `pwsh/lab_utils/`
2. **Validate syntax:** Use `Invoke-PowerShellLint` before committing
3. **Check dependencies:** Ensure all required modules are available
4. **Test execution:** Run tests in clean environment before completion

## Maintenance Schedule

### Daily (Automated)
- Pre-commit hooks validate PowerShell syntax
- CodeFixer detects and suggests import fixes

### Weekly (On Demand)
- Run comprehensive validation: `./run-comprehensive-tests.ps1`
- Generate test health report if failures > 5%
- Check workflow success rates

### Monthly (Manual)
- Review and consolidate older reports
- Update project documentation
- Assess technical debt and plan improvements

## Quick Reference Commands

```powershell
# Generate new report
./scripts/utilities/new-report.ps1 -Type "<category>" -Title "<descriptive-title>" -Template "<template>"

# Validate entire project
./run-final-validation.ps1

# Fix common issues
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer"
Invoke-ComprehensiveValidation
Invoke-ImportAnalysis -AutoFix

# Check test status
./run-comprehensive-tests.ps1

# Validate workflows  
./scripts/workflow-health-check.sh
```

---

*These guidelines ensure consistent project maintenance and proper documentation. Follow them to maintain project quality and enable effective collaboration.*

## 🤖 AI AGENT MANDATORY INSTRUCTIONS

### BEFORE MAKING ANY CHANGES
```powershell
# 1. Check current project health
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Quick"

# 2. Never create files in root - check if you're about to violate this
if (Test-Path "./your-new-file.ps1") { 
    Write-Error "STOP: Don't create files in root directory!" 
}
```

### AFTER MAKING ANY CHANGES  
```powershell
# 1. Run comprehensive auto-fix
./scripts/maintenance/unified-maintenance.ps1 -Mode "Full" -AutoFix

# 2. Clean up any root directory violations
./scripts/maintenance/cleanup-root-scripts.ps1

# 3. Validate everything passes
pwsh -File tools/Validate-PowerShellScripts.ps1
```

### FILE CREATION RULES FOR AI AGENTS
- **Fix scripts**: Create in `/scripts/maintenance/` or `/tools/`
- **Reports**: Use `./scripts/utilities/new-report.ps1 -Type "analysis" -Title "Your Title"`
- **Tests**: Create in `/tests/` following existing patterns
- **Documentation**: Update existing docs, don't create new root files
- **Temporary files**: Use proper temp directories or `/tmp/`

### FORBIDDEN ACTIONS
❌ Creating `.ps1`, `.md`, `.json` files in root directory  
❌ Creating "summary" or "report" files manually  
❌ Bypassing the auto-fix system  
❌ Ignoring validation failures  
❌ Creating duplicate functionality without consolidating existing

### REQUIRED ACTIONS
✅ Use CodeFixer module for all fixes  
✅ Run cleanup after every change  
✅ Use report utility for documentation  
✅ Follow established file organization  
✅ Test fixes before marking complete

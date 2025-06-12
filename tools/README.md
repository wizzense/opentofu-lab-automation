# 🛠️ Project Organization & Management Tools

This directory contains tools for managing, organizing, and maintaining the OpenTofu Lab Automation project.

## 🗂️ Organization Tools

### [`Cleanup-Project.ps1`](./Cleanup-Project.ps1)
**Comprehensive project cleanup with smart file organization**

```powershell
# Preview what would be organized
./tools/Cleanup-Project.ps1 -WhatIf

# Execute cleanup with backup
./tools/Cleanup-Project.ps1 -CreateBackup

# Force cleanup without prompts
./tools/Cleanup-Project.ps1 -Force
```

**Features:**
- ✅ Analyzes root directory clutter
- ✅ Proposes logical organization structure
- ✅ Creates backup before changes
- ✅ Automatic file tagging
- ✅ Smart categorization

### [`Organize-ProjectFiles.ps1`](./Organize-ProjectFiles.ps1)
**Smart file organization with pattern-based rules**

```powershell
# Analyze current structure
./tools/Organize-ProjectFiles.ps1 -WhatIf

# Execute organization
./tools/Organize-ProjectFiles.ps1 -Force
```

**Organization Rules:**
- `fix_*.ps1` → `archive/legacy/`
- `test-*.ps1` → `archive/legacy/`
- `*.md` → `docs/` (except README.md)
- `*report*.json` → `reports/`
- `*.tf` → `infrastructure/`

### [`Manage-FileTags.ps1`](./Manage-FileTags.ps1)
**Smart file tagging system for automatic organization**

```powershell
# Tag a file
./tools/Manage-FileTags.ps1 -FilePath "script.ps1" -AddTags "utility","powershell"

# Show all tags
./tools/Manage-FileTags.ps1 -ListTags

# Update all automatic tags
./tools/Manage-FileTags.ps1 -UpdateIndex
```

**Auto-detected Tags:**
- `*.ps1` → `powershell`, `script`
- `*Test*.ps1` → `test`, `pester`
- `fix_*.ps1` → `legacy`, `fix-script`
- `*report*.json` → `report`, `generated`

## 🧪 Testing Tools

### [`New-RunnerScriptTest.ps1`](./New-RunnerScriptTest.ps1)
**Generate comprehensive test files for runner scripts**

```powershell
$testCases = @(
    @{
        Name = 'installs when enabled'
        Config = @{InstallTool = $true}
        Mocks = @{'Start-Process' = {}}
        ExpectedInvocations = @{'Start-Process' = 1}
    }
)

./tools/New-RunnerScriptTest.ps1 -ScriptName "0217_Install-MyTool.ps1" -TestCases $testCases
```

## 🎯 Usage Examples

### Complete Project Organization
```powershell
# 1. Backup current state
./tools/Cleanup-Project.ps1 -CreateBackup -WhatIf

# 2. Execute comprehensive cleanup
./tools/Cleanup-Project.ps1 -CreateBackup

# 3. Update file tags
./tools/Manage-FileTags.ps1 -UpdateIndex

# 4. Review organization
./tools/Manage-FileTags.ps1 -ListTags
```

### Adding New Scripts to Runner Directory
```powershell
# The framework automatically:
# 1. Detects new scripts in pwsh/runner_scripts/
# 2. Assigns next sequence number (e.g., 0217_)
# 3. Generates appropriate test files
# 4. Applies auto-tags based on content

# Just drop your script file and it's handled automatically!
```

### Managing Technical Debt
```powershell
# Find legacy files
./tools/Manage-FileTags.ps1 -ListTags | grep "legacy"

# Organize legacy content
./tools/Cleanup-Project.ps1 -WhatIf

# Clean up systematically
./tools/Cleanup-Project.ps1 -Force
```

## 📁 Recommended Project Structure

After running the organization tools:

```
📁 ROOT/
├── 📄 README.md (main documentation)
├── 📁 archive/
│   └── 📁 legacy/ (historical fix scripts, old tests)
├── 📁 configs/
│   ├── 📁 config_files/ (lab configurations)
│   └── 📁 project/ (project-level configs: YAML, TOML)
├── 📁 docs/ (all documentation and guides)
├── 📁 infrastructure/ (Terraform files)
├── 📁 pwsh/ (PowerShell modules and scripts)
├── 📁 py/ (Python tools and modules)
├── 📁 reports/ (test results, generated reports)
├── 📁 scripts/ (build and maintenance scripts)
├── 📁 tests/ (test framework and test files)
└── 📁 tools/ (project management utilities)
```

## 🔧 Maintenance

### Regular Cleanup Tasks
```powershell
# Weekly: Update file tags
./tools/Manage-FileTags.ps1 -UpdateIndex

# Monthly: Review organization
./tools/Cleanup-Project.ps1 -WhatIf

# As needed: Organize new files
./tools/Organize-ProjectFiles.ps1 -WhatIf
```

### Extending Organization Rules

Edit the rules in the scripts to customize organization:

```powershell
# In Organize-ProjectFiles.ps1
$organizationRules = @{
    "custom_category" = @{
        patterns = @("*custom*.ps1")
        description = "Custom scripts"
    }
}
```

## 🎉 Benefits

- ✅ **Clean Root Directory**: Essential files only in root
- ✅ **Logical Organization**: Related files grouped together  
- ✅ **Automatic Maintenance**: Smart tagging and categorization
- ✅ **Easy Navigation**: Clear directory structure
- ✅ **Future-Proof**: Extensible rules and patterns
- ✅ **Developer Friendly**: Better development experience

---

*These tools help maintain a clean, organized, and maintainable project structure as your OpenTofu Lab Automation project grows.*

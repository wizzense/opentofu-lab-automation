# CRITICAL AI GUIDANCE UPDATE

## 🚨 MANDATORY REQUIREMENTS FOR ALL AI ASSISTANTS

### 1. FILE NAMING CONVENTIONS

- **ALL temporary/debugging files MUST be prefixed with `TEMP_`**
- Examples: `TEMP_Fix-Syntax.ps1`, `TEMP_Debug-Tests.ps1`, `TEMP_Analysis.md`
- These files are automatically ignored by .gitignore
- Never commit temporary files to the project permanently

### 2. TESTING REQUIREMENT

- **ALWAYS test changes with Pester before applying fixes**
- Run `Invoke-Pester -Path './specific/test/path' -Output Detailed` first
- Create test scripts for any new functionality
- Validate fixes work before applying to multiple files

### 3. GIT WORKFLOW REQUIREMENTS

- **Check git status before and after changes**: `git status`
- **Create branches for experimental work**: `git checkout -b fix/description`
- **Commit stable changes incrementally**
- **Never bulk-edit files without testing individual changes first**

### 4. IDENTIFIED RECURRING PROBLEMS

#### Problem: Automated Bulk Fixes Corrupt Files

- **NEVER apply regex replacements to multiple files without testing on ONE file first**
- **ALWAYS read the file content after editing to verify correctness**
- **Use Pester to validate syntax before and after changes**

#### Problem: Missing Context About Project Structure

- **Project modules are in**: `pwsh/modules/`
- **Valid modules**: LabRunner, Logging, PatchManager, ScriptManager, etc.
- **CodeFixer module was REMOVED** - tests referencing it need updating
- **PWSH_MODULES_PATH should point to**: `C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh\modules`

#### Problem: Incorrect Parameter Syntax

- **Common error**: `-ForceWrite-CustomLog` (WRONG)
- **Correct syntax**: `-Force` (separate parameters)
- **Always validate PowerShell syntax with**: `Get-Content file.ps1 | Invoke-Expression`

### 5. CURRENT PROJECT STATE (June 17, 2025)

#### Test Infrastructure Status

- ✅ TestHelpers.ps1 files created in required directories
- ❌ Many test files still have syntax errors
- ❌ Files corrupted by automated regex fixes
- ❌ Tests failing due to missing/removed modules (CodeFixer)

#### Known Issues

1. **Configure-Firewall.Tests.ps1**: Missing closing brace (corrupted by bulk edit)
2. **0000_Cleanup-Files.ps1**: Invalid parameter `-ForceWrite-CustomLog`
3. **Multiple test files**: References to removed CodeFixer module
4. **Syntax errors**: Missing pipes before Should assertions

### 6. PROPER FIX WORKFLOW

#### Step 1: Analyze ONE file

```powershell
# Read and understand the file
Get-Content './tests/unit/scripts/Configure-Firewall.Tests.ps1'
# Test current syntax
Invoke-Pester -Path './tests/unit/scripts/Configure-Firewall.Tests.ps1'
```

#### Step 2: Fix and Test

```powershell
# Make targeted fix
# Test the fix
Invoke-Pester -Path './tests/unit/scripts/Configure-Firewall.Tests.ps1'
```

#### Step 3: Apply Pattern to Similar Files (IF successful)

```powershell
# Only after confirming the fix works on one file
# Apply to a small batch (2-3 files)
# Test each batch before proceeding
```

### 7. IMMEDIATE ACTION REQUIRED

1. **Assess damage from bulk regex fixes**
2. **Restore corrupted files from git if necessary**
3. **Fix files individually with proper testing**
4. **Update all AI instructions to prevent this pattern**

### 8. AI ASSISTANT CHECKLIST

Before making ANY file changes:

- [ ] Is this a temporary file? (Use TEMP_ prefix)
- [ ] Have I tested the change on ONE file first?
- [ ] Have I read the file content after editing?
- [ ] Have I run Pester to validate the fix?
- [ ] Have I checked git status?
- [ ] Am I following the project's actual structure?

### 9. PROJECT KNOWLEDGE BASE

#### Valid Modules

- LabRunner (primary test framework)
- Logging (centralized logging)
- PatchManager (git operations)
- ScriptManager (script management)
- TestingFramework (test utilities)

#### Removed/Deprecated

- CodeFixer (completely removed)
- Any emoji-related functionality
- Hardcoded paths (use environment variables)

#### Environment Variables

- `PROJECT_ROOT`: Project root directory
- `PWSH_MODULES_PATH`: Points to pwsh/modules/
- Both should be set in TestHelpers.ps1

### 10. COMMIT MESSAGE STANDARDS

```
type(scope): description

- Bullet point changes
- Test results
- Breaking changes noted
```

Types: feat, fix, test, docs, refactor
Scopes: test, module, script, docs

---

**This guidance MUST be followed to prevent continued file corruption and maintain project stability.**

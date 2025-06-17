# AI File Creation Guidelines

## Temporary Files

- Prefix with `TEMP_` for all debugging, testing, or temporary fix scripts
- These files are automatically ignored by git (.gitignore)
- Examples:
  - `TEMP_Fix-TestSyntaxErrors.ps1`
  - `TEMP_debug-output.txt`
  - `TEMP_test-validation.ps1`

## Permanent Files

- Only create when explicitly requested for long-term project use
- Follow existing project naming conventions
- Ask for confirmation before creating infrastructure files
- Examples:
  - Module files in `pwsh/modules/`
  - Test files in `tests/`
  - Documentation in `docs/`

## Quick Commands

```powershell
# Find all temporary files
Get-ChildItem -Recurse -Name "TEMP_*"

# Clean up temporary files
Remove-Item "TEMP_*" -Force
```

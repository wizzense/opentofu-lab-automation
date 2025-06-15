# GitHub Copilot Instructions for CodeFixer

## Key Functions

- **Invoke-AutoFix**: Runs all available fixers.
- **Invoke-TestSyntaxFix**: Fixes syntax errors in test files.
- **Invoke-TernarySyntaxFix**: Fixes ternary operator issues.
- **Invoke-ScriptOrderFix**: Fixes Import-Module/Param order.

## Self-Healing Integration

CodeFixer integrates with PatchManager for self-healing. Use `Invoke-SelfHeal` to run fixes automatically.

## Usage

Run fixes:
```powershell
Invoke-AutoFix -Path "/pwsh/modules/CodeFixer"
```

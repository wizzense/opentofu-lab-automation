# PROJECT REORGANIZATION PLAN

## Target Structure (5 Root Folders Max)
```
opentofu-lab-automation/
├── .git/                    # Git repository data
├── .github/                 # GitHub workflows and config  
├── .vscode/                 # VS Code workspace settings
├── docs/                    # Documentation
├── src/                     # All source code
│   ├── pwsh/               # PowerShell modules and scripts
│   ├── opentofu/           # OpenTofu/Terraform configs
│   ├── python/             # Python scripts (renamed from py)
│   └── configs/            # Configuration files
└── tests/                  # All test files (moved from src/pwsh/tests)
```

## Issues Found
1. **Too many backup files** in tests folder (*.backup-* files)
2. **Numbered test files** (0000_, 0001_, etc.) - confusing naming
3. **Tests buried** in src/pwsh/tests instead of root-level tests/
4. **Python folder** named "py" - should be "python" for clarity
5. **Archive and backups** folders in root - should be consolidated

## Cleanup Actions
1. Move all tests to root-level `tests/` folder
2. Remove all backup files (*.backup-*)
3. Rename numbered tests to descriptive names
4. Rename `py/` to `python/`
5. Consolidate archive and backups
6. Update import paths in all files

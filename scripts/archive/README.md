# Archive Directory

This directory contains deprecated scripts and files that have been replaced by the CodeFixer module integration.

## Structure

- **fix-scripts/** - Deprecated individual fix scripts (now consolidated in CodeFixer module)
- **test-scripts/** - Deprecated test scripts (now handled by the testing framework)
- **deprecated-workflows/** - Old GitHub Actions workflows (now consolidated in unified-ci.yml)

## Why These Files Were Archived

As part of the CodeFixer module integration, individual fix scripts and workflows were consolidated into:

1. **CodeFixer PowerShell Module** - Located at 
2. **Unified CI Workflow** - The main GitHub Actions workflow at 
3. **Auto-Test Generation** - Automated test generation workflows

## Accessing Archived Content

These files are kept for reference and can be restored if needed. All functionality has been migrated to the new system with improved maintainability and extensibility.

For more information, see:
- [TESTING.md](../../docs/TESTING.md)
- [CODEFIXER-GUIDE.md](../../docs/CODEFIXER-GUIDE.md)
- [INTEGRATION-SUMMARY.md](../../INTEGRATION-SUMMARY.md)

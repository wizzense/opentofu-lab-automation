# Deprecated GitHub Workflows

These workflow files were archived on 2025-06-13 as part of the CodeFixer module integration.

## Reason for Deprecation
These workflows have been consolidated into the unified-ci.yml workflow, which now handles all CI/CD processes including:
- Linting
- Testing (Pester and PyTest)
- Validation
- Health checks
- Comprehensive validation using the CodeFixer module

## Current Workflows
The project now uses the following primary workflows:
- unified-ci.yml - Main CI/CD pipeline
- auto-test-generation.yml and related workflows - Automatic test generation

For more information, see the Integration Summary(../../INTEGRATION-SUMMARY.md).

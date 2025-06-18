---
mode: 'agent'
tools: ['codebase']
description: 'Develop and enhance the ParallelExecution module following project standards'
---

Develop or enhance the ParallelExecution module for the OpenTofu Lab Automation project.

## Requirements
Ask for the specific feature or enhancement if not provided in the prompt.

The module should include:

### Module Structure
- Public functions in the `Public/` subfolder
- Private helper functions in the `Private/` subfolder
- Module manifest file (.psd1) with proper metadata
- Module script file (.psm1) exporting public functions

### Code Standards
- Follow all PowerShell standards from the [copilot instructions](../.github/copilot-instructions.md)
- Include `#Requires -Version 7.0`
- Use cross-platform compatible code
- Implement proper error handling with try-catch blocks
- Use Write-CustomLog for all logging output

### Documentation
- Include comprehensive help documentation for all public functions
- Add module-level README.md with usage examples
- Document any dependencies or prerequisites

### Testing
- Generate corresponding Pester tests in the `tests/unit/modules/ParallelExecution/` directory
- Follow testing guidelines from [PowerShell testing instructions](../instructions/powershell-testing.instructions.md)
- Include tests for success and failure scenarios

### Integration
- Ensure the module integrates with the existing project structure
- Use appropriate module paths: `/workspaces/opentofu-lab-automation/core-runner/modules/ParallelExecution/`
- Follow the project's naming conventions and patterns

Base the implementation on existing modules in the codebase for consistency.

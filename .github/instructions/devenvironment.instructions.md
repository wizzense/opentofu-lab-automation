# DevEnvironment Module Development Standards

## Overview
This document outlines the standards and best practices for developing and testing the DevEnvironment module in the OpenTofu Lab Automation project.

## Development Standards
- **PowerShell Version**: Ensure compatibility with PowerShell 7.0+.
- **Cross-Platform**: Use forward slashes for paths and avoid Windows-specific cmdlets.
- **Module Structure**:
  - Public functions in `Public/` subfolder.
  - Private helper functions in `Private/` subfolder.
  - Module manifest file (.psd1) with proper metadata.
  - Module script file (.psm1) exporting public functions.
- **Logging**: Use `Write-CustomLog` for all logging with appropriate levels (INFO, WARN, ERROR, SUCCESS).
- **Error Handling**: Implement try-catch blocks with meaningful error messages.
- **Parameter Validation**: Use `[CmdletBinding(SupportsShouldProcess)]` and proper parameter validation.

## Testing Standards
- **Pester Tests**:
  - Use Pester 5.0+ with `#Requires -Module Pester`.
  - Follow Describe-Context-It structure with BeforeAll/AfterAll setup.
  - Test both success and failure scenarios.
  - Mock external dependencies like file operations and system commands.
- **Cross-Platform Testing**:
  - Validate functionality on Windows, Linux, and macOS.
  - Use TestDrive for temporary file operations.
- **Logging Tests**:
  - Mock `Write-CustomLog` to validate logging behavior.

## Documentation
- Include comprehensive help documentation for all public functions.
- Add usage examples in the module-level README.md.
- Document dependencies and prerequisites.

## Code Quality
- Verify adherence to project coding standards.
- Ensure proper error handling and logging implementation.
- Validate module imports use absolute paths and the `-Force` parameter.
- Check for proper parameter validation and SupportsShouldProcess usage.

## Commit Standards
- Use conventional commit format: `type(scope): description`.
- Reference `devenvironment` in the scope.
- Keep descriptions concise and professional.

## Additional Notes
- Follow the project's no-emoji policy.
- Use `$env:PROJECT_ROOT` and `$env:PWSH_MODULES_PATH` for paths.

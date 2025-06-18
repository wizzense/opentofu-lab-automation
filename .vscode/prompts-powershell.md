# PowerShell Module Development Prompts

## New Module Creation

```text
Create a new PowerShell module for [MODULE_NAME] that follows the project's cross-platform standards. Include:
1. Module manifest (.psd1) with proper metadata
2. Main module file (.psm1) with function exports
3. Public and Private function directories
4. Comprehensive Pester tests
5. Documentation and examples
6. Error handling and logging integration
The module should integrate with the existing Logging module and follow the established patterns in the codebase.
```

## Function Implementation

```text
Implement a PowerShell function [FUNCTION_NAME] that:
1. Uses [CmdletBinding(SupportsShouldProcess)] parameter binding
2. Includes proper parameter validation
3. Implements comprehensive error handling with try-catch blocks
4. Uses Write-CustomLog for all output with appropriate levels
5. Follows cross-platform best practices (forward slashes, compatible cmdlets)
6. Includes inline documentation and examples
7. Returns appropriate objects or status information
```

## Test Generation

```text
Generate comprehensive Pester 5.0+ tests for [FUNCTION_OR_MODULE] that include:
1. Unit tests for all public functions
2. Integration tests for module interactions
3. Cross-platform compatibility tests (Windows/Linux/macOS)
4. Error handling and edge case validation
5. Mock implementations for external dependencies
6. Performance tests for operations that may be slow
7. BeforeAll/AfterAll setup and cleanup
Use the existing test patterns from the project and ensure tests run independently.
```

## Code Review and Refactoring

```text
Review the following PowerShell code for:
1. PowerShell 7.0+ cross-platform compatibility
2. Proper error handling and logging implementation
3. Parameter validation and SupportsShouldProcess usage
4. Module import patterns and path usage
5. Security considerations and input validation
6. Performance optimization opportunities
7. Code organization and documentation quality
Provide specific recommendations for improvements following project standards.
```

## Troubleshooting and Debugging

```text
Analyze this PowerShell error/issue and provide:
1. Root cause analysis of the problem
2. Step-by-step debugging approach
3. Specific fixes with code examples
4. Prevention strategies for similar issues
5. Testing recommendations to validate the fix
6. Impact assessment on other components
Focus on the project's cross-platform requirements and existing architecture.
```

## Configuration and Environment Setup

```text
Help configure [COMPONENT] for the OpenTofu Lab Automation project:
1. Environment variable setup ($env:PROJECT_ROOT, $env:PWSH_MODULES_PATH)
2. Module loading and dependency management
3. Configuration file structure and validation
4. Cross-platform compatibility considerations
5. Testing environment setup
6. Integration with existing logging and error handling
Ensure the setup follows the project's established patterns.
```

## OpenTofu/Terraform Integration

```text
Create OpenTofu/Terraform configuration for [INFRASTRUCTURE_COMPONENT] that:
1. Uses proper HCL syntax and best practices
2. Includes variable validation and descriptions
3. Implements modular, reusable components
4. Follows security best practices
5. Includes appropriate outputs and data sources
6. Integrates with the PowerShell automation framework
7. Supports multiple environments and configurations
```

## Performance Optimization

```text
Optimize the following PowerShell code for performance:
1. Identify bottlenecks and inefficient operations
2. Suggest more efficient PowerShell constructs
3. Implement proper resource management
4. Add performance monitoring and logging
5. Consider memory usage and garbage collection
6. Implement caching where appropriate
7. Add timeout mechanisms for long operations
Maintain cross-platform compatibility and existing functionality.
```

## Documentation and Examples

```text
Create comprehensive documentation for [COMPONENT] including:
1. Overview and purpose within the automation framework
2. Installation and configuration instructions
3. Usage examples with common scenarios
4. API reference for all public functions
5. Integration examples with other modules
6. Troubleshooting guide for common issues
7. Cross-platform compatibility notes
Follow the project's professional language standards (no emojis).
```

## Security Review

```text
Perform a security review of [CODE/MODULE] focusing on:
1. Input validation and sanitization
2. Credential handling and secrets management
3. File path validation and directory traversal prevention
4. Access control and permission validation
5. Logging of security-relevant events
6. Cross-platform security considerations
7. Integration with existing security patterns
Provide specific recommendations and code examples for improvements.
```

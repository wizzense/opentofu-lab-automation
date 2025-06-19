# PowerShell Development Prompts

## Module Development

### Create New Module

```text
Create a new PowerShell module for [MODULE_NAME] with the following requirements:
- Follow project standards with proper manifest and module structure
- Include comprehensive parameter validation and error handling
- Use Write-CustomLog for all logging operations
- Implement begin/process/end blocks where appropriate
- Include proper help documentation with examples
- Follow cross-platform compatibility guidelines
```

### Function Implementation

```text
Implement a PowerShell function [FUNCTION_NAME] that:
- Uses [CmdletBinding(SupportsShouldProcess)] pattern
- Includes proper parameter validation with ValidateNotNullOrEmpty
- Implements comprehensive try-catch error handling with logging
- Uses Join-Path for all file path operations
- Returns meaningful objects with proper typing
- Includes Write-Progress for long-running operations
```

### Configuration Management

```text
Create a configuration management solution that:
- Uses PowerShell data files (.psd1) for configuration
- Implements validation for all configuration values
- Provides default values and environment-specific overrides
- Integrates with the existing Logging module
- Supports cross-platform file paths and operations
```

### Environment Setup

```text
Generate an environment setup script that:
- Validates PowerShell 7.0+ requirements
- Checks for required modules and installs if missing
- Configures logging and creates necessary directories
- Validates cross-platform compatibility
- Provides detailed progress feedback and error reporting
```

## Performance Optimization

### Parallel Processing

```text
Optimize this PowerShell code for parallel execution using:
- The project's ParallelExecution module
- Proper runspace management and cleanup
- Thread-safe logging and error handling
- Progress reporting across parallel tasks
- Memory-efficient data handling
```

### Large Dataset Processing

```text
Refactor this code to efficiently handle large datasets by:
- Implementing streaming/pipeline processing
- Using memory-efficient data structures
- Adding progress indicators and cancellation support
- Implementing proper disposal patterns
- Optimizing file I/O operations
```

## Documentation and Help

### Generate Help Documentation

```text
Create comprehensive help documentation for this PowerShell function including:
- Synopsis and detailed description
- Parameter descriptions with types and validation rules
- Multiple practical examples with expected outputs
- Notes about cross-platform compatibility
- Links to related functions and modules
```

### Code Review

```text
Review this PowerShell code for:
- Adherence to project coding standards (OTBS, cross-platform paths)
- Proper error handling and logging implementation
- Security best practices and input validation
- Performance considerations and optimization opportunities
- Test coverage and maintainability concerns
```

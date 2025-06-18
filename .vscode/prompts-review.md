# Code Review and Analysis Prompts

## Comprehensive Code Review

```text
Perform a thorough code review of [FILE_OR_MODULE] focusing on:
1. PowerShell 7.0+ cross-platform compatibility and best practices
2. Error handling implementation and exception management
3. Parameter validation and input sanitization
4. Logging integration using Write-CustomLog with appropriate levels
5. Security considerations including credential handling and path validation
6. Performance optimization opportunities and resource management
7. Code organization, documentation, and maintainability
8. Integration with existing project modules and patterns
9. Adherence to project coding standards and conventions
10. Test coverage requirements and quality
Provide specific recommendations with code examples for improvements.
```

## Security Analysis

```text
Conduct a security analysis of [CODE_COMPONENT] examining:
1. Input validation and sanitization for all parameters
2. Credential and secrets management practices
3. File path validation and directory traversal prevention
4. Access control and permission validation
5. Injection attack prevention (command, script, path injection)
6. Logging of security-relevant events and actions
7. Cross-platform security considerations and differences
8. Integration with existing security frameworks and patterns
9. Compliance with security best practices and standards
10. Potential attack vectors and mitigation strategies
Provide actionable security improvements with implementation examples.
```

## Performance Analysis

```text
Analyze the performance characteristics of [FUNCTION_OR_MODULE]:
1. Identify performance bottlenecks and inefficient operations
2. Evaluate memory usage patterns and potential leaks
3. Assess resource utilization and cleanup procedures
4. Review algorithm efficiency and computational complexity
5. Examine I/O operations and file system interactions
6. Evaluate network operations and timeout handling
7. Consider scalability under increased load
8. Review error handling performance impact
9. Analyze cross-platform performance variations
10. Recommend specific optimization strategies
Include benchmarking suggestions and performance testing approaches.
```

## Architecture Review

```text
Review the architecture and design of [COMPONENT] for:
1. Modularity and separation of concerns
2. Dependency management and coupling reduction
3. Scalability and extensibility considerations
4. Cross-platform compatibility and portability
5. Integration patterns with existing modules
6. Configuration management and environment handling
7. Error propagation and recovery mechanisms
8. Logging and monitoring integration
9. Testing strategy and testability design
10. Maintainability and future development considerations
Provide architectural improvements and refactoring recommendations.
```

## Standards Compliance Check

```text
Verify compliance with project standards for [CODE_SECTION]:
1. PowerShell 7.0+ version requirements and features
2. Cross-platform path handling (forward slashes)
3. Module import patterns with absolute paths and -Force
4. Function structure with [CmdletBinding(SupportsShouldProcess)]
5. Parameter validation attributes and types
6. Error handling with try-catch blocks and meaningful messages
7. Logging implementation using Write-CustomLog
8. Professional language usage without emojis
9. Documentation and inline comment standards
10. Variable naming and code formatting conventions
Identify deviations and provide corrective recommendations.
```

## Dependency Analysis

```text
Analyze dependencies and module interactions for [COMPONENT]:
1. Direct and transitive dependency mapping
2. Circular dependency identification and resolution
3. Version compatibility and requirements analysis
4. Cross-platform dependency considerations
5. External service and resource dependencies
6. Module loading order and initialization requirements
7. Dependency injection and inversion opportunities
8. Mock and testing dependency strategies
9. Deployment and distribution dependency impacts
10. Future dependency evolution and maintenance
Recommend dependency optimization and management improvements.
```

## Error Handling Assessment

```text
Evaluate error handling implementation in [CODE_COMPONENT]:
1. Exception handling coverage and appropriateness
2. Error message quality and user-friendliness
3. Logging integration for error scenarios
4. Recovery and rollback mechanisms
5. Error propagation strategies
6. Custom exception types and usage
7. Resource cleanup in error conditions
8. Cross-platform error handling differences
9. Testing coverage for error scenarios
10. Documentation of error conditions and responses
Provide improvements for robustness and user experience.
```

## Code Quality Metrics

```text
Assess code quality metrics for [MODULE_OR_FUNCTION]:
1. Cyclomatic complexity and code structure
2. Code duplication and reusability opportunities
3. Function and class size appropriateness
4. Comment density and documentation quality
5. Variable and function naming consistency
6. Code organization and file structure
7. Test coverage percentage and quality
8. Static analysis results and recommendations
9. Maintainability index and technical debt
10. Code readability and understandability
Generate actionable recommendations for quality improvements.
```

## Refactoring Recommendations

```text
Provide refactoring recommendations for [CODE_COMPONENT]:
1. Extract common functionality into reusable functions
2. Reduce code duplication through abstraction
3. Improve function and variable naming clarity
4. Optimize control flow and logic structure
5. Enhance error handling and recovery mechanisms
6. Improve parameter validation and type safety
7. Optimize performance-critical code sections
8. Enhance testability and mock-ability
9. Improve documentation and inline comments
10. Align with project standards and conventions
Include before/after code examples and implementation steps.
```

## Integration Impact Analysis

```text
Analyze the integration impact of changes to [COMPONENT]:
1. Identify all dependent modules and functions
2. Assess backward compatibility requirements
3. Evaluate testing impact and requirements
4. Consider deployment and rollback procedures
5. Analyze configuration and environment impacts
6. Review logging and monitoring implications
7. Assess security and permission changes
8. Consider cross-platform compatibility effects
9. Evaluate performance impact on dependent systems
10. Document change communication and training needs
Provide a comprehensive change management strategy.
```

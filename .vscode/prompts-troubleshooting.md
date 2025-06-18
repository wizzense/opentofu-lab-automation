# Troubleshooting and Debugging Prompts

## General Error Diagnosis

```text
Analyze this PowerShell error and provide comprehensive troubleshooting:
1. Parse the error message and stack trace for root cause
2. Identify the specific line and operation causing the failure
3. Determine if this is a syntax, runtime, or logic error
4. Check for common PowerShell 7.0+ compatibility issues
5. Verify cross-platform compatibility problems
6. Assess parameter validation and input handling issues
7. Examine module loading and dependency problems
8. Review environment variable and path configuration
9. Provide step-by-step debugging approach
10. Suggest preventive measures for similar issues
Include specific code fixes and validation steps.
```

## Module Loading Issues

```text
Diagnose module loading problems for [MODULE_NAME]:
1. Verify module manifest (.psd1) syntax and metadata
2. Check module file (.psm1) structure and exports
3. Validate module path resolution and accessibility
4. Examine Import-Module command and parameters
5. Review module dependencies and version requirements
6. Check for circular dependency issues
7. Validate PowerShell execution policy and permissions
8. Assess cross-platform path and case sensitivity issues
9. Review environment variable configuration
10. Test module loading in different PowerShell sessions
Provide corrective actions and validation procedures.
```

## Pester Test Failures

```text
Troubleshoot Pester test failures for [TEST_COMPONENT]:
1. Analyze test output and failure messages in detail
2. Identify whether failures are in test code or implementation
3. Check test environment setup and configuration issues
4. Validate mock implementations and scope problems
5. Examine test isolation and cleanup procedures
6. Review test data and fixture problems
7. Check for timing and asynchronous operation issues
8. Assess cross-platform test compatibility problems
9. Validate Pester version and configuration compatibility
10. Provide specific fixes prioritizing implementation over test changes
Include test validation and verification steps.
```

## Performance Issues

```text
Diagnose performance problems in [COMPONENT]:
1. Identify performance bottlenecks and slow operations
2. Analyze memory usage patterns and potential leaks
3. Examine resource utilization and cleanup efficiency
4. Review algorithm complexity and optimization opportunities
5. Assess I/O operations and file system interactions
6. Evaluate network operations and timeout configurations
7. Check for unnecessary loops and inefficient PowerShell constructs
8. Review error handling performance overhead
9. Analyze concurrent execution and thread safety issues
10. Recommend specific performance improvements
Include benchmarking and measurement strategies.
```

## Cross-Platform Compatibility

```text
Resolve cross-platform compatibility issues for [CODE_COMPONENT]:
1. Identify Windows-specific cmdlets and operations
2. Check file path handling and separator usage
3. Validate case sensitivity considerations
4. Review environment variable access patterns
5. Examine permission and access control differences
6. Assess PowerShell version and feature availability
7. Check for platform-specific external dependencies
8. Validate network and connectivity assumptions
9. Review file system behavior differences
10. Provide platform-agnostic solutions and alternatives
Include testing strategies for multiple platforms.
```

## Configuration Problems

```text
Troubleshoot configuration issues for [SYSTEM_COMPONENT]:
1. Validate configuration file syntax and structure
2. Check configuration loading and parsing logic
3. Examine environment variable resolution and defaults
4. Verify configuration inheritance and override behavior
5. Assess configuration validation and error reporting
6. Review cross-platform configuration differences
7. Check for missing or incorrect configuration values
8. Validate configuration security and access controls
9. Examine configuration change detection and reloading
10. Provide configuration repair and validation procedures
Include configuration testing and verification steps.
```

## Networking and Connectivity

```text
Diagnose networking and connectivity issues for [NETWORK_COMPONENT]:
1. Validate network endpoint accessibility and configuration
2. Check authentication and credential management
3. Examine timeout and retry logic implementation
4. Review SSL/TLS certificate validation and trust
5. Assess proxy and firewall configuration impacts
6. Validate DNS resolution and network path issues
7. Check for intermittent connectivity and error handling
8. Review network operation logging and diagnostics
9. Examine cross-platform networking differences
10. Provide network troubleshooting and testing procedures
Include network validation and monitoring recommendations.
```

## File System Operations

```text
Resolve file system operation issues for [FILE_COMPONENT]:
1. Validate file and directory path resolution
2. Check file access permissions and security contexts
3. Examine file locking and concurrent access issues
4. Review file operation error handling and recovery
5. Assess cross-platform file system differences
6. Validate file encoding and character set handling
7. Check for disk space and quota limitations
8. Examine file system monitoring and change detection
9. Review temporary file handling and cleanup
10. Provide file operation testing and validation procedures
Include file system compatibility and best practices.
```

## Memory and Resource Issues

```text
Diagnose memory and resource problems in [COMPONENT]:
1. Identify memory leaks and resource retention issues
2. Analyze object disposal and garbage collection patterns
3. Examine large object handling and streaming strategies
4. Review resource cleanup in error conditions
5. Assess concurrent access and thread safety issues
6. Validate connection and handle management
7. Check for excessive object creation and caching opportunities
8. Review memory-intensive operations and optimizations
9. Examine resource pooling and reuse strategies
10. Provide memory profiling and monitoring recommendations
Include resource management best practices and testing.
```

## Authentication and Authorization

```text
Troubleshoot authentication and authorization issues for [SECURITY_COMPONENT]:
1. Validate credential collection and storage mechanisms
2. Check authentication protocol implementation and compatibility
3. Examine authorization and permission validation logic
4. Review credential caching and refresh procedures
5. Assess cross-platform authentication differences
6. Validate secure credential transmission and handling
7. Check for authentication timeout and retry logic
8. Examine multi-factor authentication and token handling
9. Review audit logging and security event tracking
10. Provide security testing and validation procedures
Include security best practices and compliance considerations.
```

# Pester Testing Prompts

## Comprehensive Test Suite Generation

```text
Generate a complete Pester 5.0+ test suite for [MODULE_OR_FUNCTION] that includes:
1. #Requires -Module Pester and #Requires -Version 7.0 headers
2. Describe-Context-It structure with logical test organization
3. BeforeAll setup for test environment and mocking
4. AfterAll cleanup for proper test isolation
5. Unit tests for all public functions with parameter validation
6. Integration tests for module interactions and dependencies
7. Cross-platform tests for Windows, Linux, and macOS scenarios
8. Error handling tests with proper exception validation
9. Performance tests for operations that may be time-sensitive
10. Mock implementations for external dependencies and system calls
Follow the existing test patterns in the project's test directory.
```

## Test Debugging and Failure Analysis

```text
Analyze these Pester test failures and provide:
1. Root cause analysis for each failing test
2. Specific code fixes for the implementation (not test code)
3. Verification steps to confirm the fixes work
4. Recommendations for preventing similar failures
5. Additional test scenarios to cover edge cases
6. Integration impact assessment for changes
Focus on fixing the underlying implementation while maintaining test integrity.
```

## Mock Strategy Development

```text
Create a comprehensive mocking strategy for [COMPONENT] that:
1. Identifies all external dependencies requiring mocks
2. Implements proper Mock scoping (Describe/Context/It level)
3. Creates reusable mock objects for common scenarios
4. Handles both success and failure scenarios
5. Validates mock call counts and parameters
6. Ensures mocks don't interfere with other tests
7. Provides clear mock setup and teardown procedures
Include examples of complex mocking scenarios like file operations, network calls, and system commands.
```

## Performance Test Implementation

```text
Implement performance tests for [FUNCTION_OR_MODULE] that:
1. Measure execution time for different input sizes
2. Test memory usage and resource consumption
3. Validate performance under load conditions
4. Check for memory leaks and resource cleanup
5. Compare performance across different platforms
6. Set appropriate performance thresholds and assertions
7. Include baseline measurements for regression testing
Use Pester's Measure-Command and performance assertion capabilities.
```

## Cross-Platform Test Coverage

```text
Create cross-platform tests for [COMPONENT] that validate:
1. File path handling (forward vs. backward slashes)
2. PowerShell cmdlet compatibility across platforms
3. Environment variable behavior differences
4. Permission and access control variations
5. Case sensitivity considerations for file systems
6. Network and connectivity differences
7. PowerShell version-specific behavior
Structure tests to skip platform-specific scenarios appropriately using Skip and SkipBecause.
```

## Test Data and Fixtures

```text
Design test data and fixtures for [TEST_SCENARIO] that include:
1. Representative sample data covering common use cases
2. Edge cases and boundary conditions
3. Invalid data for negative testing
4. Large datasets for performance validation
5. Platform-specific test data variations
6. Reusable test fixtures and helper functions
7. Clean data generation and cleanup procedures
Organize test data in a maintainable structure with proper isolation.
```

## Integration Test Strategy

```text
Develop integration tests for [MODULE_COMBINATION] that:
1. Test real module interactions without mocking
2. Validate configuration and dependency management
3. Test complete workflows and user scenarios
4. Include database, file system, and network operations
5. Validate logging and error reporting integration
6. Test concurrent execution and thread safety
7. Include rollback and recovery scenarios
Structure tests to run independently and clean up properly.
```

## Test Infrastructure Optimization

```text
Optimize the Pester test infrastructure for:
1. Faster test execution and parallel running
2. Better test isolation and cleanup
3. Improved test discovery and categorization
4. Enhanced reporting and output formatting
5. CI/CD integration and automation
6. Test result analysis and trending
7. Resource usage optimization
Provide specific recommendations for the current test configuration and structure.
```

## Parameterized Test Design

```text
Create parameterized tests for [FUNCTION] using TestCases that:
1. Cover multiple input combinations efficiently
2. Include boundary conditions and edge cases
3. Test different parameter sets systematically
4. Validate error conditions with various inputs
5. Include platform-specific parameter variations
6. Provide clear test case descriptions and context
7. Enable easy addition of new test scenarios
Structure TestCases for maintainability and clear failure reporting.
```

## Test Documentation and Maintenance

```text
Create comprehensive test documentation for [MODULE] including:
1. Test purpose and coverage explanation
2. Setup and configuration requirements
3. Test execution instructions and options
4. Mock and fixture documentation
5. Expected test results and success criteria
6. Troubleshooting guide for common test issues
7. Maintenance procedures for test updates
Follow the project's documentation standards and professional language requirements.
```

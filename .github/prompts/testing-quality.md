# Testing & Quality Assurance Prompts

## Pester Test Development

### Comprehensive Test Suite

```text
Generate comprehensive Pester tests for [COMPONENT_NAME] that include:
- Unit tests with proper mocking of external dependencies
- Integration tests for cross-module functionality
- Parameter validation tests for all function parameters
- Error handling tests for exception scenarios
- Cross-platform compatibility tests
- Performance tests for resource-intensive operations
```

### Mock Strategy Development

```text
Create a comprehensive mocking strategy for testing [FUNCTION_NAME] that:
- Mocks all external dependencies (file system, network, etc.)
- Uses proper Pester 5.0+ mocking syntax
- Implements test isolation with proper setup/teardown
- Includes verification of mock call parameters
- Provides realistic test data and scenarios
```

### Performance Testing

```text
Design performance tests for [COMPONENT_NAME] that:
- Measure execution time and memory usage
- Test with various data sizes and scenarios
- Include baseline comparisons and regression detection
- Use proper Pester test organization (Describe-Context-It)
- Provide meaningful performance metrics and reporting
```

### Cross-Platform Testing

```text
Create cross-platform compatibility tests that verify:
- File path handling works on Windows, Linux, and macOS
- PowerShell 7.0+ feature compatibility
- Module loading and dependency resolution
- Configuration file handling across platforms
- Network and security operations work consistently
```

## Test Data and Fixtures

### Test Data Generation

```text
Generate realistic test data for [SCENARIO] including:
- Valid input data with various edge cases
- Invalid input data for negative testing
- Large datasets for performance testing
- Configuration files with different scenarios
- Mock responses for external API calls
```

### Test Environment Setup

```text
Create test environment setup that:
- Configures isolated test directories and files
- Sets up mock dependencies and services
- Initializes test logging and configuration
- Provides cleanup and teardown procedures
- Ensures test reproducibility and isolation
```

## Integration Testing

### End-to-End Testing

```text
Design end-to-end integration tests for [WORKFLOW] that:
- Test complete user scenarios from start to finish
- Validate interaction between multiple modules
- Include realistic data and configuration scenarios
- Test error recovery and rollback procedures
- Provide comprehensive assertion coverage
```

### Module Integration Testing

```text
Create integration tests that verify [MODULE_A] and [MODULE_B] work together by:
- Testing data flow between modules
- Validating shared configuration and state
- Testing error propagation and handling
- Verifying logging and audit trail consistency
- Testing concurrent access and thread safety
```

## Code Quality and Analysis

### Security Testing

```text
Generate security-focused tests that verify:
- Input validation prevents injection attacks
- Credential handling follows security best practices
- File permissions and access controls work correctly
- Sensitive data is properly protected and disposed
- Audit logging captures security-relevant events
```

### Error Handling Validation

```text
Create comprehensive error handling tests that:
- Verify all exceptions are properly caught and logged
- Test error message clarity and usefulness
- Validate error recovery and cleanup procedures
- Test cascading error scenarios
- Ensure consistent error handling patterns across modules
```

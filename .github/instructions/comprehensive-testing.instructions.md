---
applyTo: "**/*"
description: "Comprehensive testing strategy and implementation guidelines"
---

# Comprehensive Testing Instructions

## Testing Strategy
- Implement multiple testing levels: unit, integration, system, and acceptance
- Use test-driven development (TDD) approach where appropriate
- Implement behavior-driven development (BDD) for complex scenarios
- Create comprehensive test coverage for all public APIs
- Include performance and load testing for critical operations

## Test Categories

### Unit Testing
- Test individual functions and methods in isolation
- Mock all external dependencies and system calls
- Validate input/output behavior and edge cases
- Test error conditions and exception handling
- Achieve minimum 80% code coverage for all modules

### Integration Testing
- Test module interactions and dependencies
- Validate configuration management and loading
- Test cross-platform compatibility scenarios
- Validate logging and monitoring integrations
- Test infrastructure deployment workflows

### System Testing
- Test complete end-to-end workflows
- Validate system performance and resource usage
- Test backup and recovery procedures
- Validate monitoring and alerting systems
- Test disaster recovery scenarios

### Acceptance Testing
- Validate business requirements and use cases
- Test user workflows and scenarios
- Validate documentation and examples
- Test deployment and operational procedures
- Validate compliance and security requirements

## Test Implementation

### Test Structure and Organization
- Organize tests by module and functionality
- Use descriptive test names that explain the scenario
- Group related tests using Context blocks
- Implement proper test setup and teardown
- Use TestDrive for temporary file operations

### Mock Strategies
- Mock external APIs and network calls
- Mock file system operations and commands
- Mock Write-CustomLog for logging validation
- Use parameter filters for precise mock matching
- Verify mock calls with Assert-MockCalled

### Test Data Management
- Create reusable test data fixtures
- Use TestDrive for temporary test files
- Implement test data cleanup procedures
- Use realistic but sanitized test data
- Manage test database and configuration data

### Cross-Platform Testing
- Test on Windows, Linux, and macOS platforms
- Validate path handling and file operations
- Test environment variable usage
- Validate PowerShell host compatibility
- Test command availability across platforms

### Performance Testing
- Use Measure-Command for execution time validation
- Monitor memory usage during tests
- Test with realistic data volumes
- Validate performance benchmarks and SLAs
- Implement performance regression testing

### Security Testing
- Test input validation and sanitization
- Validate access controls and permissions
- Test for information disclosure in errors
- Validate secure credential handling
- Test for injection vulnerabilities

## Test Automation

### CI/CD Integration
- Configure automated test execution in pipelines
- Set up multi-platform test matrices
- Implement test result reporting and analysis
- Configure code coverage reporting
- Set up performance benchmark validation

### Test Reporting
- Generate comprehensive test reports
- Include code coverage metrics
- Provide performance benchmark results
- Document test failures and resolutions
- Maintain test execution history and trends

### Test Maintenance
- Regular review and update of test cases
- Remove obsolete or redundant tests
- Update tests for changing requirements
- Maintain test documentation and examples
- Regular performance and quality assessment

Follow all standards from the [copilot instructions](../.github/copilot-instructions.md) and ensure comprehensive test coverage and quality.

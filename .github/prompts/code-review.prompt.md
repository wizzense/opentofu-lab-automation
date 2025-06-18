---
mode: 'agent'
tools: ['codebase']
description: 'Perform comprehensive code review and quality assessment'
---

Perform a comprehensive code review and quality assessment for the OpenTofu Lab Automation project.

## Requirements
Ask for the specific files or modules to review if not provided in the prompt.

The code review should include:

### Code Quality Standards
- Check for PowerShell 7.0+ compatibility and cross-platform best practices
- Verify proper error handling and logging implementation
- Ensure module imports use absolute paths and -Force parameter
- Validate that paths use forward slashes for cross-platform compatibility
- Check for proper parameter validation and SupportsShouldProcess usage
- Verify adherence to project coding standards and conventions
- Ensure proper documentation and inline comments

### Security Assessment
- Scan for hardcoded credentials or sensitive information
- Validate input sanitization and parameter validation
- Check for proper access controls and permissions
- Review error handling for information disclosure
- Validate secure communication protocols
- Check for injection vulnerabilities
- Review cryptographic implementations

### Performance Review
- Identify potential performance bottlenecks
- Check for inefficient algorithms or data structures
- Review memory usage and resource management
- Validate proper disposal of resources
- Check for unnecessary computations or operations
- Review caching strategies and implementations

### Architecture and Design
- Validate module structure and organization
- Check for proper separation of concerns
- Review dependency management and coupling
- Validate interface design and contracts
- Check for consistent patterns and conventions
- Review error propagation and handling strategies

### Testing Coverage
- Validate test coverage for all public functions
- Check for test quality and effectiveness
- Review mock strategies and implementations
- Validate cross-platform test scenarios
- Check for integration and end-to-end tests
- Review test data management and cleanup

### Documentation Quality
- Check for comprehensive help documentation
- Validate usage examples and API documentation
- Review troubleshooting guides and common issues
- Check for up-to-date README files
- Validate architectural decision records (ADRs)
- Review inline code comments and explanations

### Maintainability
- Check for code duplication and reusability
- Validate consistent naming conventions
- Review function and module complexity
- Check for proper abstraction levels
- Validate configuration management
- Review version control and change management

### Compliance and Standards
- Validate adherence to PowerShell best practices
- Check for compliance with project standards
- Review logging and monitoring implementations
- Validate backup and recovery procedures
- Check for proper CI/CD integration
- Review security and compliance requirements

Provide specific recommendations for improvements, including code examples where appropriate. Follow all standards from the [copilot instructions](../.github/copilot-instructions.md).

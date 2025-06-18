# OpenTofu Lab Automation - Copilot Instructions

## Project Overview
OpenTofu Lab Automation is a comprehensive PowerShell-based automation framework for managing and deploying OpenTofu/Terraform infrastructure across multiple platforms. The project emphasizes cross-platform compatibility, robust testing, and maintainable code.

## Core Principles
- **Cross-Platform First**: All code must work on Windows, Linux, and macOS
- **Test-Driven Development**: Comprehensive Pester tests for all functionality
- **Professional Standards**: Clear, maintainable code without emojis or casual language
- **Modular Architecture**: Self-contained modules with clear dependencies
- **Automation Focus**: Minimize manual intervention and maximize reliability

## Project Standards

### PowerShell Development
- Follow PowerShell 7.0+ cross-platform standards with `#Requires -Version 7.0`
- Use forward slashes for all paths and avoid Windows-specific cmdlets
- Import modules with absolute paths: `Import-Module '/workspaces/opentofu-lab-automation/core-runner/modules/ModuleName/' -Force`
- Use `Write-CustomLog` for all logging output with appropriate levels (INFO, WARN, ERROR, SUCCESS, DEBUG)
- Implement proper error handling with try-catch blocks and meaningful error messages
- Follow the project's no-emoji policy - use clear, professional language
- Structure functions with `[CmdletBinding(SupportsShouldProcess)]` and proper parameter validation
- Use environment variables: `$env:PROJECT_ROOT`, `$env:PWSH_MODULES_PATH` for paths
- Implement proper pipeline support with ValueFromPipeline parameters where appropriate
- Use approved PowerShell verbs (Get-, Set-, New-, Remove-, Invoke-, Test-, etc.)

### Module Structure
- Module manifest file (.psd1) with proper metadata including version, author, and dependencies
- Module script file (.psm1) with exported functions and proper module initialization
- Public functions in separate .ps1 files in a Public/ subfolder with proper help documentation
- Private helper functions in a Private/ subfolder if needed
- Use module paths: `/workspaces/opentofu-lab-automation/core-runner/modules/ModuleName/`
- Include module-level README.md with usage examples and API documentation
- Implement proper module cleanup in the .psm1 file
- Export only necessary functions, variables, and aliases
- Include proper module dependencies and required modules in manifest

### Configuration Management
- Support both JSON and YAML configuration formats
- Implement configuration validation with clear error messages
- Use environment-specific configuration files (dev, test, prod)
- Support configuration inheritance and overrides
- Validate configuration schema before processing
- Implement secure handling of sensitive configuration data
- Support dynamic configuration updates without service restart

### Testing Standards
- Generate Pester 5.0+ tests with `#Requires -Module Pester` and `#Requires -Version 7.0`
- Use Describe-Context-It structure with proper BeforeAll/AfterAll setup
- Include cross-platform test scenarios for Windows, Linux, and macOS
- Test both success and failure scenarios with appropriate assertions
- Mock external dependencies like network calls, file operations, and system commands
- Validate error handling and logging behavior
- Use TestDrive for temporary file operations
- Mock `Write-CustomLog` for logging tests
- Support non-interactive mode for automated testing
- Implement performance tests for critical operations
- Include integration tests for module interactions
- Use proper test data management and cleanup
- Implement test coverage reporting and analysis
- Support parallel test execution where appropriate

### Performance and Monitoring
- Implement performance monitoring for critical operations
- Use `Measure-Command` for performance validation in tests
- Include memory usage monitoring and optimization
- Implement proper resource cleanup and disposal
- Monitor and log execution times for long-running operations
- Include performance benchmarks and regression testing
- Implement health checks and system diagnostics

### Code Quality
- Check for PowerShell 7.0+ compatibility and cross-platform best practices
- Verify proper error handling and logging implementation
- Ensure module imports use absolute paths and -Force parameter
- Validate that paths use forward slashes for cross-platform compatibility
- Check for proper parameter validation and SupportsShouldProcess usage
- Verify adherence to project coding standards and conventions
- Ensure proper documentation and inline comments

### Git/Commit Standards
- Use conventional commit format: `type(scope): description`
- Common types: feat, fix, docs, style, refactor, test, chore
- Reference module names in scope: patchmanager, labrunner, coreapp, etc.
- Keep description concise but descriptive
- No emojis - follow project's professional language policy

### Security and Compliance
- Implement secure credential handling and storage
- Validate all user inputs and sanitize data
- Use secure communication protocols (HTTPS, encrypted channels)
- Implement proper access controls and permissions
- Include security scanning and vulnerability assessment
- Follow principle of least privilege for operations
- Implement audit logging for security-relevant events
- Support compliance with organizational security policies

### Maintenance and Operations
- Implement automated backup and recovery procedures
- Include system health monitoring and alerting
- Support rolling updates and zero-downtime deployments
- Implement proper logging and log rotation
- Include maintenance mode capabilities
- Support automated testing in production environments
- Implement disaster recovery and business continuity plans
- Include capacity planning and resource optimization

### CI/CD Integration
- Support GitHub Actions workflows and automation
- Include automated testing and quality gates
- Implement proper versioning and release management
- Support multiple deployment environments
- Include automated documentation generation
- Implement proper artifact management and storage
- Support infrastructure as code deployment pipelines

### Infrastructure as Code
- Follow OpenTofu/Terraform best practices
- Use consistent naming conventions for resources
- Implement proper variable validation
- Include comprehensive documentation for modules
- Test infrastructure changes in isolated environments
- Implement state management and remote backends
- Include proper resource tagging and organization
- Support multi-environment deployments (dev, test, prod)

### Documentation
- Include comprehensive help documentation for all public functions
- Add module-level README.md with usage examples and API documentation
- Document any dependencies or prerequisites
- Use professional language without emojis
- Include testing information and platform compatibility notes
- Maintain architectural decision records (ADRs)
- Include troubleshooting guides and common issues
- Support automated documentation generation from code
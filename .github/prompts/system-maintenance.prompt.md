---
mode: 'agent'
tools: ['codebase', 'run_terminal']
description: 'Perform comprehensive system maintenance and health checks'
---

Perform system maintenance and health checks for the OpenTofu Lab Automation project.

## Requirements
Ask for the specific maintenance task if not provided in the prompt.

The maintenance should include:

### System Health Checks
- Validate all module manifests and dependencies
- Check PowerShell 7.0+ compatibility across all scripts
- Verify cross-platform path usage and compatibility
- Test logging functionality and output formats
- Validate configuration file integrity and schema

### Performance Monitoring
- Monitor execution times for critical operations
- Check memory usage and resource consumption
- Validate test execution performance
- Monitor infrastructure deployment times
- Check for performance regressions

### Security Audits
- Scan for hardcoded credentials or sensitive data
- Validate input sanitization and parameter validation
- Check for proper error handling and information disclosure
- Audit access controls and permissions
- Validate secure communication protocols

### Code Quality Assessment
- Run PSScriptAnalyzer on all PowerShell files
- Check for adherence to project coding standards
- Validate proper use of approved PowerShell verbs
- Check for consistent error handling patterns
- Validate proper logging implementation

### Dependencies and Updates
- Check for outdated module dependencies
- Validate required PowerShell modules are available
- Check for security updates in dependencies
- Validate compatibility with latest PowerShell versions
- Update documentation for any changes

### Backup and Recovery
- Verify backup procedures are functioning
- Test recovery procedures and documentation
- Validate configuration backup integrity
- Check log rotation and archival processes
- Test disaster recovery procedures

Follow all standards from the [copilot instructions](../.github/copilot-instructions.md) and ensure comprehensive documentation of all findings and actions taken.

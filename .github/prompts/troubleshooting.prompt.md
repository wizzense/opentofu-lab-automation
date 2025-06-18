---
mode: 'agent'
tools: ['codebase', 'run_terminal']
description: 'Troubleshoot and diagnose system issues'
---

Troubleshoot and diagnose issues in the OpenTofu Lab Automation project.

## Requirements
Ask for the specific issue or error if not provided in the prompt.

The troubleshooting should include:

### Error Analysis
- Analyze error messages and stack traces
- Identify root cause of failures
- Check for common configuration issues
- Validate environment variable settings
- Review log files for relevant information

### Module Issues
- Diagnose module loading failures
- Check module dependencies and versions
- Validate module manifest integrity
- Test module functions individually
- Check for cross-platform compatibility issues

### Performance Problems
- Identify performance bottlenecks
- Analyze memory usage patterns
- Check for resource leaks
- Monitor execution times
- Identify inefficient code patterns

### Configuration Issues
- Validate configuration file syntax and structure
- Check for missing or invalid configuration values
- Verify environment-specific settings
- Test configuration inheritance and overrides
- Validate sensitive data handling

### Network and Connectivity
- Diagnose network connectivity issues
- Check API endpoints and authentication
- Validate certificate and SSL issues
- Test proxy and firewall configurations
- Check for timeout and retry logic

### Testing Failures
- Analyze test failure patterns
- Check mock configurations and data
- Validate test environment setup
- Review test data and fixtures
- Check for test isolation issues

### Infrastructure Problems
- Diagnose OpenTofu/Terraform issues
- Check state file integrity
- Validate provider configurations
- Review resource dependencies
- Check for infrastructure drift

### Resolution Steps
- Provide step-by-step troubleshooting guide
- Include workarounds for known issues
- Document permanent fixes and preventive measures
- Update relevant documentation
- Create or update tests to prevent regression

Follow all standards from the [copilot instructions](../.github/copilot-instructions.md) and provide comprehensive documentation of the troubleshooting process and resolution.

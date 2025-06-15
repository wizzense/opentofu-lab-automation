---
description: Perform comprehensive security review of PowerShell scripts and infrastructure code
mode: agent
tools: ["filesystem", "powershell", "security"]
---

# Security Review

Perform a comprehensive security review of PowerShell scripts, configuration files, and infrastructure code in the OpenTofu Lab Automation project.

## Review Scope

Analyze the following security aspects:

1. **Script Security**:
   - Execution policy compliance
   - Input validation and sanitization
   - Privilege escalation risks
   - External dependency security
   - Credential handling

2. **Configuration Security**:
   - Secrets management
   - File permissions
   - Access controls
   - Environment variable usage

3. **Infrastructure Security**:
   - Network access patterns
   - Service configurations
   - Firewall rules
   - Certificate management

4. **Workflow Security**:
   - GitHub Actions security
   - Secret handling in CI/CD
   - Permission models
   - Supply chain security

## Security Checklist

### Script Security Analysis

```powershell
# Check for common security issues:

# 1. Input Validation
- [ ] All parameters properly validated
- [ ] No direct string concatenation in commands
- [ ] Path traversal prevention
- [ ] SQL injection prevention (if applicable)

# 2. Privilege Management  
- [ ] Runs with minimum required privileges
- [ ] No unnecessary admin rights
- [ ] Proper UAC handling on Windows

# 3. External Dependencies
- [ ] All downloads from trusted sources
- [ ] Checksums verified for downloads
- [ ] No execution of untrusted code
- [ ] Module imports from known sources

# 4. Credential Handling
- [ ] No hardcoded passwords or keys
- [ ] Proper secret management
- [ ] Secure credential storage
- [ ] Token expiration handling
```

### Configuration Security

```yaml
# Configuration file security review:

security:
  # Secrets management
  secrets:
    - type: "environment_variables"
      validation: "required"
    - type: "key_vault"
      validation: "recommended"
      
  # File permissions
  permissions:
    scripts: "755"
    configs: "644"
    secrets: "600"
    
  # Access controls
  access:
    read: ["developers", "ci_cd"]
    write: ["maintainers"]
    execute: ["automation_service"]
```

### Security Patterns to Check

1. **Safe PowerShell Patterns**:
   ```powershell
   #  Good: Parameter validation
   [ValidateSet('Option1', 'Option2')]
   [string]$Choice
   
   #  Good: Path validation
   $safePath = Resolve-Path $InputPath -ErrorAction Stop
   
   #  Bad: Direct string execution
   Invoke-Expression $UserInput
   ```

2. **Secure File Operations**:
   ```powershell
   #  Good: Safe file operations
   if (Test-Path $ConfigFile) {
       $config = Get-Content $ConfigFile | ConvertFrom-Json
   }
   
   #  Bad: Unsafe file access
   $content = [System.IO.File]::ReadAllText($UserProvidedPath)
   ```

3. **Network Security**:
   ```powershell
   #  Good: TLS enforcement
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   
   #  Good: Certificate validation
   Invoke-WebRequest -Uri $url -UseBasicParsing -Certificate $cert
   ```

## Security Findings Template

Generate findings using this format:

```markdown
## Security Review Findings

### Critical Issues
- **Issue**: [Description]
  - **File**: [Path/to/file]
  - **Line**: [Line number]
  - **Risk**: Critical
  - **Recommendation**: [Fix description]

### High Priority Issues
- **Issue**: [Description]
  - **File**: [Path/to/file]  
  - **Risk**: High
  - **Recommendation**: [Fix description]

### Medium Priority Issues
- **Issue**: [Description]
  - **File**: [Path/to/file]
  - **Risk**: Medium
  - **Recommendation**: [Fix description]

### Best Practice Recommendations
- [Recommendation 1]
- [Recommendation 2]
- [Recommendation 3]

### Security Score: [X/10]

### Action Items
1. [ ] Fix critical issues immediately
2. [ ] Address high priority issues within 1 week
3. [ ] Plan medium priority fixes for next sprint
4. [ ] Implement security monitoring
```

## Analysis Areas

Focus on these specific areas in the codebase:

1. **PowerShell Scripts** (`/pwsh/`, `/scripts/`):
   - Parameter validation
   - External command execution  
   - File system operations
   - Network requests

2. **Test Files** (`/tests/`):
   - Mock security
   - Test data handling
   - Temporary file cleanup

3. **Workflows** (`.github/workflows/`):
   - Secret usage
   - Permission models
   - External action security

4. **Configuration** (`/configs/`):
   - Sensitive data handling
   - Access permissions
   - Validation rules

## Security Tools Integration

Leverage these security tools where available:

```powershell
# PSScriptAnalyzer security rules
Invoke-ScriptAnalyzer -Path $ScriptPath -IncludeRule PSAvoidUsingPlainTextForPassword,PSAvoidUsingInvokeExpression

# CodeFixer security validation  
Invoke-PowerShellLint -SecurityFocus

# Runner script safety check
Test-RunnerScriptSafety -Path $ScriptPath -Detailed
```

## Input Variables

- `${selection}`: Selected code or files to review
- `${input:scope}`: Specific security focus area
- `${input:priority}`: Priority level (critical, high, medium, all)

Please specify:
1. Files or directory to review
2. Specific security concerns or focus areas
3. Priority level for findings
4. Output format preference (markdown, json, text)

---
applyTo: "**/*.{yml,yaml}"
description: YAML and workflow standards for GitHub Actions and configuration files
---

# YAML and Workflow Standards

## YAML Formatting Rules

Always follow these YAML standards:

```yaml
# Use 2-space indentation consistently
name: "Workflow Name"
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  # Job names use kebab-case
  lint-and-test:
    name: "Lint and Test"
    runs-on: ubuntu-latest
    
    steps:
      # Step names are descriptive
      - name: "Checkout Repository"
        uses: actions/checkout@v4
        
      - name: "Setup PowerShell"
        uses: actions/setup-powershell@v1
        with:
          pwsh: true
```

## Workflow Structure Standards

Every workflow should include these elements:

```yaml
name: "Descriptive Workflow Name"

on:
  # Specify clear triggers
  
env:
  # Global environment variables
  POWERSHELL_TELEMETRY_OPTOUT: 1
  
jobs:
  # Validation job (always first)
  validate:
    name: "Validate Workflow"
    runs-on: ubuntu-latest
    steps:
      - name: "Validate YAML"
        run: yamllint .github/workflows/
        
  # Main jobs follow validation
  main-job:
    needs: validate
    # Job implementation
```

## PowerShell Integration in Workflows

Use consistent PowerShell execution patterns:

```yaml
- name: "Execute PowerShell Script"
  shell: pwsh
  run: |
    $ErrorActionPreference = "Stop"
    Import-Module "./pwsh/modules/LabRunner/" -Force
    
    # Your PowerShell code here
    Write-CustomLog "Workflow step completed" "INFO"
```

## Configuration File Standards

For lab_config.yaml and similar files:

```yaml
# Configuration metadata
metadata:
  version: "1.0.0"
  description: "Lab configuration for OpenTofu automation"
  
# Environment settings
environment:
  platform: "cross-platform"
  shell: "pwsh"
  
# Module configuration
modules:
  codefixer:
    enabled: true
    parallel_processing: true
    max_jobs: 4
    
  labrunner:
    enabled: true
    logging_level: "INFO"
    
# Validation settings
validation:
  yamllint:
    enabled: true
    rules: "configs/yamllint.yaml"
  
  powershell:
    enabled: true
    analyzer: "PSScriptAnalyzer"
```

## Error Handling in Workflows

Include proper error handling and reporting:

```yaml
- name: "Execute with Error Handling"
  shell: pwsh
  run: |
    try {
      # Your operation
      Write-Host "Operation successful" -ForegroundColor Green
    } catch {
      Write-Host "Operation failed: $_" -ForegroundColor Red
      exit 1
    }
  continue-on-error: false
```

## Cross-Platform Workflow Patterns

Support multiple platforms when needed:

```yaml
strategy:
  matrix:
    os: [ ubuntu-latest, windows-latest, macos-latest ]
    include:
      - os: ubuntu-latest
        shell: pwsh
      - os: windows-latest
        shell: pwsh
      - os: macos-latest
        shell: pwsh

runs-on: ${{ matrix.os }}

steps:
  - name: "Cross-Platform Setup"
    shell: ${{ matrix.shell }}
    run: |
      # Platform-agnostic PowerShell code
```

## Security Considerations

Apply security best practices:

```yaml
# Use specific action versions
- uses: actions/checkout@v4.1.1

# Limit permissions
permissions:
  contents: read
  actions: read
  
# Use secrets properly
env:
  API_TOKEN: ${{ secrets.API_TOKEN }}
  
# Validate inputs
- name: "Validate Inputs"
  run: |
    if (-not $env:REQUIRED_VAR) {
      throw "Required variable not set"
    }
```

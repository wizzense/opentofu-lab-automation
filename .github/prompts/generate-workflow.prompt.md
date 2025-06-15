---
description: Create or update GitHub Actions workflows following OpenTofu Lab Automation standards
mode: agent  
tools: ["filesystem", "yaml"]
---

# Generate GitHub Actions Workflow

Create or update GitHub Actions workflows that follow the OpenTofu Lab Automation project standards for CI/CD, testing, and automation.

## Workflow Requirements

Generate workflows that include:

1. **Standard Structure**:
   - Proper naming and triggers
   - Environment variables
   - Job dependencies and strategy
   - Cross-platform support when needed

2. **PowerShell Integration**:
   - Consistent PowerShell execution
   - Module loading patterns
   - Error handling and reporting

3. **Security Best Practices**:
   - Minimal permissions
   - Secret handling
   - Action version pinning
   - Input validation

4. **Performance Optimization**:
   - Parallel job execution
   - Caching strategies
   - Efficient resource usage

## Base Workflow Template

```yaml
name: "${input:workflowName}"

on:
  push:
    branches: [ main, develop ]
    paths:
      - '${input:triggerPaths}'
  pull_request:
    branches: [ main ]
    paths:
      - '${input:triggerPaths}'
  workflow_dispatch:
    inputs:
      debug:
        description: 'Enable debug logging'
        required: false
        default: 'false'
        type: boolean

env:
  POWERSHELL_TELEMETRY_OPTOUT: 1
  DOTNET_NOLOGO: 1
  
permissions:
  contents: read
  actions: read

jobs:
  # Validation job - always runs first
  validate:
    name: "Validate Workflow"
    runs-on: ubuntu-latest
    
    steps:
      - name: "Checkout Repository"
        uses: actions/checkout@v4.1.1
        
      - name: "Validate YAML Syntax"
        run: |
          sudo apt-get update
          sudo apt-get install -y yamllint
          yamllint .github/workflows/
          
      - name: "Validate PowerShell Syntax"
        shell: pwsh
        run: |
          $ErrorActionPreference = "Stop"
          Get-ChildItem -Path "." -Filter "*.ps1" -Recurse | ForEach-Object {
            $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
            Write-Host " $($_.Name) syntax valid"
          }

  # Main workflow job
  main:
    name: "${input:jobName}"
    needs: validate
    runs-on: ${{ matrix.os }}
    
    strategy:
      matrix:
        os: [ ubuntu-latest, windows-latest ]
        include:
          - os: ubuntu-latest
            shell: pwsh
          - os: windows-latest  
            shell: pwsh
      fail-fast: false
      
    steps:
      - name: "Checkout Repository"
        uses: actions/checkout@v4.1.1
        
      - name: "Setup PowerShell"
        uses: actions/setup-powershell@v1
        with:
          pwsh: true
          
      - name: "Install Required Modules"
        shell: ${{ matrix.shell }}
        run: |
          $ErrorActionPreference = "Stop"
          
          # Install PSScriptAnalyzer
          if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
            Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
          }
          
          # Install Pester
          if (-not (Get-Module -ListAvailable Pester)) {
            Install-Module Pester -RequiredVersion 5.7.1 -Force -Scope CurrentUser
          }
          
      - name: "Load Project Modules"
        shell: ${{ matrix.shell }}
        run: |
          $ErrorActionPreference = "Stop"
          
          # Import LabRunner
          Import-Module "./pwsh/modules/LabRunner/" -Force
          Write-Host " LabRunner module loaded"
          
          # Import CodeFixer
          Import-Module "./pwsh/modules/CodeFixer/" -Force  
          Write-Host " CodeFixer module loaded"
          
      - name: "${input:mainStepName}"
        shell: ${{ matrix.shell }}
        run: |
          $ErrorActionPreference = "Stop"
          
          try {
            # Your main workflow logic here
            Write-Host "Executing main workflow step..." -ForegroundColor Green
            
            # Example: Run validation
            Invoke-ComprehensiveValidation -OutputFormat "CI"
            
            Write-Host "Workflow completed successfully" -ForegroundColor Green
          } catch {
            Write-Host "Workflow failed: $_" -ForegroundColor Red
            throw
          }
```

## Workflow Types

### 1. Validation Workflow
For code quality and syntax checking:

```yaml
- name: "Run PowerShell Linting"
  shell: pwsh
  run: |
    Import-Module "./pwsh/modules/CodeFixer/" -Force
    Invoke-PowerShellLint -Path "." -Parallel -OutputFormat "CI"
    
- name: "Run Pester Tests"  
  shell: pwsh
  run: |
    Import-Module Pester -RequiredVersion 5.7.1
    $config = New-PesterConfiguration
    $config.Run.Path = "./tests/"
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = "NUnitXml"
    $config.TestResult.OutputPath = "./TestResults.xml"
    Invoke-Pester -Configuration $config
```

### 2. Deployment Workflow
For automated deployments:

```yaml
- name: "Deploy to Environment"
  shell: pwsh
  run: |
    Import-Module "./pwsh/modules/LabRunner/" -Force
    
    $config = [pscustomobject]@{
      Environment = "${{ github.ref_name }}"
      Version = "${{ github.sha }}"
    }
    
    Invoke-LabStep -Config $config -Body {
      Write-CustomLog "Starting deployment..." "INFO"
      # Deployment logic here
    }
```

### 3. Security Workflow
For security scanning and validation:

```yaml
- name: "Security Scan"
  shell: pwsh
  run: |
    Import-Module "./pwsh/modules/LabRunner/" -Force
    
    # Run security validation
    $scripts = Get-ChildItem -Path "./pwsh/" -Filter "*.ps1" -Recurse
    foreach ($script in $scripts) {
      $result = Test-RunnerScriptSafety -Path $script.FullName
      if (-not $result.AutoDeployable) {
        Write-Warning "Security issue in $($script.Name): $($result.Reason)"
      }
    }
```

## Input Variables

- `${input:workflowName}`: Name of the workflow
- `${input:triggerPaths}`: Paths that trigger the workflow  
- `${input:jobName}`: Main job name
- `${input:mainStepName}`: Name of the main execution step
- `${input:workflowType}`: Type of workflow (validation, deployment, security, custom)

## Reference Instructions

This prompt references:
- [YAML Standards](../instructions/yaml-standards.instructions.md)
- [PowerShell Standards](../instructions/powershell-standards.instructions.md)

Please specify:
1. Workflow name and purpose
2. Trigger conditions (paths, events)
3. Main job functionality
4. Platform requirements (cross-platform, Windows-only, etc.)
5. Any specific tools or modules needed

---
description: Generate comprehensive documentation for PowerShell modules, functions, and project components
mode: agent
tools: "filesystem", "documentation"
---

# Generate Documentation

Create comprehensive documentation for PowerShell modules, functions, scripts, and project components following OpenTofu Lab Automation documentation standards.

## Documentation Types

### 1. Module Documentation
Generate complete module documentation including:

```markdown
# ${input:moduleName} PowerShell Module

${input:moduleDescription}

## Overview
The ${input:moduleName} module provides comprehensive functionality for specific purpose. This module is part of the OpenTofu Lab Automation project and follows established patterns and standards.

## Installation
```powershell
Import-Module "/pwsh/modules/${input:moduleName}/" -Force
```

## Architecture
- **Public Functions**: User-facing cmdlets and functions
- **Private Functions**: Internal helper functions  
- **Dependencies**: Required modules and external dependencies
- **Platform Support**: Cross-platform compatibility (Windows, Linux, macOS)

## Functions

### Public Functions
Auto-generated function list with descriptions

### Private Functions  
Internal functions for module operation

## Usage Examples

### Basic Usage
```powershell
# Import the module
Import-Module "/pwsh/modules/${input:moduleName}/" -Force

# Basic operation
${input:basicExample}
```

### Advanced Usage
```powershell
# Advanced scenarios
${input:advancedExample}
```

## Configuration
Module configuration options and settings.

## Dependencies
- LabRunner: `/pwsh/modules/LabRunner/`
- PSScriptAnalyzer (for CodeFixer)
- Pester 5.7.1+ (for testing)

## Development
Guidelines for contributing to the module.

## Troubleshooting
Common issues and their solutions.
```

### 2. Function Documentation
Generate detailed function documentation:

```markdown
## ${input:functionName}

### Synopsis
${input:functionSynopsis}

### Syntax
```powershell
${input:functionName}
    -Parameter1 <Type>
    -Parameter2 <Type>
    -Switch
    <CommonParameters>
```

### Description
${input:functionDescription}

The function integrates with the OpenTofu Lab Automation framework and follows established patterns:
- Uses standardized error handling with `Write-CustomLog`
- Supports cross-platform execution
- Includes comprehensive parameter validation
- Follows performance optimization guidelines

### Parameters

#### -Parameter1 \<Type\>
${input:parameter1Description}

**Type**: ${input:parameter1Type}
**Required**: ${input:parameter1Required}
**Position**: ${input:parameter1Position}
**Default value**: ${input:parameter1Default}
**Accept pipeline input**: ${input:parameter1Pipeline}

### Examples

#### Example 1: Basic Usage
```powershell
PS> ${input:functionName} -Parameter1 "Value"
${input:example1Output}
```

#### Example 2: Pipeline Usage
```powershell
PS> Get-ChildItem  ${input:functionName} -Parameter2 "Value"
${input:example2Output}
```

#### Example 3: Advanced Configuration
```powershell
PS> ${input:functionName} -Parameter1 "Value" -Parameter2 "Advanced" -Switch
${input:example3Output}
```

### Inputs
${input:functionInputs}

### Outputs
${input:functionOutputs}

### Notes
- **Performance**: ${input:performanceNotes}
- **Security**: ${input:securityNotes}
- **Platform**: ${input:platformNotes}

### Related Links
- ${input:relatedFunction1}(#${input:relatedFunction1})
- Module Overview(#module-overview)
```

### 3. Script Documentation
Generate documentation for PowerShell scripts:

```markdown
# ${input:scriptName}

## Purpose
${input:scriptPurpose}

## Synopsis
${input:scriptSynopsis}

## Syntax
```powershell
.\\${input:scriptName}.ps1 -Config <PSCustomObject>
```

## Description
${input:scriptDescription}

This script follows OpenTofu Lab Automation standards:
- Uses `Invoke-LabStep` execution pattern
- Implements standardized error handling
- Supports cross-platform execution
- Includes comprehensive logging

## Parameters

### -Config \<PSCustomObject\>
Configuration object containing script parameters and settings.

**Required Properties**:
${input:requiredConfigProperties}

**Optional Properties**:
${input:optionalConfigProperties}

## Examples

### Example 1: Basic Execution
```powershell
$config = PSCustomObject@{
    ${input:basicConfigExample}
}
.\\${input:scriptName}.ps1 -Config $config
```

### Example 2: Advanced Configuration
```powershell
$config = PSCustomObject@{
    ${input:advancedConfigExample}
}
.\\${input:scriptName}.ps1 -Config $config
```

## Error Handling
The script implements comprehensive error handling:
- Parameter validation
- Graceful failure recovery
- Detailed error logging with `Write-CustomLog`
- Exit codes for automation scenarios

## Dependencies
- LabRunner module: `/pwsh/modules/LabRunner/`
- ${input:additionalDependencies}

## Platform Support
- **Windows**: Full support
- **Linux**: Full support  
- **macOS**: Full support

## Integration
Integration points with other system components:
${input:integrationPoints}

## Troubleshooting
Common issues and solutions:
${input:troubleshootingInfo}
```

### 4. Project Documentation
Generate high-level project documentation:

```markdown
# ${input:projectName}

## Overview
${input:projectOverview}

## Architecture

### Module Structure
```
${input:projectStructure}
```

### Key Components
- **CodeFixer Module**: Automated code analysis and fixing
- **LabRunner Module**: Lab automation execution framework
- **Test Framework**: Comprehensive Pester-based testing
- **Workflows**: GitHub Actions automation

### Data Flow
${input:dataFlowDescription}

## Getting Started

### Prerequisites
- PowerShell 7.0 or higher
- Git for version control
- VS Code (recommended) with PowerShell extension

### Installation
```powershell
# Clone the repository
git clone ${input:repositoryUrl}

# Import required modules
Import-Module "./pwsh/modules/LabRunner/" -Force
Import-Module "./pwsh/modules/CodeFixer/" -Force
```

### Quick Start
```powershell
# Run basic validation
Invoke-ComprehensiveValidation

# Execute sample lab step
$config = PSCustomObject@{ Example = "Value" }
Invoke-LabStep -Config $config -Body { 
    Write-CustomLog "Hello from OpenTofu Lab Automation!" "INFO" 
}
```

## Configuration
Configuration files and their purposes:
${input:configurationInfo}

## Development
Development guidelines and standards:
${input:developmentInfo}

## Deployment
Deployment processes and automation:
${input:deploymentInfo}

## Monitoring
Monitoring and observability features:
${input:monitoringInfo}

## Support
Support channels and resources:
${input:supportInfo}
```

## Auto-Generated Sections

For modules, automatically extract and document:

```powershell
# Extract function information
$module = Get-Module ${input:moduleName}
$functions = Get-Command -Module ${input:moduleName}

foreach ($function in $functions) {
    $help = Get-Help $function.Name -Full
    # Generate documentation from help content
}

# Extract module manifest info
$manifest = Import-PowerShellDataFile "path/to/module.psd1"
# Include version, dependencies, exported functions
```

## Validation and Quality

Ensure documentation quality:

```powershell
# Validate markdown syntax
if (Get-Command markdownlint -ErrorAction SilentlyContinue) {
    markdownlint $DocumentationPath
}

# Check for required sections
$requiredSections = @('Overview', 'Installation', 'Examples', 'Dependencies')
$content = Get-Content $DocumentationFile -Raw

foreach ($section in $requiredSections) {
    if ($content -notmatch "## $section") {
        Write-Warning "Missing required section: $section"
    }
}

# Validate code examples
$codeBlocks = regex::Matches($content, '```powershell\r?\n(.*?)\r?\n```', 'Singleline')
foreach ($block in $codeBlocks) {
    $code = $block.Groups1.Value
    try {
        $null = System.Management.Automation.Language.Parser::ParseInput($code, ref$null, ref$null)
    } catch {
        Write-Warning "Invalid PowerShell syntax in documentation"
    }
}
```

## Input Variables

- `${input:docType}`: Type of documentation (module, function, script, project)
- `${input:moduleName}`: Name of the module being documented
- `${input:functionName}`: Name of the function being documented
- `${input:description}`: Main description of the component

## Reference Instructions

This prompt references:
- Documentation Standards(../instructions/documentation-standards.instructions.md)
- PowerShell Standards(../instructions/powershell-standards.instructions.md)

Please specify:
1. Type of documentation needed (module, function, script, project)
2. Component name and basic description
3. Specific sections or details to emphasize
4. Target audience (developers, users, administrators)

---
applyTo: "**/docs/**/*.md"
description: Documentation standards and formatting guidelines
---

# Documentation Standards Instructions

## Markdown Formatting Standards

### File Structure
Every documentation file should follow this structure:

```markdown
# Document Title

Brief description of the document's purpose and scope.

## Table of Contents
<!-- Example Table of Contents for documentation templates:
- Section 1(#section-1)
- Section 2(#section-2)
- Examples(#examples)
- Reference(#reference)
-->

## Section Content

### Subsections
Use progressive heading levels (##, ###, ####)

## Examples
Always include practical examples

## Reference
Link to related documentation
```

### Code Block Standards
Use proper syntax highlighting:

````markdown
```powershell
# PowerShell code blocks
Import-Module "/pwsh/modules/LabRunner/" -Force
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Example operation" "INFO"
}
```

```yaml
# YAML configuration examples
name: "Configuration Example"
settings:
  enabled: true
```

```json
{
  "example": "JSON configuration",
  "version": "1.0.0"
}
```
````

### Module Documentation

For PowerShell modules, include:

```markdown
# ModuleName PowerShell Module

Brief description of the module's purpose.

## Overview
Detailed description of functionality and use cases.

## Installation
```powershell
Import-Module "/pwsh/modules/ModuleName/" -Force
```

## Functions

### Function-Name
**Synopsis**: Brief function description

**Syntax**:
```powershell
Function-Name -Parameter1 <Type> -Parameter2 <Type>
```

**Parameters**:
- `Parameter1`: Description of required parameter
- `Parameter2`: Description of optional parameter

**Examples**:
```powershell
# Example 1: Basic usage
Function-Name -Parameter1 "Value"

# Example 2: Advanced usage
Function-Name -Parameter1 "Value" -Parameter2 "Optional"
```

**Returns**: Description of return value

## Dependencies
- Module dependencies
- External requirements
- Platform considerations
```

### Project Documentation

For project-level documentation:

```markdown
# Project Name

## Architecture Overview
- Module structure
- Component relationships
- Data flow

## Getting Started
### Prerequisites
- PowerShell 7+
- Required modules
- Platform requirements

### Quick Start
```powershell
# Step-by-step setup
Import-Module "/pwsh/modules/LabRunner/" -Force
```

## Configuration
Reference to configuration files and options

## Development
- Coding standards
- Testing requirements
- Contribution guidelines

## Troubleshooting
Common issues and solutions
```

## API Documentation

For function and cmdlet documentation:

```markdown
## Function-Name

### Synopsis
Brief description of what the function does.

### Syntax
```powershell
Function-Name
    -Parameter1 <Type>
    -Parameter2 <Type>
    -Switch
    <CommonParameters>
```

### Description
Detailed description of the function's behavior, use cases, and important notes.

### Parameters

#### -Parameter1 \<Type\>
Description of the parameter, including:
- Purpose and usage
- Accepted values or validation rules
- Default value (if any)
- Pipeline input support

**Type**: String/Int/Switch/Object
**Required**: True/False
**Position**: Named/1/2
**Default value**: None/Value
**Accept pipeline input**: True/False
**Accept wildcard characters**: True/False

### Inputs
Description of objects that can be piped to the function.

### Outputs
Description of objects returned by the function.

### Examples

#### Example 1: Basic Usage
```powershell
PS> Function-Name -Parameter1 "Value"
Expected output description
```

#### Example 2: Advanced Usage  
```powershell
PS> Get-Something  Function-Name -Parameter2 "Value"
Expected output description
```

### Notes
Additional information about:
- Performance considerations
- Security implications
- Platform-specific behavior
- Version history

### Related Links
- External Documentation(https://example.com)
```

## Formatting Guidelines

### Lists and Tables

Use consistent formatting for lists:

```markdown
## Ordered Lists
1. First item
2. Second item
   - Sub-item
   - Sub-item
3. Third item

## Unordered Lists
- Item one
- Item two
  - Nested item
  - Nested item
- Item three

## Tables
 Column 1  Column 2  Column 3 
------------------------------
 Value 1   Value 2   Value 3  
 Value A   Value B   Value C  
```

### Links and References

```markdown
## Internal Links
Section Reference(#section-name)
Document Reference(./other-document.md)

## External Links
PowerShell Documentation(https://docs.microsoft.com/powershell)

## Code References
Reference functions like `Invoke-LabStep` and modules like `LabRunner`.
```

### Callouts and Alerts

```markdown
> **Note**: Important information that enhances understanding

> **Warning**: Critical information about potential issues

> **Tip**: Helpful suggestions for optimization or best practices
```

## Documentation Validation

Ensure documentation quality with:

```powershell
# Markdown linting (if available)
if (Get-Command markdownlint -ErrorAction SilentlyContinue) {
    markdownlint docs/
}

# Link validation
$content = Get-Content $DocFile -Raw
$links = regex::Matches($content, '\.*?\\((.*?)\)')
foreach ($link in $links) {
    $path = $link.Groups1.Value
    if ($path.StartsWith('./') -and -not (Test-Path $path)) {
        Write-Warning "Broken link: $path"
    }
}

# Code block syntax validation
$codeBlocks = regex::Matches($content, '```(\w+)?\r?\n(.*?)\r?\n```', 'Singleline')
foreach ($block in $codeBlocks) {
    $language = $block.Groups1.Value
    $code = $block.Groups2.Value
    
    if ($language -eq 'powershell') {
        # Validate PowerShell syntax
        try {
            $null = System.Management.Automation.Language.Parser::ParseInput($code, ref$null, ref$null)
        } catch {
            Write-Warning "Invalid PowerShell syntax in code block"
        }
    }
}
```

## Project Maintenance Integration

### Continuous Health Checking
Always integrate documentation with project health validation:

```powershell
# Run health checks before documentation updates
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"

# Validate documentation against current project state
Invoke-ComprehensiveValidation -IncludeDocumentation

# Update project files after documentation changes
./scripts/utilities/update-project-index.ps1
./scripts/utilities/update-manifest.ps1
```

### Self-Validation Requirements
- Document all utilities and their current capabilities
- Reference actual script locations and functions
- Validate examples against live project structure
- Include performance metrics and health targets

### Project File Updates
Always maintain project synchronization:

```powershell
# Update PROJECT-MANIFEST.json when adding new documentation
$manifest = Get-Content "./PROJECT-MANIFEST.json"  ConvertFrom-Json
$manifest.documentation += @{
    file = "docs/new-guide.md"
    type = "user-guide"
    category = "operational"
}
$manifest  ConvertTo-Json -Depth 10  Set-Content "./PROJECT-MANIFEST.json"

# Regenerate project index with new documentation references
./scripts/utilities/update-project-index.ps1

# Log all documentation changes
Write-CustomLog "Documentation updated: $DocumentPath" "INFO"
```

### Issue Tracking Integration
```powershell
# Create documentation task tracking
./scripts/utilities/create-issue.ps1 -Type "documentation" -Title "Update XYZ docs"

# Link documentation to existing issues
./scripts/utilities/link-to-issue.ps1 -IssueId "123" -File "docs/new-guide.md"
```

## GitHub Collaboration Requirements

### Branch Management for Documentation
Follow strict branch management for all documentation changes:

```bash
# ALWAYS create feature branches for documentation changes
git checkout -b "docs/update-xyz-documentation"

# Follow semantic commit conventions
git add docs/
git commit -m "docs: Update XYZ documentation with health check integration

- Add maintenance integration guidelines
- Include validation requirements
- Update project file references
- Add GitHub workflow examples"

# Push and create PR
git push -u origin docs/update-xyz-documentation
```

### Pre-Commit Validation
Run comprehensive validation before any documentation commit:

```powershell
# Run before any documentation commit
./scripts/validation/pre-commit-validation.ps1

# Validate documentation syntax and links
./scripts/validation/validate-documentation.ps1

# Check project health before PR
./scripts/maintenance/unified-maintenance.ps1 -Mode "All"

# Ensure examples execute correctly
./scripts/validation/test-documentation-examples.ps1
```

### CI/CD Integration Requirements
- All documentation PRs must pass automated validation
- Include documentation build checks in CI pipeline
- Require health check pass before merge
- Auto-update project files post-merge
- Test all code examples in multiple environments

### Pull Request Standards
Documentation PRs must include:

```markdown
## Documentation Changes
-   All examples tested and validated
-   Links checked and functional
-   Project health check passed
-   PROJECT-MANIFEST.json updated
-   Cross-platform compatibility verified
-   Accessibility standards met

## Validation Results
```powershell
# Include output from validation scripts
./scripts/validation/validate-documentation.ps1
```

## Review Process
- Technical accuracy review required
- Accessibility compliance check
- Cross-platform testing validation
- Performance impact assessment
```

## Integration Requirements

### Auto-Update Integration
- Link documentation to project manifest updates
- Trigger documentation regeneration on code changes
- Maintain documentation version synchronization
- Include automated link validation

### Search and Discovery
- Implement full-text search capabilities
- Create comprehensive cross-reference systems
- Generate automatic topic indexing
- Enable contextual help integration

## Quality Assurance

### Documentation Testing
- Validate all code examples execute correctly
- Test all links and references regularly
- Verify cross-platform compatibility of examples
- Ensure documentation completeness coverage

### Review Process
- Require documentation updates with code changes
- Implement peer review for documentation changes
- Validate technical accuracy with SME review
- Ensure accessibility compliance

### Continuous Validation
```powershell
# Documentation must validate against live project
Test-DocumentationAccuracy -Path "docs/"

# Verify all referenced utilities exist and work
Test-UtilityReferences -DocumentationPath "docs/"

# Check health metrics match documented capabilities
Compare-DocumentedVsActualCapabilities
```

---
*Apply these standards to all documentation generation and maintenance*
*Ensure integration with project automation and validation systems*
*Always use feature branches and proper GitHub workflow for changes*
*Maintain continuous validation and health checking standards*

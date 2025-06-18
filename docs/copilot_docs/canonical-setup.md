# Canonical Copilot Setup for OpenTofu Lab Automation

## Overview

This document describes the canonical setup and configuration for GitHub Copilot and VS Code in the OpenTofu Lab Automation project, ensuring optimal AI-assisted development experience.

## File Structure

The Copilot configuration is organized as follows:

```
.github/
├── copilot-instructions.md              # Main project instructions
├── instructions/                        # Specialized instructions
│   ├── comprehensive-testing.instructions.md
│   ├── devenvironment.instructions.md
│   ├── logging.instructions.md
│   ├── parallelexecution.instructions.md
│   ├── patchmanager.instructions.md
│   └── powershell-testing.instructions.md
└── prompts/                            # Task-specific prompts
    ├── cicd-management.prompt.md
    ├── code-review.prompt.md
    ├── create-powershell-module.prompt.md
    ├── devenvironment-development.prompt.md
    ├── infrastructure-management.prompt.md
    ├── labrunner-development.prompt.md
    ├── logging-development.prompt.md
    ├── parallelexecution-development.prompt.md
    ├── patchmanager-development.prompt.md
    ├── system-maintenance.prompt.md
    ├── testingframework-development.prompt.md
    └── troubleshooting.prompt.md

.vscode/
├── settings.json                       # VS Code workspace settings
├── tasks.json                         # Development tasks
├── launch.json                        # Debug configurations
└── extensions.json                    # Recommended extensions
```

## Core Components

### 1. Main Instructions (`.github/copilot-instructions.md`)

The primary instruction file containing:

- Project overview and core principles
- PowerShell development standards
- Module structure guidelines
- Testing and quality standards
- Security and compliance requirements
- CI/CD and infrastructure guidelines
- Documentation standards

### 2. Specialized Instructions (`.github/instructions/`)

Module-specific and domain-specific instructions:

- **comprehensive-testing.instructions.md**: Complete testing strategy
- **Module-specific files**: Standards for each project module
- **powershell-testing.instructions.md**: Pester testing guidelines

### 3. Task Prompts (`.github/prompts/`)

Reusable prompts for common development tasks:

- **Development prompts**: Module creation and enhancement
- **Operations prompts**: Maintenance, troubleshooting, CI/CD
- **Quality prompts**: Code review and testing

  - Module structure and testing guidelines.

  - Commit and documentation standards.

### `.github/instructions/`

- **Files**:

  - `powershell-testing.instructions.md`: Pester testing guidelines.

  - `patchmanager.instructions.md`: PatchManager module standards.

- **Purpose**: Provide module-specific and testing-specific instructions.

### `.github/prompts/`

- **Files**:

  - `create-powershell-module.prompt.md`: Prompts for PowerShell module creation.

  - `pester-testing.prompt.md`: Prompts for Pester test generation.

  - `patchmanager-development.prompt.md`: Prompts for PatchManager development.

- **Purpose**: Enhance Copilot's context-aware suggestions.

## Recommended Extensions

- **PowerShell**: `ms-vscode.powershell`

- **GitHub Copilot**: `github.copilot`, `github.copilot-chat`

- **Testing**: `pester.pester`

- **Infrastructure as Code**: `hashicorp.terraform`

## Development Workflow

1. **Setup Environment**:

   - Run the "Setup Development Environment" task.

   - Import all modules using the "Import All Modules" task.

2. **Follow Standards**:

   - Adhere to PowerShell 7.0+ cross-platform guidelines.

   - Use Copilot prompts for consistent code generation.

3. **Test Continuously**:

   - Execute "Run All Pester Tests" to validate changes.

   - Use "Generate Test Report" for detailed results.

4. **Debug Effectively**:

   - Utilize debug configurations in `launch.json`.

### 4. VS Code Configuration (`.vscode/`)

Workspace settings optimized for:

- GitHub Copilot integration
- PowerShell development
- Cross-platform compatibility
- Testing and debugging

## Configuration Details

### GitHub Copilot Settings

The workspace is configured with:

```json
{
  "github.copilot.enable": {
    "*": true,
    "powershell": true,
    "terraform": true,
    "json": true,
    "markdown": true
  },
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "github.copilot.instructionFiles": [
    // All instruction files are automatically included
  ],
  "github.copilot.chat.promptFiles": [
    // All prompt files are available for reuse
  ]
}
```

### Advanced Copilot Settings

Optimized parameters for PowerShell development:

```json
{
  "github.copilot.advanced": {
    "length": 3000,
    "temperature": 0.1,
    "top_p": 1,
    "stops": {
      "powershell": ["\n\n", "# End", "```"]
    }
  }
}
```

## Usage Guidelines

### For Developers

1. **Install Recommended Extensions**: Use the extensions.json recommendations
2. **Follow Instructions**: All code should adhere to the project instructions
3. **Use Prompts**: Leverage task-specific prompts for consistency
4. **Test Thoroughly**: Follow comprehensive testing guidelines

### For Maintainers

1. **Keep Instructions Current**: Update instructions as standards evolve
2. **Add New Prompts**: Create prompts for recurring tasks
3. **Monitor Quality**: Regularly review generated code quality
4. **Update Settings**: Optimize VS Code settings as needed

## Best Practices

### Instruction Management

- Keep instructions specific and actionable
- Avoid conflicting instructions across files
- Regular review and updates
- Clear examples and documentation

### Prompt Development

- Task-specific and focused prompts
- Clear requirements and expectations
- Reference instruction files for consistency
- Include validation and testing requirements

### Quality Assurance

- Regular validation of generated code
- Continuous improvement of instructions
- Monitoring of AI assistance effectiveness
- Feedback collection and implementation

## Troubleshooting

### Common Issues

1. **Conflicting Instructions**: Check for overlapping or contradictory guidelines
2. **Poor Code Quality**: Review and update instruction specificity
3. **Inconsistent Patterns**: Ensure prompt files reference common instructions
4. **Performance Issues**: Optimize instruction length and complexity

### Validation Steps

1. Test generated code against project standards
2. Validate cross-platform compatibility
3. Run comprehensive test suites
4. Review security and compliance adherence

## Maintenance

### Regular Tasks

1. **Monthly Review**: Check instruction relevance and accuracy
2. **Quarterly Updates**: Update for new tools and standards
3. **Annual Assessment**: Comprehensive review of entire setup
4. **Continuous Monitoring**: Track code quality and consistency

### Update Process

1. Identify areas for improvement
2. Update relevant instruction or prompt files
3. Test changes with representative scenarios
4. Document changes and communicate to team
5. Monitor impact and adjust as needed

This canonical setup ensures consistent, high-quality AI-assisted development while maintaining project standards and best practices.

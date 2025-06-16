# VS Code Configuration for OpenTofu Lab Automation

This directory contains comprehensive VS Code configuration files optimized for the OpenTofu Lab Automation project. The configuration provides an enhanced development experience with proper Copilot integration, debugging support, and project-specific settings.

## Files Overview

### Core Configuration Files

#### `.vscode/copilot-instructions.md`
Comprehensive instructions for GitHub Copilot that provide:
- Project context and architecture overview
- Coding standards and conventions specific to this project
- Module structure and key functions documentation
- Common patterns and examples for PowerShell, Python, and OpenTofu
- Security guidelines and best practices
- Testing requirements and frameworks

#### `.vscode/settings.json`
VS Code workspace settings including:
- **Copilot Configuration**: Enhanced code generation, test generation, and code review instructions
- **PowerShell Settings**: Cross-platform formatting, script analysis, and debugging
- **File Management**: Exclusions for backups, archives, and temporary files
- **Language-Specific Settings**: Terraform/OpenTofu, Python, JSON, YAML, Markdown
- **Editor Preferences**: Formatting, rulers, whitespace handling

#### `.vscode/tasks.json`
Pre-configured tasks for common operations:
- **Health Checks**: Quick and comprehensive health analysis
- **PatchManager Operations**: Direct commits, PR creation, rollbacks
- **Testing**: Pester tests, PSScriptAnalyzer, Python pytest
- **Development**: Module testing, environment initialization
- **OpenTofu**: Validation, planning, and infrastructure management

#### `.vscode/launch.json`
Debug configurations for:
- **PowerShell Debugging**: Current script, modules, Pester tests
- **Python Debugging**: Current file, CLI tools, test suites
- **Integrated Debugging**: Environment variable support and proper working directories

#### `.vscode/extensions.json`
Recommended extensions for optimal development experience:
- **Core Development**: PowerShell, Python, Git integration
- **Infrastructure**: Terraform/OpenTofu support
- **AI Assistance**: GitHub Copilot and Copilot Chat
- **Code Quality**: Linting, testing, error highlighting
- **Productivity**: Code runners, diagram tools, remote development

### Additional Files

#### `.vscode/snippets/powershell.json`
Custom code snippets for:
- Standard function templates following project conventions
- Module import patterns for cross-platform compatibility
- Error handling and logging patterns
- Pester test templates
- Common PowerShell patterns used throughout the project

#### `opentofu-lab-automation.code-workspace`
Multi-root workspace configuration that organizes the project into logical sections:
- Main project root
- PowerShell modules
- Core application
- Runner scripts
- OpenTofu configurations
- Python CLI
- Tests and documentation

## Key Features

### Enhanced Copilot Integration
- **Context-Aware Code Generation**: Copilot understands the project structure and generates code following project standards
- **Intelligent Test Generation**: Automated Pester and pytest test creation with proper setup/teardown
- **Code Review Assistance**: Automated code review focusing on PowerShell 7.0+ compatibility and project standards
- **Conventional Commits**: Automated commit message generation following project conventions

### Cross-Platform Development Support
- **PowerShell 7.0+ Standards**: All configurations enforce cross-platform PowerShell compatibility
- **Path Handling**: Proper forward slash usage and absolute path patterns
- **Environment Variables**: Consistent use of `$env:PROJECT_ROOT` and `$env:PWSH_MODULES_PATH`
- **Remote Development**: Support for SSH, containers, and GitHub Codespaces

### Comprehensive Testing Integration
- **Pester 5.0+ Support**: Full integration with Pester testing framework
- **Python Testing**: pytest integration with proper PYTHONPATH configuration
- **Script Analysis**: PSScriptAnalyzer integration with project-specific rules
- **Continuous Validation**: Automated testing tasks and debug configurations

### Project-Specific Optimizations
- **Module-Aware Navigation**: Quick access to PatchManager, LabRunner, and CoreApp modules
- **OpenTofu Integration**: Validation and planning tasks for infrastructure code
- **Backup/Archive Exclusions**: Performance optimized by excluding backup directories
- **Intelligent File Nesting**: Related files (tests, manifests) are nested appropriately

## Usage Examples

### Running Common Tasks
```bash
# Quick health check
Ctrl+Shift+P -> Tasks: Run Task -> Quick Health Check

# Run all tests
Ctrl+Shift+P -> Tasks: Run Task -> Run Pester Tests

# Apply changes with PatchManager
Ctrl+Shift+P -> Tasks: Run Task -> PatchManager: Apply Changes with PR
```

### Debugging
```bash
# Debug current PowerShell script
F5 (with PowerShell file open)

# Debug specific module
Ctrl+Shift+P -> Debug: Select and Start Debugging -> PowerShell: Debug PatchManager Module

# Debug Python CLI
Ctrl+Shift+P -> Debug: Select and Start Debugging -> Python: Debug Lab Control CLI
```

### Code Generation with Copilot
- **Function Creation**: Type `psfunction` and tab to get a complete function template
- **Module Import**: Type `psimport` and tab for proper module import syntax
- **Test Generation**: Use Copilot Chat to generate tests: "Generate Pester tests for this function"
- **Error Handling**: Type `pstrycatch` for comprehensive error handling patterns

## Customization

### Adding Custom Tasks
Edit `.vscode/tasks.json` to add project-specific tasks:
```json
{
    "label": "Your Custom Task",
    "type": "shell",
    "command": "pwsh",
    "args": ["-File", "./your-script.ps1"],
    "group": "build"
}
```

### Custom Snippets
Add snippets to `.vscode/snippets/powershell.json`:
```json
"Your Snippet Name": {
    "prefix": "yourprefix",
    "body": ["Your code template"],
    "description": "Description of your snippet"
}
```

### Environment-Specific Settings
Create `.vscode/settings.json` overrides for different environments:
```json
{
    "powershell.developer.powerShellExePath": "/usr/local/bin/pwsh",
    "terminal.integrated.defaultProfile.linux": "PowerShell"
}
```

## Troubleshooting

### Common Issues

#### PowerShell Extension Not Loading
1. Ensure PowerShell 7.0+ is installed and in PATH
2. Check `powershell.developer.powerShellExePath` setting
3. Restart VS Code and reload the PowerShell extension

#### Copilot Not Using Instructions
1. Verify `github.copilot.chat.codeGeneration.useInstructionFiles` is enabled
2. Check that `.vscode/copilot-instructions.md` exists and is readable
3. Restart Copilot service: Command Palette -> "GitHub Copilot: Restart Language Server"

#### Tasks Not Running
1. Ensure `pwsh` is available in PATH
2. Check working directory settings in task configuration
3. Verify required modules are available

#### Debug Configurations Not Working
1. Check that debug configurations match your installed extensions
2. Ensure PowerShell debugger extension is enabled
3. Verify file paths in launch.json are correct

### Performance Optimization
- **File Exclusions**: The configuration excludes backup and archive directories for better performance
- **Watcher Exclusions**: Git and node_modules directories are excluded from file watching
- **Search Optimization**: Search operations ignore irrelevant directories

## Integration with Project Workflows

This VS Code configuration integrates seamlessly with:
- **PatchManager Module**: Direct integration with patch management workflows
- **CI/CD Pipelines**: Tasks mirror GitHub Actions workflows
- **Testing Frameworks**: Pester and pytest integration with proper environment setup
- **Cross-Platform Development**: Consistent experience across Windows, Linux, and macOS

The configuration follows the project's emphasis on maintainability, cross-platform compatibility, and comprehensive testing while providing an enhanced development experience through intelligent tooling and automation.

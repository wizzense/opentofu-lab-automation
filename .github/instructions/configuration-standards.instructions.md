---
applyTo: "**/*.{yml,yaml,json}"
description: Configuration file standards and validation requirements
---

# Configuration Standards Instructions

## YAML Configuration Guidelines

Always follow these YAML formatting and structure standards:

### Formatting Rules
```yaml
# Use 2-space indentation consistently
name: "Configuration Name"
version: "1.0.0"

# Use quotes for string values with special characters
description: "OpenTofu lab automation configuration"

# Group related settings logically
modules:
  codefixer:
    enabled: true
    parallel_processing: true
    max_concurrency: 4
    
  labrunner:
    enabled: true
    logging_level: "INFO"
    cross_platform: true
```

### Required Metadata
Every configuration file should include:
```yaml
metadata:
  version: "1.0.0" 
  description: "Purpose and scope of this configuration"
  last_updated: "2025-06-14"
  maintainer: "OpenTofu Lab Automation Team"
```

### Validation Requirements
- All YAML files must pass yamllint validation
- Use schema validation where available
- Include comments for complex configurations
- Validate environment-specific settings

## JSON Configuration Standards

### Structure Requirements
```json
{
  "$schema": "https://json-schema.org/draft/schema-id",
  "metadata": {
    "version": "1.0.0",
    "description": "Configuration purpose"
  },
  "settings": {
    "key": "value"
  }
}
```

### Validation Patterns
```powershell
# Use CodeFixer for JSON validation
Test-JsonConfig -Path $ConfigFile -Schema $SchemaFile

# Validate structure
$config = Get-Content $ConfigFile | ConvertFrom-Json
if (-not $config.metadata) {
    throw "Missing required metadata section"
}
```

## Environment Configuration

### Cross-Platform Settings
```yaml
platforms:
  windows:
    shell: "pwsh"
    paths:
      modules: "C:\\Projects\\modules"
      
  linux:
    shell: "pwsh"
    paths:
      modules: "/opt/projects/modules"
      
  macos:
    shell: "pwsh"  
    paths:
      modules: "/usr/local/projects/modules"
```

### Module Configuration
```yaml
modules:
  paths:
    codefixer: "/pwsh/modules/CodeFixer/"
    labrunner: "/pwsh/modules/LabRunner/"
    
  settings:
    auto_import: true
    force_reload: true
    parallel_processing: true
```

## Security Configuration

### Secrets Management
```yaml
security:
  secrets:
    source: "environment"  # environment, keyvault, file
    required:
      - API_TOKEN
      - DATABASE_CONNECTION
      
  permissions:
    scripts: "755"
    configs: "644"
    secrets: "600"
```

### Access Control
```yaml
access:
  roles:
    developer:
      permissions: ["read", "execute"]
      paths: ["scripts/*", "configs/*"]
      
    maintainer:
      permissions: ["read", "write", "execute"]
      paths: ["**/*"]
```

## Validation Integration

### Automated Validation
```powershell
# In your configuration scripts
$ErrorActionPreference = "Stop"

# Validate YAML syntax
if (Get-Command yamllint -ErrorAction SilentlyContinue) {
    yamllint $ConfigFile
}

# Validate with CodeFixer
Import-Module "/pwsh/modules/CodeFixer/" -Force
Test-YamlConfig -Path $ConfigFile

# Custom validation
if (-not (Test-Path $config.modules.paths.labrunner)) {
    throw "LabRunner module path not found: $($config.modules.paths.labrunner)"
}
```

### Schema Validation
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["metadata", "modules"],
  "properties": {
    "metadata": {
      "type": "object",
      "required": ["version", "description"],
      "properties": {
        "version": {"type": "string"},
        "description": {"type": "string"}
      }
    },
    "modules": {
      "type": "object",
      "properties": {
        "codefixer": {"type": "object"},
        "labrunner": {"type": "object"}
      }
    }
  }
}
```

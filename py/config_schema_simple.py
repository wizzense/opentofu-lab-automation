#!/usr/bin/env python3
"""
Simplified Configuration Schema for OpenTofu Lab Automation
"""

import platform
from typing import Dict, Any, List, Optional

print("Loading configuration schema...")

class ConfigField:
    """Simple configuration field definition"""
    def __init__(self, name: str, display_name: str, field_type: str, default_value: Any, 
                 help_text: str, required: bool = False, choices: Optional[List[str]] = None,
                 category: str = "General"):
        self.name = name
        self.display_name = display_name
        self.field_type = field_type
        self.default_value = default_value
        self.help_text = help_text
        self.required = required
        self.choices = choices or []
        self.category = category

class ConfigSchema:
    """Configuration schema with organized sections"""
    
    def __init__(self):
        print("Initializing ConfigSchema...")
        self.sections = self._build_schema()
        print(f"ConfigSchema initialized with {len(self.sections)} sections")
    
    def _build_schema(self) -> Dict[str, List[ConfigField]]:
        """Build the configuration schema organized by sections"""
        
        # Platform-specific defaults
        is_windows = platform.system() == "Windows"
        default_temp = "C:\\Temp" if is_windows else "/tmp"
        
        return {
            "Repository Settings": [
                ConfigField(
                    name="RepoUrl",
                    display_name="Repository URL",
                    field_type="url",
                    default_value="https://github.com/wizzense/opentofu-lab-automation.git",
                    help_text="URL of the main lab automation repository.",
                    required=True
                ),
                ConfigField(
                    name="LocalPath", 
                    display_name="Local Deployment Path",
                    field_type="path",
                    default_value=f"{default_temp}/lab",
                    help_text="Local directory where the lab will be deployed.",
                    required=True
                ),
                ConfigField(
                    name="Verbosity",
                    display_name="Output Verbosity",
                    field_type="choice",
                    default_value="normal",
                    choices=["silent", "normal", "detailed"],
                    help_text="Control the amount of output during deployment."
                )
            ],
            
            "System Configuration": [
                ConfigField(
                    name="ComputerName",
                    display_name="Computer Name",
                    field_type="text",
                    default_value="lab-host",
                    help_text="Name to assign to the lab computer."
                ),
                ConfigField(
                    name="InstallGit",
                    display_name="Install Git",
                    field_type="bool",
                    default_value=True,
                    help_text="Install Git version control system."
                ),
                ConfigField(
                    name="InstallPwsh",
                    display_name="Install PowerShell 7+",
                    field_type="bool",
                    default_value=True,
                    help_text="Install PowerShell 7+ (cross-platform)."
                )
            ]
        }
    
    def get_field_by_name(self, name: str) -> Optional[ConfigField]:
        """Get a configuration field by name"""
        for section_fields in self.sections.values():
            for field in section_fields:
                if field.name == name:
                    return field
        return None
    
    def get_defaults(self) -> Dict[str, Any]:
        """Get dictionary of all default values"""
        defaults = {}
        for section_fields in self.sections.values():
            for field in section_fields:
                defaults[field.name] = field.default_value
        return defaults
    
    def validate_config(self, config: Dict[str, Any]) -> List[str]:
        """Validate configuration and return list of errors"""
        errors = []
        
        for section_fields in self.sections.values():
            for field in section_fields:
                if field.required and field.name not in config:
                    errors.append(f"Required field '{field.display_name}' is missing")
                
                if field.name in config:
                    value = config[field.name]
                    
                    # Validate choices
                    if field.choices and value not in field.choices:
                        errors.append(f"'{field.display_name}' must be one of: {', '.join(field.choices)}")
        
        return errors

print("ConfigSchema class defined successfully")

# Test the schema if run directly
if __name__ == "__main__":
    print("Testing ConfigSchema...")
    try:
        schema = ConfigSchema()
        print(f" Schema created with {len(schema.sections)} sections")
        
        defaults = schema.get_defaults()
        print(f" Got {len(defaults)} default values")
        
        # Test validation
        test_config = {"RepoUrl": "https://example.com", "LocalPath": "/tmp"}
        errors = schema.validate_config(test_config)
        print(f" Validation test: {len(errors)} errors")
        
        print(" ConfigSchema test completed successfully")
        
    except Exception as e:
        print(f" Error: {e}")
        import traceback
        traceback.print_exc()

print("Config schema module loaded successfully")

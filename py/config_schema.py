#!/usr/bin/env python3
"""
Configuration Schema for OpenTofu Lab Automation

Defines the complete configuration structure with help text, validation rules,
and recommended defaults for the lab automation system.
"""

from typing import Dict, Any, List, Optional, Union
from dataclasses import dataclass
import platform

@dataclass
class ConfigField:
    """Configuration field definition with metadata"""
    name: str
    display_name: str
    field_type: str  # 'text', 'bool', 'choice', 'path', 'url', 'number'
    default_value: Any
    help_text: str
    required: bool = False
    choices: OptionalListstr = None
    validation_pattern: Optionalstr = None
    category: str = "General"
    platform_specific: OptionalDictstr, Any = None

class ConfigSchema:
    """Complete configuration schema with organized sections"""
    
    def __init__(self):
        self.sections = self._build_schema()
    
    def _build_schema(self) -> Dictstr, ListConfigField:
        """Build the complete configuration schema organized by sections"""
        
        # Platform-specific defaults
        is_windows = platform.system() == "Windows"
        default_temp = "C:\\Temp" if is_windows else "/tmp"
        
        return {
            "Repository Settings": 
                ConfigField(
                    name="RepoUrl",
                    display_name="Repository URL",
                    field_type="url",
                    default_value="https://github.com/wizzense/opentofu-lab-automation.git",
                    help_text="URL of the main lab automation repository. This contains the PowerShell scripts and deployment tools.",
                    required=True
                ),
                ConfigField(
                    name="LocalPath", 
                    display_name="Local Deployment Path",
                    field_type="path",
                    default_value=f"{default_temp}\\lab" if is_windows else f"{default_temp}/lab",
                    help_text="Local directory where the lab will be deployed. Must be writable and have sufficient space (>2GB recommended).",
                    required=True
                ),
                ConfigField(
                    name="RunnerScriptName",
                    display_name="Runner Script",
                    field_type="text",
                    default_value="pwsh/runner.ps1",
                    help_text="Path to the main PowerShell runner script relative to the repository root."
                ),
                ConfigField(
                    name="InfraRepoUrl",
                    display_name="Infrastructure Repository",
                    field_type="url", 
                    default_value="https://github.com/wizzense/tofu-base-lab.git",
                    help_text="URL of the infrastructure code repository containing Terraform/OpenTofu configurations."
                ),
                ConfigField(
                    name="InfraRepoPath",
                    display_name="Infrastructure Path",
                    field_type="path",
                    default_value=f"{default_temp}\\base-infra" if is_windows else f"{default_temp}/base-infra",
                    help_text="Local path where infrastructure code will be cloned and managed."
                )
            ,
            
            "System Configuration": 
                ConfigField(
                    name="ComputerName",
                    display_name="Computer Name",
                    field_type="text",
                    default_value="lab-host",
                    help_text="Name to assign to the lab computer. Leave empty to keep current name."
                ),
                ConfigField(
                    name="SetComputerName",
                    display_name="Set Computer Name",
                    field_type="bool",
                    default_value=False,
                    help_text="Enable to change the computer name to the value specified above. Requires restart."
                ),
                ConfigField(
                    name="DNSServers",
                    display_name="DNS Servers",
                    field_type="text",
                    default_value="8.8.8.8,1.1.1.1",
                    help_text="Comma-separated list of DNS servers. Use public DNS (8.8.8.8,1.1.1.1) for reliable internet access."
                ),
                ConfigField(
                    name="SetDNSServers",
                    display_name="Configure DNS",
                    field_type="bool", 
                    default_value=False,
                    help_text="Enable to set custom DNS servers. Recommended for labs with custom domains or restricted internet."
                ),
                ConfigField(
                    name="Verbosity",
                    display_name="Output Verbosity",
                    field_type="choice",
                    default_value="normal",
                    choices="silent", "normal", "detailed",
                    help_text="Control the amount of output during deployment. 'detailed' shows all commands and outputs."
                )
            ,
            
            "Security & Remote Access": 
                ConfigField(
                    name="AllowRemoteDesktop",
                    display_name="Enable Remote Desktop",
                    field_type="bool",
                    default_value=False,
                    help_text="Enable Windows Remote Desktop Protocol (RDP) for remote GUI access. Only enable if needed.",
                    platform_specific={"windows": True}
                ),
                ConfigField(
                    name="ConfigureFirewall",
                    display_name="Configure Firewall",
                    field_type="bool",
                    default_value=False,
                    help_text="Automatically configure Windows Firewall rules for lab services. Disables some security protections."
                ),
                ConfigField(
                    name="TrustedHosts",
                    display_name="Trusted Hosts",
                    field_type="text",
                    default_value="",
                    help_text="PowerShell trusted hosts for WinRM connections. Use '*' for all hosts (less secure) or specific hostnames."
                ),
                ConfigField(
                    name="SetTrustedHosts",
                    display_name="Set Trusted Hosts",
                    field_type="bool",
                    default_value=False,
                    help_text="Enable to configure PowerShell trusted hosts for remote management."
                )
            ,
            
            "Development Tools": 
                ConfigField(
                    name="InstallGit",
                    display_name="Install Git",
                    field_type="bool",
                    default_value=True,
                    help_text="Install Git version control system. Required for cloning repositories and version control."
                ),
                ConfigField(
                    name="InstallGitHubCLI",
                    display_name="Install GitHub CLI",
                    field_type="bool",
                    default_value=True,
                    help_text="Install GitHub CLI (gh) for enhanced GitHub integration and authentication."
                ),
                ConfigField(
                    name="InstallPwsh",
                    display_name="Install PowerShell 7+",
                    field_type="bool",
                    default_value=True,
                    help_text="Install PowerShell 7+ (cross-platform). Strongly recommended for best compatibility."
                ),
                ConfigField(
                    name="InstallVSCode",
                    display_name="Install Visual Studio Code",
                    field_type="bool",
                    default_value=False,
                    help_text="Install VS Code editor with PowerShell and Terraform extensions."
                ),
                ConfigField(
                    name="InstallPython",
                    display_name="Install Python",
                    field_type="bool",
                    default_value=False,
                    help_text="Install Python runtime for additional scripting and automation tools."
                )
            ,
            
            "Infrastructure Tools": 
                ConfigField(
                    name="InstallOpenTofu",
                    display_name="Install OpenTofu",
                    field_type="bool",
                    default_value=False,
                    help_text="Install OpenTofu (open-source Terraform alternative) for infrastructure provisioning."
                ),
                ConfigField(
                    name="OpenTofuVersion",
                    display_name="OpenTofu Version",
                    field_type="text",
                    default_value="latest",
                    help_text="Specific OpenTofu version to install, or 'latest' for the newest stable release."
                ),
                ConfigField(
                    name="InitializeOpenTofu",
                    display_name="Initialize OpenTofu",
                    field_type="bool",
                    default_value=False,
                    help_text="Run 'tofu init' after installation to initialize the working directory."
                ),
                ConfigField(
                    name="InstallDockerDesktop",
                    display_name="Install Docker Desktop",
                    field_type="bool",
                    default_value=False,
                    help_text="Install Docker Desktop for containerized applications. Requires Windows Pro/Enterprise or WSL2."
                ),
                ConfigField(
                    name="InstallAzureCLI",
                    display_name="Install Azure CLI",
                    field_type="bool",
                    default_value=False,
                    help_text="Install Azure Command Line Interface for Azure cloud management."
                ),
                ConfigField(
                    name="InstallAWSCLI",
                    display_name="Install AWS CLI",
                    field_type="bool",
                    default_value=False,
                    help_text="Install Amazon Web Services Command Line Interface for AWS cloud management."
                )
            ,
            
            "Hyper-V Configuration": 
                ConfigField(
                    name="InstallHyperV",
                    display_name="Install Hyper-V",
                    field_type="bool",
                    default_value=False,
                    help_text="Install Hyper-V virtualization platform. Requires Windows Pro/Enterprise and hardware virtualization support.",
                    platform_specific={"windows": True}
                ),
                ConfigField(
                    name="PrepareHyperVHost",
                    display_name="Prepare Hyper-V Host",
                    field_type="bool",
                    default_value=False,
                    help_text="Configure the system as a Hyper-V host with optimal settings for virtualization."
                ),
                ConfigField(
                    name="InstallWAC",
                    display_name="Install Windows Admin Center",
                    field_type="bool",
                    default_value=False,
                    help_text="Install Windows Admin Center for web-based server management interface.",
                    platform_specific={"windows": True}
                )
            ,
            
            "Package Managers": 
                ConfigField(
                    name="InstallChocolatey",
                    display_name="Install Chocolatey",
                    field_type="bool",
                    default_value=False,
                    help_text="Install Chocolatey package manager for easy Windows software installation.",
                    platform_specific={"windows": True}
                ),
                ConfigField(
                    name="Install7Zip",
                    display_name="Install 7-Zip",
                    field_type="bool",
                    default_value=False,
                    help_text="Install 7-Zip archiving utility for handling compressed files."
                )
            ,
            
            "Advanced Settings": 
                ConfigField(
                    name="DisableTCPIP6",
                    display_name="Disable IPv6",
                    field_type="bool",
                    default_value=False,
                    help_text="Disable IPv6 protocol. Only enable if you have specific IPv4-only requirements."
                ),
                ConfigField(
                    name="ConfigPXE",
                    display_name="Configure PXE Boot",
                    field_type="bool",
                    default_value=False,
                    help_text="Configure Preboot Execution Environment for network booting. Advanced feature for imaging labs."
                ),
                ConfigField(
                    name="SetupLabProfile",
                    display_name="Setup Lab Profile",
                    field_type="bool",
                    default_value=False,
                    help_text="Create PowerShell profile with lab-specific aliases and functions."
                )
            
        }
    
    def get_field_by_name(self, name: str) -> OptionalConfigField:
        """Get a configuration field by name"""
        for section_fields in self.sections.values():
            for field in section_fields:
                if field.name == name:
                    return field
        return None
    
    def get_defaults(self) -> Dictstr, Any:
        """Get dictionary of all default values"""
        defaults = {}
        for section_fields in self.sections.values():
            for field in section_fields:
                # Apply platform-specific defaults if applicable
                if field.platform_specific and platform.system().lower() in field.platform_specific:
                    defaultsfield.name = field.platform_specificplatform.system().lower()
                else:
                    defaultsfield.name = field.default_value
        return defaults
    
    def validate_config(self, config: Dictstr, Any) -> Liststr:
        """Validate configuration and return list of errors"""
        errors = 
        
        for section_fields in self.sections.values():
            for field in section_fields:
                if field.required and field.name not in config:
                    errors.append(f"Required field '{field.display_name}' is missing")
                
                if field.name in config:
                    value = configfield.name
                    
                    # Validate choices
                    if field.choices and value not in field.choices:
                        errors.append(f"'{field.display_name}' must be one of: {', '.join(field.choices)}")
                    
                    # Validate types
                    if field.field_type == "bool" and not isinstance(value, bool):
                        errors.append(f"'{field.display_name}' must be true or false")
                    elif field.field_type == "number" and not isinstance(value, (int, float)):
                        errors.append(f"'{field.display_name}' must be a number")
        
        return errors

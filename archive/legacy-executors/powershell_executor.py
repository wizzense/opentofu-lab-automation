#!/usr/bin/env python3
"""
PowerShell Cross-Platform Executor Integration

Provides Python wrapper for CrossPlatformExecutor.ps1 to enable
reliable PowerShell script execution across platforms.
"""

import subprocess
import json
import base64
from pathlib import Path
from typing import Dict, Any, Optional

class PowerShellExecutor:
    """Cross-platform PowerShell script executor using base64 encoding"""
    
    def __init__(self, project_root: str = None):
        self.project_root = Path(project_root) if project_root else Path.cwd()
        self.executor_path = self.project_root / "pwsh" / "CrossPlatformExecutor.ps1"
        
        if not self.executor_path.exists():
            raise FileNotFoundError(f"CrossPlatformExecutor.ps1 not found at {self.executor_path}")
    
    def encode_script(self, script_path: str, parameters: Dict[str, Any] = None) -> str:
        """Encode a PowerShell script with parameters for cross-platform execution"""
        cmd = [
            "pwsh", "-File", str(self.executor_path),
            "-Action", "encode",
            "-ScriptPath", script_path,
            "-CI"
        ]
        
        if parameters:
            # Convert parameters to PowerShell hashtable format
            param_str = "@{" + "; ".join([f'"{k}"="{v}"' for k, v in parameters.items()]) + "}"
            cmd.extend(["-Parameters", param_str])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(f"Failed to encode script: {result.stderr}")
        
        data = json.loads(result.stdout)
        return data["EncodedScript"]
    
    def execute_encoded(self, encoded_script: str, whatif: bool = False) -> Dict[str, Any]:
        """Execute a base64-encoded PowerShell script"""
        cmd = [
            "pwsh", "-File", str(self.executor_path),
            "-Action", "execute",
            "-EncodedScript", encoded_script,
            "-CI"
        ]
        
        if whatif:
            cmd.append("-WhatIf")
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        try:
            return json.loads(result.stdout) if result.stdout else {"ExitCode": result.returncode}
        except json.JSONDecodeError:
            return {
                "ExitCode": result.returncode,
                "Output": result.stdout,
                "Error": result.stderr
            }
    
    def validate_encoded(self, encoded_script: str) -> Dict[str, Any]:
        """Validate a base64-encoded PowerShell script"""
        cmd = [
            "pwsh", "-File", str(self.executor_path),
            "-Action", "validate",
            "-EncodedScript", encoded_script,
            "-CI"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout) if result.stdout else {"Valid": False, "Error": result.stderr}
    
    def execute_script(self, script_path: str, parameters: Dict[str, Any] = None, whatif: bool = False) -> Dict[str, Any]:
        """One-shot: encode and execute a PowerShell script"""
        encoded = self.encode_script(script_path, parameters)
        return self.execute_encoded(encoded, whatif)

# Example usage functions
def demo_usage():
    """Demonstrate how to use the PowerShell executor"""
    executor = PowerShellExecutor()
    
    # Example 1: Execute runner script with custom config
    try:
        result = executor.execute_script(
            "pwsh/runner.ps1",
            parameters={
                "ConfigFile": "configs/config_files/default-config.json",
                "Auto": "true",
                "WhatIf": "true"
            },
            whatif=True
        )
        print(f"✅ Runner script executed: Exit code {result['ExitCode']}")
    except Exception as e:
        print(f"❌ Failed to execute runner: {e}")
    
    # Example 2: Validate a script before execution
    try:
        script_path = "pwsh/modules/LabRunner/Get-LabConfig.ps1"
        encoded = executor.encode_script(script_path)
        validation = executor.validate_encoded(encoded)
        
        if validation["Valid"]:
            print(f"✅ Script {script_path} is valid")
        else:
            print(f"❌ Script {script_path} has errors: {validation['Error']}")
    except Exception as e:
        print(f"❌ Validation failed: {e}")

if __name__ == "__main__":
    demo_usage()

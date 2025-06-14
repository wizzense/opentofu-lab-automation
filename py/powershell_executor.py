#!/usr/bin/env python3
"""
Consolidated PowerShell Executor with Cross-Platform Support

Merges functionality from enhanced_powershell_executor.py and powershell_executor.py
for robust PowerShell script execution with proper encoding, working directory 
management, and error handling.

Integrates with CrossPlatformExecutor.ps1 for maximum compatibility.
"""

import os
import sys
import subprocess
import platform
import tempfile
import base64
import json
from pathlib import Path
from typing import Optional, Dict, Any, Tuple

class PowerShellExecutor:
    """Consolidated PowerShell executor with cross-platform support"""
    
    def __init__(self, working_directory: Optional[str] = None, project_root: Optional[str] = None):
        self.working_directory = Path(working_directory) if working_directory else self.get_default_working_directory()
        self.project_root = Path(project_root) if project_root else Path.cwd()
        self.powershell_cmd = self.detect_powershell()
        self.executor_script = None
        self.setup_executor()
    
    def get_default_working_directory(self) -> Path:
        """Get default working directory based on platform"""
        if platform.system() == "Windows":
            work_dir = Path("C:/temp/opentofu-lab-automation")
        else:
            work_dir = Path("/tmp/opentofu-lab-automation")
        
        work_dir.mkdir(parents=True, exist_ok=True)
        return work_dir
    
    def detect_powershell(self) -> Optional[str]:
        """Detect available PowerShell executable"""
        candidates = ['pwsh', 'powershell'] if platform.system() == "Windows" else ['pwsh']
        
        for cmd in candidates:
            try:
                result = subprocess.run(
                    [cmd, '-NoProfile', '-NonInteractive', '-Command', '$PSVersionTable.PSVersion.Major'],
                    capture_output=True, text=True, timeout=10
                )
                if result.returncode == 0:
                    version = int(result.stdout.strip())
                    if version >= 5:  # Minimum required version
                        print(f"Found PowerShell {version}: {cmd}")
                        return cmd
            except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError, ValueError):
                continue
        
        return None
    
    def setup_executor(self):
        """Setup the CrossPlatformExecutor.ps1 script"""
        if not self.powershell_cmd:
            raise RuntimeError("PowerShell not found. Please install PowerShell 7+ or Windows PowerShell 5.1+")
        
        # Look for CrossPlatformExecutor.ps1 in project
        possible_locations = [
            self.working_directory / "pwsh" / "CrossPlatformExecutor.ps1",
            self.project_root / "pwsh" / "CrossPlatformExecutor.ps1",
            Path(__file__).parent.parent / "pwsh" / "CrossPlatformExecutor.ps1",
            Path.cwd() / "pwsh" / "CrossPlatformExecutor.ps1"
        ]
        
        for location in possible_locations:
            if location.exists():
                self.executor_script = location
                print(f"Found CrossPlatformExecutor.ps1: {location}")
                break
        
        if not self.executor_script:
            # Create a minimal executor if not found
            self.create_minimal_executor()
    
    def create_minimal_executor(self):
        """Create a minimal PowerShell executor script"""
        executor_content = '''
param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "execute",
    
    [Parameter(Mandatory=$false)]
    [string]$EncodedScript,
    
    [Parameter(Mandatory=$false)]
    [string]$WorkingDirectory,
    
    [Parameter(Mandatory=$false)]
    [switch]$NonInteractive
)

try {
    # Set working directory if provided
    if ($WorkingDirectory -and (Test-Path $WorkingDirectory)) {
        Set-Location $WorkingDirectory
        Write-Host "Changed to working directory: $WorkingDirectory"
    }
    
    # Decode and execute script
    if ($EncodedScript) {
        $decodedScript = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedScript))
        Write-Host "Executing decoded PowerShell script..."
        
        # Execute the script
        Invoke-Expression $decodedScript
        
        exit $LASTEXITCODE
    } else {
        Write-Error "No script provided"
        exit 1
    }
} catch {
    Write-Error "Execution failed: $_"
    exit 1
}
'''
        
        # Save to working directory
        executor_path = self.working_directory / "CrossPlatformExecutor.ps1"
        executor_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(executor_path, 'w', encoding='utf-8') as f:
            f.write(executor_content)
        
        self.executor_script = executor_path
        print(f"Created minimal PowerShell executor: {executor_path}")
    
    def encode_script(self, script_path: str, parameters: Optional[Dict[str, Any]] = None) -> str:
        """Encode a PowerShell script with parameters for cross-platform execution"""
        if not self.executor_script or not self.executor_script.exists():
            raise FileNotFoundError(f"CrossPlatformExecutor.ps1 not found at {self.executor_script}")
        
        cmd = [
            self.powershell_cmd, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
            "-File", str(self.executor_script),
            "-Action", "encode",
            "-ScriptPath", script_path
        ]
        
        if parameters:
            # Convert parameters to PowerShell hashtable format
            param_str = "@{" + "; ".join([f'"{k}"="{v}"' for k, v in parameters.items()]) + "}"
            cmd.extend(["-Parameters", param_str])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            if result.returncode != 0:
                raise RuntimeError(f"Failed to encode script: {result.stderr}")
            
            # Extract encoded script from output
            lines = result.stdout.strip().split('\n')
            for i, line in enumerate(lines):
                if "=== ENCODED SCRIPT ===" in line and i + 1 < len(lines):
                    return lines[i + 1].strip()
            
            # Fallback: try to parse as JSON
            try:
                data = json.loads(result.stdout)
                return data["EncodedScript"]
            except json.JSONDecodeError:
                # Extract base64 from output
                for line in lines:
                    if len(line.strip()) > 100 and line.strip().replace('=', '').replace('+', '').replace('/', '').isalnum():
                        return line.strip()
                
                raise RuntimeError("Could not extract encoded script from output")
                
        except subprocess.TimeoutExpired:
            raise RuntimeError("Script encoding timed out")
    
    def execute_script(self, script_content: str, parameters: Optional[Dict[str, Any]] = None) -> Tuple[bool, str, str]:
        """
        Execute PowerShell script with proper encoding and error handling
        
        Returns:
            Tuple of (success: bool, stdout: str, stderr: str)
        """
        if not self.executor_script or not self.executor_script.exists():
            return False, "", f"CrossPlatformExecutor.ps1 not found at {self.executor_script}"
        
        try:
            # Encode script as base64 for safe transport
            encoded_script = base64.b64encode(script_content.encode('utf-8')).decode('ascii')
              # Build command
            cmd = [
                self.powershell_cmd,
                '-NoProfile',
                '-NonInteractive',
                '-ExecutionPolicy', 'Bypass',
                '-File', str(self.executor_script),
                '-Action', 'execute',
                '-EncodedScript', encoded_script
            ]
            
            # Add working directory parameter if the script supports it
            if self.executor_script.name != "CrossPlatformExecutor.ps1" or "WorkingDirectory" in self.executor_script.read_text():
                cmd.extend(['-WorkingDirectory', str(self.working_directory)])
            
            # Add non-interactive parameter if supported
            if "NonInteractive" in self.executor_script.read_text():
                cmd.append('-NonInteractive')
            
            # Set up environment
            env = os.environ.copy()
            env['PYTHONIOENCODING'] = 'utf-8'
            
            if platform.system() == "Windows":
                # Force UTF-8 on Windows
                env['PYTHONUTF8'] = '1'
            
            result = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                timeout=300,
                env=env,
                cwd=str(self.working_directory)
            )
            
            return result.returncode == 0, result.stdout, result.stderr
            
        except subprocess.TimeoutExpired:
            return False, "", "Script execution timed out (300s)"
        except Exception as e:
            return False, "", f"Execution error: {str(e)}"
    
    def execute_file(self, script_path: str, parameters: Optional[Dict[str, Any]] = None) -> Tuple[bool, str, str]:
        """Execute PowerShell script file"""
        script_file = Path(script_path)
        
        if not script_file.exists():
            return False, "", f"Script file not found: {script_path}"
        
        try:
            script_content = script_file.read_text(encoding='utf-8')
            
            # Add parameter assignments if provided
            if parameters:
                param_script = self.build_parameter_script(parameters)
                script_content = f"{param_script}\n\n{script_content}"
            
            return self.execute_script(script_content, parameters)
            
        except Exception as e:
            return False, "", f"Failed to read script file: {str(e)}"
    
    def execute_encoded(self, encoded_script: str, whatif: bool = False) -> Dict[str, Any]:
        """Execute a base64-encoded PowerShell script"""
        cmd = [
            self.powershell_cmd, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
            "-File", str(self.executor_script),
            "-Action", "execute",
            "-EncodedScript", encoded_script
        ]
        
        if whatif:
            cmd.append("-WhatIf")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            try:
                return json.loads(result.stdout) if result.stdout else {"ExitCode": result.returncode}
            except json.JSONDecodeError:
                return {
                    "ExitCode": result.returncode,
                    "Output": result.stdout,
                    "Error": result.stderr
                }
        except subprocess.TimeoutExpired:
            return {"ExitCode": -1, "Error": "Execution timed out"}
    
    def validate_encoded(self, encoded_script: str) -> Dict[str, Any]:
        """Validate a base64-encoded PowerShell script"""
        cmd = [
            self.powershell_cmd, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
            "-File", str(self.executor_script),
            "-Action", "validate",
            "-EncodedScript", encoded_script
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            try:
                return json.loads(result.stdout) if result.stdout else {"Valid": False, "Error": result.stderr}
            except json.JSONDecodeError:
                return {"Valid": result.returncode == 0, "Output": result.stdout, "Error": result.stderr}
        except subprocess.TimeoutExpired:
            return {"Valid": False, "Error": "Validation timed out"}
    
    def build_parameter_script(self, parameters: Dict[str, Any]) -> str:
        """Build PowerShell parameter assignment script"""
        param_lines = []
        
        for key, value in parameters.items():
            if isinstance(value, str):
                param_lines.append(f'${key} = "{value}"')
            elif isinstance(value, bool):
                param_lines.append(f'${key} = ${str(value).lower()}')
            elif isinstance(value, (int, float)):
                param_lines.append(f'${key} = {value}')
            else:
                param_lines.append(f'${key} = "{str(value)}"')
        
        return "\n".join(param_lines)
    
    def test_execution(self) -> bool:
        """Test PowerShell execution with a simple script"""
        test_script = '''
Write-Host "PowerShell execution test successful"
Write-Host "Working Directory: $(Get-Location)"
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
if ($PSVersionTable.Platform) {
    Write-Host "Platform: $($PSVersionTable.Platform)"
} else {
    Write-Host "Platform: Windows (Legacy PowerShell)"
}
'''
        
        success, stdout, stderr = self.execute_script(test_script)
        
        if success:
            print("✓ PowerShell execution test passed")
            print(f"Output: {stdout}")
            return True
        else:
            print("✗ PowerShell execution test failed")
            print(f"Error: {stderr}")
            return False
    
    def get_system_info(self) -> Dict[str, Any]:
        """Get system information via PowerShell"""
        info_script = '''
$info = @{
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Platform = if ($PSVersionTable.Platform) { $PSVersionTable.Platform } else { "Windows" }
    OS = if ($PSVersionTable.OS) { $PSVersionTable.OS } else { "Windows" }
    WorkingDirectory = (Get-Location).Path
    TempDirectory = if ($env:TEMP) { $env:TEMP } else { "/tmp" }
    UserName = if ($env:USERNAME) { $env:USERNAME } else { $env:USER }
    ComputerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { $env:HOSTNAME }
}

$info | ConvertTo-Json -Depth 2
'''
        
        success, stdout, stderr = self.execute_script(info_script)
        
        if success:
            try:
                return json.loads(stdout)
            except json.JSONDecodeError:
                return {"error": "Failed to parse system info JSON", "raw_output": stdout}
        else:
            return {"error": f"Failed to get system info: {stderr}"}


def main():
    """Test the consolidated PowerShell executor"""
    print("Testing Consolidated PowerShell Executor...")
    
    try:
        executor = PowerShellExecutor()
        print(f"✓ Executor initialized")
        print(f"  PowerShell Command: {executor.powershell_cmd}")
        print(f"  Working Directory: {executor.working_directory}")
        print(f"  Executor Script: {executor.executor_script}")
        
        # Test execution
        if executor.test_execution():
            print("✓ Basic execution test passed")
        else:
            print("✗ Basic execution test failed")
            return 1
        
        # Get system info
        print("\nSystem Information:")
        system_info = executor.get_system_info()
        for key, value in system_info.items():
            print(f"  {key}: {value}")
        
        print("\n✓ Consolidated PowerShell Executor is working correctly")
        return 0
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
Enhanced PowerShell Executor with Cross-Platform Support

Integrates with CrossPlatformExecutor.ps1 for robust PowerShell script execution
with proper encoding, working directory management, and error handling.
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

class EnhancedPowerShellExecutor:
    """Enhanced PowerShell executor with cross-platform support"""
    
    def __init__(self, working_directory: Optionalstr = None):
        self.working_directory = Path(working_directory) if working_directory else self.get_default_working_directory()
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
    
    def detect_powershell(self) -> Optionalstr:
        """Detect available PowerShell executable"""
        candidates = 'pwsh', 'powershell' if platform.system() == "Windows" else 'pwsh'
        
        for cmd in candidates:
            try:
                result = subprocess.run(
                    cmd, '-NoProfile', '-NonInteractive', '-Command', '$PSVersionTable.PSVersion.Major',
                    capture_output=True, text=True, timeout=10
                )
                if result.returncode == 0:
                    version = int(result.stdout.strip())
                    if version >= 5:  # Minimum required version
                        return cmd
            except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError, ValueError):
                continue
        
        return None
    
    def setup_executor(self):
        """Setup the CrossPlatformExecutor.ps1 script"""
        if not self.powershell_cmd:
            raise RuntimeError("PowerShell not found. Please install PowerShell 7+ or Windows PowerShell 5.1+")
        
        # Look for CrossPlatformExecutor.ps1 in project
        possible_locations = 
            self.working_directory / "pwsh" / "CrossPlatformExecutor_Enhanced.ps1",
            self.working_directory / "pwsh" / "CrossPlatformExecutor.ps1",
            Path(__file__).parent.parent / "pwsh" / "CrossPlatformExecutor_Enhanced.ps1",
            Path(__file__).parent.parent / "pwsh" / "CrossPlatformExecutor.ps1",
            Path.cwd() / "pwsh" / "CrossPlatformExecutor_Enhanced.ps1",
            Path.cwd() / "pwsh" / "CrossPlatformExecutor.ps1"
        
        
        for location in possible_locations:
            if location.exists():
                self.executor_script = location
                print(f"Found PowerShell executor: {location}")
                break
        
        if not self.executor_script:
            # Create a minimal executor if not found
            self.create_minimal_executor()
    
    def create_minimal_executor(self):
        """Create a minimal PowerShell executor script"""
        executor_content = '''
param(
    Parameter(Mandatory=$false)
    string$EncodedScript,
    
    Parameter(Mandatory=$false)
    string$WorkingDirectory,
    
    Parameter(Mandatory=$false)
    switch$NonInteractive
)

try {
    # Set working directory if provided
    if ($WorkingDirectory -and (Test-Path $WorkingDirectory)) {
        Set-Location $WorkingDirectory
        Write-Host "Changed to working directory: $WorkingDirectory"
    }
    
    # Decode and execute script
    if ($EncodedScript) {
        $decodedScript = System.Text.Encoding::UTF8.GetString(System.Convert::FromBase64String($EncodedScript))
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
    
    def execute_script(self, script_content: str, parameters: OptionalDictstr, Any = None) -> Tuplebool, str, str:
        """
        Execute PowerShell script with proper encoding and error handling
        
        Returns:
            Tuple of (success: bool, stdout: str, stderr: str)
        """
        if not self.executor_script or not self.executor_script.exists():
            return False, "", "PowerShell executor script not found"
        
        try:
            # Encode script as base64 for safe transport
            encoded_script = base64.b64encode(script_content.encode('utf-8')).decode('ascii')
            
            # Build command
            cmd = 
                self.powershell_cmd,
                '-NoProfile',
                '-NonInteractive',
                '-ExecutionPolicy', 'Bypass',
                '-File', str(self.executor_script),
                '-EncodedScript', encoded_script,
                '-WorkingDirectory', str(self.working_directory),
                '-NonInteractive'
            
            
            # Set up environment
            env = os.environ.copy()
            env'PYTHONIOENCODING' = 'utf-8'
            
            if platform.system() == "Windows":
                env'TEMP' = str(self.working_directory / 'temp')
                env'TMP' = str(self.working_directory / 'temp')
                (self.working_directory / 'temp').mkdir(exist_ok=True)
            
            # Execute with timeout
            result = subprocess.run(
                cmd,
                cwd=str(self.working_directory),
                env=env,
                capture_output=True,
                text=True,
                encoding='utf-8',
                errors='replace',
                timeout=1800  # 30 minute timeout
            )
            
            success = result.returncode == 0
            return success, result.stdout, result.stderr
            
        except subprocess.TimeoutExpired:
            return False, "", "Script execution timed out after 30 minutes"
        except Exception as e:
            return False, "", f"Execution error: {str(e)}"
    
    def execute_file(self, script_path: str, parameters: OptionalDictstr, Any = None) -> Tuplebool, str, str:
        """Execute PowerShell script file"""
        script_file = Path(script_path)
        
        if not script_file.exists():
            return False, "", f"Script file not found: {script_path}"
        
        try:
            with open(script_file, 'r', encoding='utf-8') as f:
                script_content = f.read()
            
            # Add parameter handling if needed
            if parameters:
                param_script = self.build_parameter_script(parameters)
                script_content = param_script + "\n" + script_content
            
            return self.execute_script(script_content, parameters)
            
        except Exception as e:
            return False, "", f"Error reading script file: {str(e)}"
    
    def build_parameter_script(self, parameters: Dictstr, Any) -> str:
        """Build PowerShell parameter assignment script"""
        param_lines = 
        
        for key, value in parameters.items():
            if isinstance(value, bool):
                param_lines.append(f"${key} = ${str(value).lower()}")
            elif isinstance(value, str):
                # Escape quotes and special characters
                escaped_value = value.replace("'", "''")
                param_lines.append(f"${key} = '{escaped_value}'")
            elif isinstance(value, (int, float)):
                param_lines.append(f"${key} = {value}")
            else:
                # Convert to JSON for complex objects
                json_value = json.dumps(value).replace('"', '""')
                param_lines.append(f"${key} = ConvertFrom-Json '{json_value}'")
        
        return "\n".join(param_lines)
    
    def test_execution(self) -> bool:
        """Test PowerShell execution with a simple script"""
        test_script = '''
Write-Host "PowerShell execution test successful"
Write-Host "Working Directory: $(Get-Location)"
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Host "Platform: $($PSVersionTable.Platform)"
'''
        
        success, stdout, stderr = self.execute_script(test_script)
        
        if success:
            print(" PowerShell execution test passed")
            print(f"Output: {stdout.strip()}")
            return True
        else:
            print(" PowerShell execution test failed")
            print(f"Error: {stderr}")
            return False
    
    def get_system_info(self) -> Dictstr, Any:
        """Get system information via PowerShell"""
        info_script = '''
$info = @{
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Platform = $PSVersionTable.Platform
    OS = $PSVersionTable.OS
    WorkingDirectory = (Get-Location).Path
    TempDirectory = $env:TEMP
    UserName = $env:USERNAME
    ComputerName = $env:COMPUTERNAME
}

$info  ConvertTo-Json -Depth 2
'''
        
        success, stdout, stderr = self.execute_script(info_script)
        
        if success:
            try:
                return json.loads(stdout.strip())
            except json.JSONDecodeError:
                return {"raw_output": stdout, "error": "Failed to parse JSON"}
        else:
            return {"error": stderr}

def main():
    """Test the enhanced PowerShell executor"""
    print("Testing Enhanced PowerShell Executor...")
    
    try:
        executor = EnhancedPowerShellExecutor()
        print(f" Executor initialized")
        print(f"  PowerShell Command: {executor.powershell_cmd}")
        print(f"  Working Directory: {executor.working_directory}")
        print(f"  Executor Script: {executor.executor_script}")
        
        # Test execution
        if executor.test_execution():
            print("\n Basic execution test passed")
        else:
            print("\n Basic execution test failed")
            return 1
        
        # Get system info
        print("\nSystem Information:")
        system_info = executor.get_system_info()
        for key, value in system_info.items():
            print(f"  {key}: {value}")
        
        print("\n Enhanced PowerShell Executor is working correctly")
        return 0
        
    except Exception as e:
        print(f"\n Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

# Pester Test Failures (Tracked)

This file tracks current Pester test failures for the OpenTofu Lab Automation project. Each entry includes the test file, test name, and error message. As errors are resolved, they should be checked off or removed.

---

## Outstanding Errors

### 1. /tests/Get-WindowsJobArtifacts.Tests.ps1
- **Error:** Unexpected token '}' in expression or statement. (ParseException)
- **Line:** 102

### 2. /tests/examples/Install-Go.Modern.Tests.ps1
- **Error:** The Export-ModuleMember cmdlet can only be called from inside a module. (InvalidOperationException)
- **File:** helpers/TestTemplates.ps1, line 346

### 3. /tests/0000_Cleanup-Files.Tests.ps1
- **Error:** Script file not found: '/workspaces/opentofu-lab-automation/pwsh/runner_scripts/0000_Cleanup-Files.ps1'
- **Error:** Exception: The term ... is not recognized as a name of a cmdlet, function, script file, or executable program.

### 4. /tests/0001_Reset-Git.Tests.ps1
- **Error:** Script file not found: '/workspaces/opentofu-lab-automation/pwsh/runner_scripts/0001_Reset-Git.ps1'
- **Error:** Exception: The term ... is not recognized as a name of a cmdlet, function, script file, or executable program.

### 5. /tests/0002_Setup-Directories.Tests.ps1
- **Error:** Script file not found: '/workspaces/opentofu-lab-automation/pwsh/runner_scripts/0002_Setup-Directories.ps1'
- **Error:** Exception: The term ... is not recognized as a name of a cmdlet, function, script file, or executable program.

### 6. /tests/0101_Enable-RemoteDesktop.Tests.ps1
- **Error:** Script file not found: '/workspaces/opentofu-lab-automation/pwsh/runner_scripts/0101_Enable-RemoteDesktop.ps1'
- **Error:** Exception: The term ... is not recognized as a name of a cmdlet, function, script file, or executable program.

### 7. /tests/0102_Configure-Firewall.Tests.ps1
- **Error:** Script file not found: '/workspaces/opentofu-lab-automation/pwsh/runner_scripts/0102_Configure-Firewall.ps1'
- **Error:** Exception: The term ... is not recognized as a name of a cmdlet, function, script file, or executable program.

---

(See full XML for additional details or new errors.)


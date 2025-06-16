# OpenTofu Lab Automation Quickstart

## Prerequisites
- PowerShell 7.4 or higher.
- Git installed and configured.
- Access to the OpenTofu Lab Automation repository.

## Setup
1. Clone the repository:
   ```powershell
   git clone https://github.com/wizzense/opentofu-lab-automation.git
   ```

2. Navigate to the project directory:
   ```powershell
   cd opentofu-lab-automation
   ```

3. Run the bootstrap script:
   ```powershell
   ./pwsh/kicker-bootstrap.ps1
   ```

## Usage
### Running Maintenance
Run a quick health check:
```powershell
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
```

### Validating Changes
Validate PowerShell scripts:
```powershell
Invoke-PowerShellLint -Path "./scripts/" -Parallel
```

### Creating a Patch
Use PatchManager to create a patch:
```powershell
Invoke-GitControlledPatch -PatchDescription "feat: new feature" -PatchOperation {
    # Your changes here
} -AutoCommitUncommitted -CreatePullRequest
```

## Additional Resources
- Refer to `AGENTS.md` for module details.
- Check `docs/roadmap/IMPLEMENTATION-ROADMAP.md` for project goals.

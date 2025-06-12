# Lab Utility Scripts

This folder contains helper tools used across the project. Each script focuses on a small task so they can be composed in other workflows.

- **Expand-All.ps1** – Expands a specified ZIP archive or every archive in the current directory tree.
- **Format-Config.ps1** – Converts a configuration object into pretty JSON for easier logging.
- **Get-LabConfig.ps1** – Loads a JSON or YAML file and returns it as a PowerShell object.
- **Get-Platform.ps1** – Detects the host operating system.
- **Menu.ps1** – Provides an interactive menu for selecting items from a list.
- **Hypervisor.psm1** – Stub module defining `Get-HVFacts`, `Enable-Provider` and `Deploy-VM` functions.
- **get_platform.py** – Python version of `Get-Platform.ps1`.
- **Get-WindowsJobArtifacts.ps1** – Downloads the latest Windows job artifacts from GitHub and shows failing tests. Use `gh run list` to grab a run ID and call the script with `-RunId <id>` if automatic discovery fails. Run IDs are 64‑bit integers, so quote them if needed. The script falls back to nightly.link URLs when unauthenticated and gracefully skips the coverage archive when tests fail.

The `__init__.py` file is currently empty and simply marks the folder as a Python package.

---

See [pester-test-failures.md](pester-test-failures.md) for a tracked list of current test failures.

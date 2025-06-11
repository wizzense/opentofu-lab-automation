# Windows Test Failures

The following table lists failing tests collected from `coverage/testResults.xml` along with their error messages. When a test workflow fails, `.github/workflows/issue-on-fail.yml` downloads the `pester-results-*` or `pytest-results-*` artifacts and runs `python -m labctl.pester_failures` or `python -m labctl.pytest_failures` to open GitHub issues for each failing test. The matching log (`coverage/pester.log`) only contained `gh: Not Found (HTTP 404)`.

| Test Name | Error Message |
|-----------|--------------|
| Format-Config.is a terminating error when Config is null | ParameterBindingException: The input object cannot be bound to any parameters for the command either because the command does not take pipeline input or the input and its properties do not match any of the parameters that take pipeline input. |
| Format-Config.is a terminating error when piped null | ParameterBindingException: The input object cannot be bound to any parameters for the command either because the command does not take pipeline input or the input and its properties do not match any of the parameters that take pipeline input. |
| runner.ps1 executing 0200_Get-SystemInfo.outputs system info when run via runner | Expected regular expression 'ComputerName' to match <empty>, but it did not match. |
| Get-WindowsJobArtifacts.uses gh CLI when authenticated | Expected gh.exe to be called at least 1 times, but was called 0 times |
| Get-WindowsJobArtifacts.falls back to nightly.link when gh auth fails | Expected Invoke-WebRequest to be called at least 1 times, but was called 0 times |
| Get-WindowsJobArtifacts.uses provided run ID with gh | Expected gh.exe to be called at least 1 times, but was called 0 times |
| 0104_Install-CA script.invokes CA installation when InstallCA is true | Expected Install-AdcsCertificationAuthority to be called at least 1 times, but was called 0 times |
| Prepare-HyperVProvider path restoration.restores location after execution | ParameterBindingValidationException: Cannot bind argument to parameter 'Path' because it is null. |
| Prepare-HyperVProvider certificate handling.creates PEM files and updates providers.tf | ParameterBindingValidationException: Cannot bind argument to parameter 'Path' because it is null. |
| Convert certificate helpers validate paths.errors when PfxPath, CertPath, or KeyPath is missing | Expected an exception with message like 'Convert-PfxToPem: PfxPath is required' to be thrown, but no exception was thrown. |
| runner.ps1 script selection.forces script execution when flag disabled using -Force | Expected $true, but got $false. |
| runner.ps1 script selection.suppresses informational logs when -Verbosity silent is used | ParameterBindingException: Parameter set cannot be resolved using the specified named parameters. One or more parameters issued cannot be used together or an insufficient number of parameters were provided. |
| runner.ps1 script selection.suppresses informational logs when -Verbosity silent is used | ParameterBindingException: Parameter set cannot be resolved using the specified named parameters. One or more parameters issued cannot be used together or an insufficient number of parameters were provided. |
| runner.ps1 script selection.prompts twice when -Auto is used without -Scripts | Expected Get-MenuSelection to be called at least 2 times, but was called 1 times |
| runner.ps1 script selection.logs script output exactly once | Expected 1, but got 0. |

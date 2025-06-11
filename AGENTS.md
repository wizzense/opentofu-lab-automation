# Agents Roadmap

## Project Status

* **Phase 0 – House‑Keeping (✅ complete, June 2025)**
  `Get-Platform.ps1` is now fully covered by Pester tests.

* **Phase 1 – Cross‑Platform Foundations (🟡 in progress)**

  * `get_platform.py` with pytest suite.
  * Typer‑based CLI scaffold (`labctl`) under `py/`.
  * Hypervisor PowerShell module skeleton available.
  * **Next:** Finish cross‑platform provider implementations.

---

## Phase 0 – House‑Keeping (1 day)

| Task                              | Details                                                                                                                                                                                   |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ~~0.1 Stabilise `runner.ps1`~~    | • Added `-Scripts` (string) & `-Auto` (switch) parameters.<br>• Defaults to interactive mode.<br>• Exits non‑zero on child failures.<br>**Prompt:** “Refactor `runner.ps1` so it takes …” |
| ~~0.2 Unify config‑file loading~~ | • New `lab_utils/Get-LabConfig.ps1` returning a `[pscustomobject]`.<br>• Handles missing file & invalid JSON.<br>**Prompt:** “Create `lab_utils/Get‑LabConfig.ps1` …”                     |
| ~~0.3 CI hygiene~~                | • Composite action `.github/actions/lint` runs `Invoke‑ScriptAnalyzer` and `ruff`.<br>• `lint` → `pester` gates `main`.<br>**Prompt:** “Add a composite action …”                         |

---

## Phase 1 – Cross‑Platform Foundations (3 days)

| Task                                    | Details                                                                                                                 |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| ~~1.1 Platform detector~~               | `lab_utils/Get‑Platform.ps1` and `get_platform.py` return `Windows`, `Linux`, or `macOS` with shared tests.             |
| ~~1.2 Hypervisor abstraction skeleton~~ | `lab_utils/Hypervisor.psm1` exposes `Get‑HVFacts`, `Enable‑Provider`, and `Deploy‑VM` with stub Hyper‑V implementation. |
| ~~1.3 Python scaffold~~                 | Poetry project under `py/`; Typer CLI `labctl` (`hv facts`, `hv deploy`) shares JSON config; pytest wired.              |

**Remaining work**

* Flesh out provider‑specific classes in both PowerShell and Python.
* Map shared config schema across languages.
* Useful `labctl` subcommands:
  * `labctl hv facts` – display hypervisor configuration details.
  * `labctl hv deploy` – deploy a host or VM using the config.
  * `labctl repo cleanup` – remove merged branches from the remote.
  * `labctl ui` – launch the Textual user interface.

See `py/README.md` for detailed instructions on installing and running the CLI.

---

## Phase 2 – Additional Hypervisors (10 days)

| Task                          | Details                                                                                                   |
| ----------------------------- | --------------------------------------------------------------------------------------------------------- |
| 2.1 VMware Workstation / ESXi | Extend `Hypervisor` modules with VMware provider via `govc`; add `Install‑Govc.ps1`; update tests & docs. |
| 2.2 Proxmox / libvirt / KVM   | Implement Proxmox provider via REST API; Typer sub‑command; pytest with `responses`.                      |

---

## Phase 3 – Cloud Targets (8 days)

| Task      | Details                                                                                 |
| --------- | --------------------------------------------------------------------------------------- |
| 3.1 Azure | Create OpenTofu module (`cloud/azure`) for vNet, subnet, VMSS; validate with `azurite`. |
| 3.2 AWS   | Mirror Azure module for EC2; include Tfsec & Checkov baselines.                         |

---

## Phase 4 – Secrets & Security (2 days)

| Task                                  | Details                                                                                                                   |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| 4.1 Secrets back‑ends                 | `lab_utils/Get‑Secret.ps1` (+ Python twin) resolves IDs from KeyVault/SecretsManager, falling back to env vars.           |
| 4.2 Hyper‑V provider certificate flow | Finalise cert handling in `Prepare‑HyperVProvider.ps1` – convert PFX→PEM, inject into OpenTofu, remove `insecure = true`. |

---

## Phase 5 – User‑Facing Improvements (ongoing)

| Task                              | Details                                                                          |
| --------------------------------- | -------------------------------------------------------------------------------- |
| 5.1 Interactive TUI (`labctl ui`) | Build Textual‑based selector that consumes JSON config and invokes scripts.      |
| 5.2 Docs site                     | MkDocs‑Material docs with autogenerated API references; deploy via GitHub Pages. |

---

## Contribution Guidelines

1. **Tests**
   • PowerShell: `Invoke‑Pester`
   • Python: `pytest`
   • *Shortcut:* `task test` (InvokeBuild) runs the same CI command.

2. **Coverage**
   • Add or update Pester/pytest tests for every functional change, covering success and failure paths.

### Pester test tips

* Import helper scripts at the top of each test file:
  ```powershell
  . (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
  . (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
  ```
* Dot-source scripts or modules under test in a `BeforeAll` block using
  `(Join-Path $PSScriptRoot ..)` to build the path.  This keeps paths
  consistent and avoids module import issues.
* Use `$script:` scope for variables that need to be shared between `BeforeAll`,
  `BeforeEach` and individual `It` blocks.
* Remove mocked functions in `AfterEach` with
  `Remove-Item Function:<Name> -ErrorAction SilentlyContinue` to prevent
  cross‑test pollution.
* Reset any environment variables or modules changed by the test inside
  `AfterEach`.
* Use `Get-RunnerScriptPath` from `tests/helpers/TestHelpers.ps1` to resolve
  paths to scripts under `runner_scripts`.
* Guard Windows‑only tests with `if ($SkipNonWindows) { return }` or
  `-Skip:($SkipNonWindows)`.

* Use `$SkipNonWindows` only for tests that rely on Windows-specific functionality (e.g., the registry). Tests that simply use mocks or platform-neutral cmdlets should run on all operating systems.
* CI runs Pester on Windows, Linux, and macOS, so avoid skipping cross-platform tests as it reduces coverage.


3. **Style**
   • PowerShell: `Invoke‑ScriptAnalyzer`
   • Python: `ruff .`

4. **Documentation**
   • Doc‑only changes live under `docs/` and must build with `mkdocs build`.

5. **CI**
   • GitHub Actions: `lint` → `test` gate `main`.
   • `.github/workflows/issue-on-fail.yml` opens an issue on CI failure; include log excerpts when debugging.
# Windows Artifact Review & Remediation Workflow

> **Audience:** Continuous‑integration maintainers & contributors responsible for keeping the Windows test matrix green.

---

## Overview

This guide explains how to pull the latest Windows job artifacts, analyse test & coverage reports, and quickly repair any failing tests or scripts so that the **`windows‑latest`** job passes again.

## Prerequisites

| Requirement                                | Notes                                                                                   |
| ------------------------------------------ | --------------------------------------------------------------------------------------- |
| **PowerShell 7+**                          | The workflow is automated with `pwsh`.                                                  |
| **lab\_utils/Get‑WindowsJobArtifacts.ps1** | Must exist in your local clone (or fetch it).                                           |
| **GitHub access**                          | The script relies on GitHub REST API; set `GITHUB_TOKEN` or authenticate interactively. |
| **Unzip utility**                          | Built‑in `Expand‑Archive` is sufficient.                                                |
| (Optional) **Pester v5+**                  | For local re‑runs of updated tests.                                                     |

## Step‑by‑Step

1. ### Download the latest Windows artifacts

   ```powershell
   pwsh lab_utils/Get-WindowsJobArtifacts.ps1
   ```

   *The script locates the most recent workflow run on **windows‑latest**, downloads the artifact ZIP(s) and extracts them into* `artifacts/windows‑latest/`.

2. ### Locate key report files

   | File                               | Typical path                                     |
   | ---------------------------------- | ------------------------------------------------ |
   | **coverage.xml**                   | `artifacts/windows‑latest/coverage/coverage.xml` |
   | **testResults.xml**<br>(VsTest/Pester) | `artifacts/windows‑latest/coverage/testResults.xml` |

   *The GitHub artifact is named `pester-results-${{ matrix.os }}` and contains this XML file.*

3. ### Analyse the test results

   ```powershell
   # Quick one‑liner to see failed tests
   Select-Xml -Path "artifacts/windows‑latest/coverage/testResults.xml" -XPath "//UnitTestResult[@outcome='Failed']" |
   ForEach-Object { $_.Node.testName }
   ```

   *Tip: pipe to `Format-Table` or open in VS Code for easier reading.*

4. ### Diagnose root cause

   * For each failing test, view its **ErrorMessage**/**StackTrace** nodes.
   * Cross‑check against `coverage.xml` to see which files lack execution hits—often reveals un‑run code paths on Windows.
   * Look for platform‑specific issues (path separators, ACLs, registry, `Mock` parameter names, etc.).

5. ### Fix & verify locally

    1. Edit scripts or tests.
    2. Commit changes to a new branch and push.
    3. Wait for the **windows-latest** CI job.
    4. Download results via `lab_utils/Get-WindowsJobArtifacts.ps1`.
    5. Iterate until no failing tests remain.

6. ### Commit & push

    Windows tests run only in CI. Commit your changes and push to trigger a new workflow:

    ```bash
    git commit -am "Fix Windows test failures: <brief description>"
    git push
    ```

7. ### Re‑run the CI workflow

    *Windows tests run exclusively in CI. GitHub Actions triggers automatically—confirm the **windows‑latest** job is green.*

## Troubleshooting

| Symptom                          | Likely cause                                    | Remedy                                                                           |
| -------------------------------- | ----------------------------------------------- | -------------------------------------------------------------------------------- |
| `Should -Invoke` fails (0 calls) | Mock parameter names don’t match implementation | Align names or remove filter while debugging.                                    |
| Zero tests discovered on CI      | `$SkipNonWindows` guard triggered               | Ensure `.ps1` runs **only** on Windows runner or set `$ENV:OS` override locally. |
| Artifacts script fails with 404  | No successful run yet for branch                | Authenticate with `gh` or specify `-RunId <id>`.                            |
If the helper still fails, list recent runs and pass the ID with `-RunId`:
```bash
gh run list --limit 20
```

## References

* **scripts/lab\_utils/Get-WindowsJobArtifacts.ps1** – download helper
* **.github/workflows/ci.yml** – Windows job definition
* **docs/testing.md** – general test guidelines

---

*Last updated {{DATE}}; keep this page in sync with CI changes.*

---

## Working With GitHub

* Install [GitHub CLI](https://cli.github.com/) or rely on the **ChatGPT Connector** for creating PRs and issues.
* Recent workflow runs:

  ```bash
  gh run list --limit 20
  ```
* Run local tests:

  ```bash
  pwsh -NoLogo -NoProfile -Command "Invoke-Pester"
  ```

---

## Suggested Timeline

```
Week 1 – Phase 0 (done)
Week 2 – Phase 1
Weeks 3‑4 – Phase 2
Week 5 – Phase 3
Week 6 – Phase 4 + polish
Ongoing – Phase 5
```

---

## Next Steps

* **Document** `labctl` commands in the main `README` ✔️
* **Package** default `config_files/` with the CLI ✔️
* **Begin Phase 2** – VMware provider implementation.
* **Ensure** local `pytest` passes. Windows Pester tests run on GitHub and should be checked via `Get-WindowsJobArtifacts.ps1`.

---

### Open Questions

> Let me know which phase or task needs more detail, or propose new constraints, and I can expand the plan or draft the initial PR.

---

*This is a streamlined and formatted update to `AGENTS.md`, consolidating redundant prose, fixing table layouts, and clarifying action items for quicker onboarding and maintenance.*

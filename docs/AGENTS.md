# Agents Roadmap

## Project Status

* **Phase 0 – House‑Keeping (✅ complete, June 2025)**
  - `Get-Platform.ps1` is now fully covered by Pester tests.

* **Phase 1 – Cross‑Platform Foundations (🟡 in progress)**
  - Finish cross‑platform provider implementations.

### Bootstrapping

Use the provided bootstrap helpers to spin up a test environment quickly:
- On Windows: `pwsh/kicker-bootstrap.ps1`
- On Linux: `pwsh/kickstart-bootstrap.sh`

See the [README](README.md#quick-start) for example usage and configuration pointers.

---

## Phase 0 – House‑Keeping

| Task                              | Details |
| --------------------------------- | ------- |
| Stabilise `runner.ps1`            | Added `-Scripts` (string) & `-Auto` (switch) parameters. Defaults to interactive mode. Exits non‑zero on child failures. |
| Unify config‑file loading         | New `lab_utils/Get-LabConfig.ps1` returning a `[pscustomobject]`. Handles missing file & invalid JSON. |
| CI hygiene                        | Composite action `.github/actions/lint` runs `Invoke‑ScriptAnalyzer` and `ruff`. `lint` → `pester` gates `main`. |

---

## Phase 1 – Cross‑Platform Foundations

| Task                                    | Details |
| --------------------------------------- | ------- |
| Platform detector                       | `lab_utils/Get-Platform.ps1` and `get_platform.py` return `Windows`, `Linux`, or `macOS` with shared tests. |
| Hypervisor abstraction skeleton         | `lab_utils/Hypervisor.psm1` exposes `Get-HVFacts`, `Enable-Provider`, and `Deploy-VM` with stub Hyper-V implementation. |
| Python scaffold                         | Poetry project under `py/`; Typer CLI `labctl` (`hv facts`, `hv deploy`) shares JSON config; pytest wired. |

---

## Remaining work
- Complete cross-platform provider implementations
- Expand test coverage for all runner scripts
- Improve documentation and onboarding

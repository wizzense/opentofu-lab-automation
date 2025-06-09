**Short answer:** Yes—I understand you want to evolve the Windows-centric **lab-automation** repo into a **multi-OS, multi-hypervisor, cloud-capable** automation toolkit while keeping everything reproducible, well-tested, and Codex-friendly.

Below is a **comprehensive project plan** broken into phases.  Each task is paired with a *ready-to-paste* Codex prompt that tells the model exactly what to do, the constraints it must follow, and the tests it should add or update.  Copy a prompt into your IDE, press *⌥-Enter / ⇧-Enter*, and iterate.

---

## Phase 0  House-Keeping (1 day)

| #   | Task                                                                                                                                    | Codex Prompt                                                                                                                                                                                                                                        |
| --- | --------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0.1 | **Stabilise runner.ps1**<br/>  • Accept `-Scripts "0006,0007"` without interactive prompt<br/>  • Exit with non-zero on any child error | > *“Refactor `runner.ps1` so it takes `-Scripts` (string) & `-Auto` (switch) to run non-interactive.  Preserve interactive mode by default.  Update `tests/Runner.Tests.ps1` to cover both modes.  Must stay idempotent and Windows-only for now.”* |
| 0.2 | **Unify config-file loading**<br/>Replace all `Join-Path .. 'config_files'` fragments with a single function                            | > *“Create `lab_utils/Get-LabConfig.ps1` that returns `[pscustomobject]` from a JSON/YAML file path (default `config_files/default-config.json`).  Add Pester tests for happy path, missing file, bad JSON.”*                                       |
| 0.3 | **CI hygiene**<br/>  • Lint (`PSScriptAnalyzer`, `ruff`) in GitHub Actions<br/>  • Fail on warnings                                     | > *“Add a composite action under `.github/actions/lint` that runs `Invoke-ScriptAnalyzer` and `ruff .`.  Update workflow so `lint → pester` jobs gate `main`.”*                                                                                     |

---

## Phase 1  Cross-Platform Foundations (3 days)

| #   | Task                                                                        | Codex Prompt                                                                                                                                                      |       |                                                                                    |
| --- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- | ---------------------------------------------------------------------------------- |
| 1.1 | **Platform detector**                                                       | > \*“Create `lab_utils/Get-Platform.ps1` returning \`Windows                                                                                                      | Linux | MacOS`.  Write equivalent `get\_platform.py\`.  Add cross-OS Pester and pytest.”\* |
| 1.2 | **Hypervisor abstraction skeleton**                                         | > *“Produce `lab_utils/Hypervisor.psm1` with an interface: `Get-HVFacts`, `Enable-Provider`, `Deploy-VM`.  Implement stubs for `HyperV`; unit-test with Pester.”* |       |                                                                                    |
| 1.3 | **Python scaffold**<br/>Poetry project in `/py` for future Linux/macOS work | > *“Init Poetry project `py/`.  Add Typer CLI `labctl` exposing `hv facts`, `hv deploy`, reading same JSON config.  Wire pytest.”*                                |       |                                                                                    |

---

## Phase 2  Additional Hypervisors (10 days)

| #   | Task                                                          | Codex Prompt                                                                                                                                                                |
| --- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.1 | **VMware Workstation / ESXi support (Windows & Linux hosts)** | > *“Extend `Hypervisor.psm1` and Python module with VMware implementation using `govc` (CLI).  Update tests and docs.  Add `Install-Govc.ps1` to `runner_scripts/0011_…`.”* |
| 2.2 | **Proxmox / libvirt / KVM (Linux hosts)**                     | > *“Implement Proxmox provider via its REST API (see docs).  Provide Typer sub-command.  Add pytest w/ `responses` mocks.”*                                                 |

---

## Phase 3  Cloud Targets (8 days)

| #   | Task      | Codex Prompt                                                                                                                                                                                           |
| --- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 3.1 | **Azure** | > *“Create `cloud/azure` OpenTofu module producing a vNet, subnet, VMSS.  Expose variables identical to on-prem path.  Update CI to run `tofu init` and `tofu validate` against `azurite` container.”* |
| 3.2 | **AWS**   | > *“Mirror Azure module for AWS EC2 using provider `aws`.  Keep variable names consistent (`vm_size`, `image_id`, etc.).  Include Tfsec and Checkov baselines.”*                                       |

---

## Phase 4  Secrets & Security (2 days)

| #   | Task                                              | Codex Prompt                                                                                                                                                    |
| --- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.1 | **Secrets back-ends** (KeyVault / SecretsManager) | > *“Add `lab_utils/Get-Secret.ps1` (and Python sibling) that resolves secret IDs from Azure KeyVault or AWS SecretsManager, falling back to ENV vars for dev.”* |
| 4.2 | **Hyper-V provider certificate flow**             | > *“Finish cert handling in `Prepare-HyperVProvider.ps1`: convert PFX → PEM, place in OpenTofu provider inputs, remove `insecure = true`.”*                     |

---

## Phase 5  User-Facing Improvements (ongoing)

| #   | Task                                                   | Codex Prompt                                                                                               |
| --- | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| 5.1 | **Interactive TUI** for script selection (`labctl ui`) | > *“Use `Textual` to build a curses-style selector that drives the same JSON config and invokes scripts.”* |
| 5.2 | **Docs site** (MkDocs-Material)                        | > *“Generate `docs/` with automatic API docs from PowerShell & Python.  Deploy via GitHub Pages.”*         |

---

### Suggested Timeline (reference)

```
Week 1 – Phase 0
Week 2 – Phase 1
Weeks 3-4 – Phase 2
Week 5 – Phase 3
Week 6 – Phase 4 + polish
```

> **Tip** – Paste one prompt at a time, review Codex output, then commit with matching test updates.  Keep PRs small (single task).

---

**Anything missing?**
Tell me which phase or task you’d like fleshed out further, or drop any new constraints, and I’ll update the plan (or draft the first PR for you).

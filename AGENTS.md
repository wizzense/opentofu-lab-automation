## Project status

Phase 0 was completed in June 2025. `Get-Platform.ps1` now has Pester tests.
Phase 1 is partially complete: `get_platform.py`, a pytest suite, and a basic
Typer-based CLI under `py/` are present. The Hypervisor PowerShell module is in
place with stub implementations. Further cross-platform work and provider
support remain on the roadmap.

---

## Phase 0  House-Keeping (1 day)

| #   | Task                                                                                                                                    | Codex Prompt                                                                                                                                                                                                                                        |
| --- | --------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ~~0.1~~ | ~~**Stabilise runner.ps1**<br/>  • Accept `-Scripts "0006,0007"` without interactive prompt<br/>  • Exit with non-zero on any child error~~ | > *“Refactor `runner.ps1` so it takes `-Scripts` (string) & `-Auto` (switch) to run non-interactive.  Preserve interactive mode by default.  Update `tests/Runner.Tests.ps1` to cover both modes.  Must stay idempotent and Windows-only for now.”* |
| ~~0.2~~ | ~~**Unify config-file loading**<br/>Replace all `Join-Path .. 'config_files'` fragments with a single function~~                            | > *“Create `lab_utils/Get-LabConfig.ps1` that returns `[pscustomobject]` from a JSON/YAML file path (default `config_files/default-config.json`).  Add Pester tests for happy path, missing file, bad JSON.”*                                       |
| ~~0.3~~ | ~~**CI hygiene**<br/>  • Lint (`PSScriptAnalyzer`, `ruff`) in GitHub Actions<br/>  • Fail on warnings~~                                     | > *“Add a composite action under `.github/actions/lint` that runs `Invoke-ScriptAnalyzer` and `ruff .`.  Update workflow so `lint → pester` jobs gate `main`.”*                                                                                     |

### Checking GitHub Actions status

Make sure your repo is added as a remote and that [GitHub CLI](https://cli.github.com/) is installed. Then run:

```bash
gh run list --limit 20
```

This shows recent workflow runs. You can also query the GitHub API directly.

The repository has the **ChatGPT Connector** installed. This service can open
issues and pull requests without depending on local GitHub CLI authentication.
You still need a configured Git remote if you want to push commits yourself.
`gh` commands are optional when using the connector, though they continue to
work if `gh` is installed and authenticated.

When PowerShell is available via `pwsh`, run tests locally:

```bash
pwsh -NoLogo -NoProfile -Command "Invoke-Pester"
```

### Contribution expectations

- **Tests:** Any modification to scripts or functional code (PowerShell or Python) must pass `Invoke-Pester` (and `pytest` once available) before committing.
- **Pester coverage:** When adding or modifying PowerShell scripts or modules, create or update Pester tests that exercise the new behaviour. Organise scenarios in `tests/` with `Describe` blocks named for the module or script, and cover both success and error paths where feasible.
he CI configuration and catches failures early.

---

**Shortcut**: `task test` (defined in `InvokeBuild`) runs the same steps as the lint, Pester and Pytest workflows.

- **Style:** Run `Invoke-ScriptAnalyzer` for PowerShell and `ruff .` for Python to ensure code style.
- **Docs:** Document-only changes belong under `docs/` and can skip tests but should still build successfully with `mkdocs build` once the docs site is implemented.

To locate relevant `AGENTS.md` files, you can run:
```bash
find . -maxdepth 2 -name AGENTS.md -print
```

### CI failure issues


`.github/workflows/issue-on-fail.yml` opens an issue whenever any of the lint, Pester or Pytest workflows end in `failure`. It uses `actions-ecosystem/action-create-issue@v1` with the repository `GITHUB_TOKEN` and requests `issues: write` permissions. Check these issues when debugging failing runs and mention them when submitting fixes.

The `.github/workflows/issue-on-fail.yml` workflow listens for
`workflow_run` events from the `Lint`, `Pester` and `Pytest` workflows. When a run concludes with a
`failure` status, it opens a GitHub issue using
`actions-ecosystem/action-create-issue@v1`. The issue title notes the workflow name and branch that
failed, and the body links to the failing run.

To help debug flaky tests, consider enriching the issue body with details such
as which jobs failed or key log excerpts. The `workflow_run` payload provides
job-level results that can be inserted into the issue text.


---

## Phase 1  Cross-Platform Foundations (3 days)

| #   | Task                                                                        | Codex Prompt                                                                                                                                                      |       |                                                                                    |
| --- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- | ---------------------------------------------------------------------------------- |
| ~~1.1~~ | ~~**Platform detector**~~ | > \*“Create `lab_utils/Get-Platform.ps1` returning \`Windows                                                                                                      | Linux | MacOS`.  Write equivalent `get\_platform.py\`.  Add cross-OS Pester and pytest.”\* |
| ~~1.2~~ | ~~**Hypervisor abstraction skeleton**~~ | > *“Produce `lab_utils/Hypervisor.psm1` with an interface: `Get-HVFacts`, `Enable-Provider`, `Deploy-VM`.  Implement stubs for `HyperV`; unit-test with Pester.”* |       |                                                                                    |
| ~~1.3~~ | ~~**Python scaffold**~~ | > *“Init Poetry project `py/`.  Add Typer CLI `labctl` exposing `hv facts`, `hv deploy`, reading same JSON config.  Wire pytest.”*                                |       |                                                                                    |

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

### Current Recommendations

- Document the Python `labctl` CLI in the main README (done).
- Package `config_files/` with the CLI so default paths work when installed.
- Continue Phase 2 by adding VMware provider support and corresponding tests.
- Enable `pytest` and `Invoke-Pester` locally before committing changes.

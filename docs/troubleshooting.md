# Troubleshooting CI Failures

When a Pester job fails in GitHub Actions, the console output is saved as an artifact.
Look for `pester-log-<os>` on the run summary page. These text files mirror the
**Run Pester** step and can be downloaded without signing in to GitHub.

Inspect the log to see which tests failed and view any stack traces.

## Inspecting Windows Job Artifacts

Use `lab_utils/Get-WindowsJobArtifacts.ps1` to download the latest artifacts from a completed Windows run. The script tries to locate the most recent workflow run on the `main` branch and falls back to nightly.link URLs when not authenticated with the GitHub CLI.

```powershell
pwsh -File lab_utils/Get-WindowsJobArtifacts.ps1
```

Pass `-RunId <id>` to target a specific run if automatic discovery fails. Run IDs may exceed 32-bit range, so wrap them in quotes on PowerShell 7. The helper extracts `testResults.xml` and, when available, `coverage.xml` into a temporary folder. Coverage is only uploaded on successful runs, so it may be missing when tests fail.

### Reading `testResults.xml`

Open the results file in any editor or query it with `Select-Xml`:

```powershell
Select-Xml -Path path\to\testResults.xml -XPath "//test-case@result='Failed' or @outcome='Failed'"  ForEach-Object { $_.Node.name }
```

The output lists failing Pester tests. Review the surrounding `failure` nodes for the error message and stack trace.

### Correlating with `coverage.xml`

The coverage report shows which lines executed during the test run. Search for the same file paths mentioned in `testResults.xml`:

```powershell
Select-String -Path path\to\coverage.xml -Pattern 'your-module.ps1'
```

Missing or zero-hit sections often reveal code paths that were not exercised on Windows, hinting at platform-specific issues. Compare the uncovered lines with the failing tests to narrow down the root cause.

## Automatic Failure Issues

The workflow `.github/workflows/issue-on-fail.yml` opens a single GitHub issue whenever any CI job fails. It gathers Pester and pytest results from the run artifacts and posts a summary of failing tests in the issue body. Subsequent failed runs append a comment rather than creating new issues.

After fetching the artifacts with `gh run download`, remember to extract the downloaded archives:

```bash
for z in artifacts/*.zip; do
  unzip -q "$z" -d artifacts
done
```

---

See pester-test-failures.md(pester-test-failures.md) for a tracked list of current test failures.

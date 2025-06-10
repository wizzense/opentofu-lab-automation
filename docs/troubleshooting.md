# Troubleshooting CI failures

When a Pester job fails in GitHub Actions, the console output is saved as an artifact.
Look for `pester-log-<os>` on the run summary page. These text files mirror the
**Run Pester** step and can be downloaded without signing in to GitHub.

Inspect the log to see which tests failed and view any stack traces.

# Copilot Auto Fix Workflow

The workflow `.github/workflows/copilot-auto-fix.yml` uses the GitHub Copilot CLI extension via `gh`. It requires an OAuth token with the `copilot` scope.

1. Install and authenticate the [GitHub CLI](https://cli.github.com/):

   ```bash
   gh auth login --web
   ```

2. Refresh your token with the additional scope and print it:

   ```bash
   gh auth refresh -s copilot
   gh auth token
   ```

3. Add the token as the repository secret **`COPILOT_OAUTH_TOKEN`**.

The workflow reads the secret and sets the `GH_TOKEN` environment variable so that Copilot can suggest fixes for open issues. If the secret is missing, the job stops immediately with an error message.

---

See [pester-test-failures.md](pester-test-failures.md) for a tracked list of current test failures.


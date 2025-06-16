# Debugging Tests in Codespaces with Copilot Agent

This guide explains how to use GitHub Codespaces together with Copilot in agent mode to troubleshoot failing tests.

## Launch a Codespace

1. Open the **Code** drop-down on the repository page and choose **Create codespace**.
2. Wait for the container to build and connect.

## Install Dependencies

Inside the codespace terminal run:

```bash
./tools/setup-tests.sh
```

This installs PowerShell modules and the Python packages required for the Pester and pytest suites.

## Run the Tests

```bash
pwsh -NoLogo -NoProfile -Command "Invoke-Pester"
pytest py
```

Review any failures in the terminal output or in the generated `artifacts` folder.

## Use Copilot Agent Mode

1. Open the **Copilot Chat** view in VS Code.
2. Enable **Agent** mode and ask Copilot for help, for example:
   ```
   /agent troubleshoot failing tests
   ```
3. Follow the suggestions to inspect logs, locate error messages and propose fixes.

For manual steps on interpreting `testResults.xml` and `coverage.xml`, see Troubleshooting CI(troubleshooting.md).

---

See pester-test-failures.md(pester-test-failures.md) for a tracked list of current test failures.

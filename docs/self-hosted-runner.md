# Self-hosted GitHub Actions Runner

This repository can use your own machine to execute workflow jobs. The following steps are adapted from the GitHub runner setup page.

1. **Create a folder and download the runner**

   ```powershell
   mkdir actions-runner; cd actions-runner
   $runnerVersion = "2.325.0"
   $runnerChecksum = "8601aa56828c084b29bdfda574af1fcde0943ce275fdbafb3e6d4a8611245b1b"
   mkdir actions-runner; cd actions-runner
   Invoke-WebRequest -Uri "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip" -OutFile "actions-runner-win-x64-$runnerVersion.zip"
   ```

2. **Configure the runner**

   ```powershell
   ./config.cmd --url https://github.com/wizzense/opentofu-lab-automation --token <token>
   ```

   Replace `<token>` with the registration token from the repository settings.

3. **Start the runner**

   ```powershell
   ./run.cmd
   ```

   Leave this terminal open while jobs are running, or install the runner as a service.

Use `runs-on: self-hosted` in a workflow job to target your machine.

---

See pester-test-failures.md(pester-test-failures.md) for a tracked list of current test failures.

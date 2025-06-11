# Self-hosted GitHub Actions Runner

This repository can use your own machine to execute workflow jobs. The following steps are adapted from the GitHub runner setup page.

1. **Create a folder and download the runner**

   ```powershell
   mkdir actions-runner; cd actions-runner
   Invoke-WebRequest -Uri https://github.com/actions/runner/releases/latest/download/actions-runner-win-x64.zip -OutFile actions-runner-win-x64.zip
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

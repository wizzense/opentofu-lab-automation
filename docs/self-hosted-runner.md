# Self-hosted GitHub Actions Runner

This repository can use your own machine to execute workflow jobs. The following steps are adapted from the GitHub runner setup page.

1. **Create a folder and download the runner**

   ```powershell
   mkdir actions-runner; cd actions-runner
   Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.325.0/actions-runner-win-x64-2.325.0.zip -OutFile actions-runner-win-x64-2.325.0.zip
   ```

   Optionally validate the package hash:

   ```powershell
   if((Get-FileHash -Path actions-runner-win-x64-2.325.0.zip -Algorithm SHA256).Hash.ToUpper() -ne '8601aa56828c084b29bdfda574af1fcde0943ce275fdbafb3e6d4a8611245b1b'.ToUpper()){ throw 'Computed checksum did not match' }
   ```

   Extract the archive:

   ```powershell
   Add-Type -AssemblyName System.IO.Compression.FileSystem
   [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.325.0.zip", "$PWD")
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

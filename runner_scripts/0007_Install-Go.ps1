Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

# Param([pscustomobject]$Config)
# Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
if ($Config.InstallGo -eq $true) {
    $GoConfig = $Config.Go
    if ($null -eq $GoConfig) {
        Write-CustomLog "No Go configuration found. Skipping installation."
        return
    }

    if ($GoConfig.InstallerUrl) {
        $installerUrl = $GoConfig.InstallerUrl
        if ($installerUrl -match "go([\d\.]+)\.windows-([a-z0-9]+)\.msi") {
            $goVersion = $matches[1]
            $goArch = $matches[2]
        } else {
            Write-CustomLog "Unable to extract Go version and architecture from InstallerUrl."
            return
        }
    } elseif ($GoConfig.Version) {
        $goVersion = $GoConfig.Version
        $goArch = $GoConfig.Architecture
        if (-not $goArch) { $goArch = "amd64" }
    } else {
        Write-CustomLog "No Go version or InstallerUrl specified. Skipping installation."
        return
    }

    # Check if Go is already installed by looking for the 'go' command
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Write-CustomLog "Go is already installed. Skipping installation."
        return
    }

    Write-CustomLog "Installing Go version $goVersion for architecture $goArch..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-LabDownload -Uri $installerUrl -Prefix 'GoInstaller' -Extension '.msi' -Action {
        param($installerPath)
        Write-CustomLog "Installing Go silently..."
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installerPath`" /qn /L*v `"$env:TEMP\GoInstall.log`""
        Write-CustomLog "Go installation complete."
    }
} else {
    Write-CustomLog "InstallGo flag is disabled. Skipping Go installation."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}

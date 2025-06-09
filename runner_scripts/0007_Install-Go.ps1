Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"
if ($Config.InstallGo -eq $true) {
    $GoConfig = $Config.Go
    if ($null -eq $GoConfig) {
        Write-Log "No Go configuration found. Skipping installation."
        return
    }

    if ($GoConfig.InstallerUrl) {
        $installerUrl = $GoConfig.InstallerUrl
        if ($installerUrl -match "go([\d\.]+)\.windows-([a-z0-9]+)\.msi") {
            $goVersion = $matches[1]
            $goArch = $matches[2]
        } else {
            Write-Log "Unable to extract Go version and architecture from InstallerUrl."
            return
        }
    } elseif ($GoConfig.Version) {
        $goVersion = $GoConfig.Version
        $goArch = $GoConfig.Architecture
        if (-not $goArch) { $goArch = "amd64" }
    } else {
        Write-Log "No Go version or InstallerUrl specified. Skipping installation."
        return
    }

    # Check if Go is already installed by looking for the 'go' command
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Write-Log "Go is already installed. Skipping installation."
        return
    }

    Write-Log "Installing Go version $goVersion for architecture $goArch..."
    $installerPath = "$env:TEMP\GoInstaller.msi"

    $ProgressPreference = 'SilentlyContinue'
    Write-Log "Downloading Go from $installerUrl"
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

    Write-Log "Installing Go silently..."
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installerPath`" /qn /L*v `"$env:TEMP\GoInstall.log`""

    Write-Log "Go installation complete."
}
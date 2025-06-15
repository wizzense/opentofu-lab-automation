Param([object]$Config)







Import-Module "/pwsh/modules/LabRunner/"  -Force
Write-CustomLog "Starting $MyInvocation.MyCommand"

function Install-Cosign {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    






# Check if cosign is available in the current PATH
    if (-not (Test-Path (Join-Path $Config.CosignPath "cosign-windows-amd64.exe") -ErrorAction SilentlyContinue)) {
        Write-CustomLog "Cosign is not found. Installing cosign..."
        
        # Define the installation directory and destination file path
        $installDir = $Config.CosignPath
        $destination = Join-Path $installDir "cosign-windows-amd64.exe"

        # Create the installation folder if it doesn't exist
        if (-not (Test-Path $installDir)) {
            if ($PSCmdlet.ShouldProcess($installDir, 'Create directory')) {
                New-Item -ItemType Directory -Path $installDir -Force | Out-Null
            }
        }

        if (-not (Test-Path $destination)) {
            try {
                if ($PSCmdlet.ShouldProcess($destination, 'Download cosign')) {
                    # Download the cosign executable
                    Invoke-LabWebRequest -Uri $Config.CosignURL -OutFile $destination -UseBasicParsing
                    Write-CustomLog "Cosign downloaded and installed at $destination"
                }
            }
            catch {
                Write-Error "Failed to download cosign from $Config.CosignURL. Please check your internet connection and try again."
                return
            }
        }

        # Add the installation folder to the user's PATH if not already present
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if (-not $userPath) { $userPath = '' }
        if (-not $userPath.Contains($installDir)) {
            if ($PSCmdlet.ShouldProcess('User PATH', 'Update environment variable')) {
                [Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
                Write-CustomLog "Added $installDir to your user PATH. You may need to restart your session for this change to take effect."
            }
        }
    }
    else {
        Write-CustomLog "Cosign is already installed."
    }
}

function Find-Gpg {
    # Check if gpg is available in the current PATH
    if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
        Write-CustomLog "GPG is not found."
        Write-CustomLog "Please install Gpg4win from https://www.gpg4win.org/ and ensure it is added to your PATH."
    }
    else {
        Write-CustomLog "GPG is already installed."
    }
}

Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

# Execute based on provided switches
if ($Config.InstallCosign -eq $true) {
    Install-Cosign
}
elseif ($Config.InstallGpg -eq $true) {
    Find-Gpg
}

if (-not $Config.InstallCosign -and -not $Config.InstallGpg) {
    Write-CustomLog "No installation option specified. Use -InstallCosign and/or -InstallGpg when running this script."
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
















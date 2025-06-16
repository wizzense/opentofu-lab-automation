# Ensure the Param block is at the top if it's meant for the whole script
Param([object]$Config)








# Import necessary modules
Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"

function Install-NodeCore {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    






Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

    Write-CustomLog "==== [0201] Installing Node.js Core ===="

    $nodeDeps = if ($Config -is [hashtable]) { $Config['Node_Dependencies']    } else { $Config.Node_Dependencies    }
    if (-not $nodeDeps) {
        Write-CustomLog "Config missing Node_Dependencies; skipping Node.js installation."
        return
    }

    if ($nodeDeps.InstallNode) {
        if (Get-Command node -ErrorAction SilentlyContinue) {
            Write-CustomLog "Node.js already installed. Skipping installation."
            return
        }
        try {
            $url = $null
            if ($nodeDeps.Node) {
                if ($nodeDeps.Node -is [hashtable]) {
                    $url = $nodeDeps.Node['InstallerUrl']
                } elseif ($nodeDeps.Node.PSObject.Properties.Match('InstallerUrl').Count -gt 0) {
                    $url = $nodeDeps.Node.InstallerUrl
                }
            }
            if (-not $url) {
                $url = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
            }

            Invoke-LabDownload -Uri $url -Prefix 'node-installer' -Extension '.msi' -Action {
                param($installerPath)
                






Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -NoNewWindow
            }

            if (Get-Command node -ErrorAction SilentlyContinue) {
                Write-CustomLog "Node.js installed successfully."
                node -v
            } else {
                Write-Error "Node.js installation failed."
                exit 1
            }
        } catch {
            Write-Warning "Failed to install Node.js: $_"
        }
    } else {
        Write-CustomLog "InstallNode flag is disabled. Skipping Node.js installation."
    }

    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}

# Start the NodeCore installation if the script is directly invoked
if ($MyInvocation.InvocationName -ne '.') { Install-NodeCore @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"


















Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"

function Install-Poetry {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        param($Config)
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

        if ($Config.InstallPoetry -eq $true) {
            $installerUrl = 'https://install.python-poetry.org'
            Invoke-LabDownload -Uri $installerUrl -Prefix 'install-poetry' -Extension '.py' -Action {
                param($installerPath)
                $args = @()
                if ($Config.PoetryVersion) {
                    $args += '--version'
                    $args += $Config.PoetryVersion
                }
                Write-CustomLog 'Executing Poetry installer...'
                $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
                if (-not $pythonCmd) {
                    throw 'Python executable not found. Ensure Python is installed and in PATH.'
                }
                & $pythonCmd.Path $installerPath @args
            }
        }
        else {
            Write-CustomLog 'InstallPoetry flag is disabled. Skipping Poetry installation.'
        }

        Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
    }
}

if ($MyInvocation.InvocationName -ne '.') { Install-Poetry @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"

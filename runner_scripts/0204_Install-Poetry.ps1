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
            $installerPath = Join-Path $env:TEMP 'install-poetry.py'

            Invoke-LabWebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

            $args = @()
            if ($Config.PoetryVersion) {
                $args += '--version'
                $args += $Config.PoetryVersion
            }
            Write-CustomLog 'Executing Poetry installer...'
            python $installerPath @args
            Remove-Item $installerPath -Force
        }
        else {
            Write-CustomLog 'InstallPoetry flag is disabled. Skipping Poetry installation.'
        }

        Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
    }
}

if ($MyInvocation.InvocationName -ne '.') { Install-Poetry @PSBoundParameters }

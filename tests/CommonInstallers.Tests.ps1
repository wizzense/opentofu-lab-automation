. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabSetup' 'LabSetup.psd1') -Force
InModuleScope LabSetup {
Describe 'Additional installer scripts' {
    BeforeAll {
        $script:cases = @(
            @{ Flag='InstallPython';        Script='0206_Install-Python.ps1';        Command='Start-Process' },
            @{ Flag='InstallGit';           Script='0207_Install-Git.ps1';           Command='Start-Process' },
            @{ Flag='InstallDockerDesktop'; Script='0208_Install-DockerDesktop.ps1'; Command='Start-Process' },
            @{ Flag='Install7Zip';          Script='0209_Install-7Zip.ps1';          Command='Start-Process' },
            @{ Flag='InstallVSCode';        Script='0210_Install-VSCode.ps1';        Command='Start-Process' },
            @{ Flag='InstallVSBuildTools';  Script='0211_Install-VSBuildTools.ps1';  Command='Start-Process' },
            @{ Flag='InstallAzureCLI';      Script='0212_Install-AzureCLI.ps1';      Command='Start-Process' },
            @{ Flag='InstallAWSCLI';        Script='0213_Install-AWSCLI.ps1';        Command='Start-Process' },
            @{ Flag='InstallPacker';        Script='0214_Install-Packer.ps1';        Command='Expand-Archive' },
            @{ Flag='InstallChocolatey';    Script='0215_Install-Chocolatey.ps1';    Command='Start-Process' }
        )
    }

    It 'runs installer when flag enabled' -TestCases $script:cases {
        param($Flag,$Script,$Command)
        $cfg = [pscustomobject]@{ $Flag = $true }
        $path = Get-RunnerScriptPath $Script
        Mock Invoke-LabWebRequest {}
        Mock Start-Process {}
        Mock Expand-Archive {}
        Mock-WriteLog
        & $path -Config $cfg
        Should -Invoke -CommandName $Command -Times 1
    }

    It 'skips when flag disabled' -TestCases $script:cases {
        param($Flag,$Script,$Command)
        $cfg = [pscustomobject]@{ $Flag = $false }
        $path = Get-RunnerScriptPath $Script
        Mock Invoke-LabWebRequest {}
        Mock Start-Process {}
        Mock Expand-Archive {}
        Mock-WriteLog
        & $path -Config $cfg
        Should -Invoke -CommandName $Command -Times 0
    }
}
}

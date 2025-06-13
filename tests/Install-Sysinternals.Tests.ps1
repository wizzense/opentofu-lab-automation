. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '0205_Install-Sysinternals' -Skip:($SkipNonWindows) {
    InModuleScope LabRunner {
        BeforeAll { 
            Enable-WindowsMocks
            $script:ScriptPath = Get-RunnerScriptPath '0205_Install-Sysinternals.ps1'
        }
        It 'downloads and extracts when enabled' {
            $dest = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
            $cfg  = [pscustomobject]@{ InstallSysinternals = $true; SysinternalsPath = $dest }
            Mock Invoke-LabDownload { 
                param($Uri, $Prefix, $Extension, $Action)
                



$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "mock_$Prefix.zip"
                New-Item -ItemType File -Path $tempFile -Force | Out-Null
                try { & $Action $tempFile } finally { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
            }
            Mock Expand-Archive {}
            Mock New-Item {}
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $dest }
            Mock Remove-Item {}
            
            & $script:ScriptPath -Config $cfg
            
            Should -Invoke -CommandName Invoke-LabDownload -Times 1 -ParameterFilter { $Uri -eq 'https://download.sysinternals.com/files/SysinternalsSuite.zip' }
            Should -Invoke -CommandName Expand-Archive -Times 1 -ParameterFilter { $DestinationPath -eq $dest }
        }
        It 'skips when InstallSysinternals is false' {
            $cfg = [pscustomobject]@{ InstallSysinternals = $false }
            Mock Invoke-LabDownload {}
            Mock Expand-Archive {}
            
            & $script:ScriptPath -Config $cfg
            
            Should -Invoke -CommandName Invoke-LabDownload -Times 0
            Should -Invoke -CommandName Expand-Archive -Times 0
        }
    }

    AfterAll {
        Get-Module LabRunner | Remove-Module -Force -ErrorAction SilentlyContinue
    }
}



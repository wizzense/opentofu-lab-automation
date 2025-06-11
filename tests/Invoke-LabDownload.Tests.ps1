. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'LabRunner.psd1') -Force

Describe 'Invoke-LabDownload' {
    BeforeEach {
        Mock Invoke-LabWebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
    }

    It 'downloads and executes action with cleanup' {
        Invoke-LabDownload -Uri 'http://example.com/file.exe' -Prefix 'test' -Action { param($p) Start-Process $p -Wait }
        Should -Invoke -CommandName Invoke-LabWebRequest -Times 1
        Should -Invoke -CommandName Start-Process -Times 1
        Should -Invoke -CommandName Remove-Item -Times 1
    }
}

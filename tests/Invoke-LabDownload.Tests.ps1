. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'Invoke-LabDownload' {
    BeforeAll {
        if (-not $env:TEMP) {
            $env:TEMP = if ($IsWindows) { 'C:\\temp' } else { '/tmp' }
        }
    }
        It 'downloads and executes action with cleanup' {
        InModuleScope LabRunner {
            Mock Invoke-LabWebRequest {}
            Mock Start-Process {}
            Mock Remove-Item {}
            Invoke-LabDownload -Uri 'http://example.com/file.exe' -Prefix 'test' -Action { param($p) 



Start-Process $p -Wait }
            Should -Invoke -CommandName Invoke-LabWebRequest -Times 1
            Should -Invoke -CommandName Start-Process -Times 1
            Should -Invoke -CommandName Remove-Item -Times 1
        }
    }
}



. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe 'Write-CustomLog' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'Logger.ps1')
    }
    It 'works when LogFilePath variable is not defined' {
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        { Write-CustomLog 'test message' } | Should -Not -Throw
    }

    It 'works under strict mode without global variable' {
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        Set-StrictMode -Version Latest
        { Write-CustomLog 'another test' } | Should -Not -Throw
        Set-StrictMode -Off
    }

    It 'appends to log file when LogFilePath is set' {
        $tempFile = (Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())) + '.log'
        $script:LogFilePath = $tempFile
        try {
            Write-CustomLog 'hello world'
            $content = Get-Content $tempFile -Raw
            $content | Should -Match 'hello world'
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        }
    }

    It 'defaults to LogFilePath variable when not provided' {
        $tempFile = (Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())) + '.log'
        $script:LogFilePath = $tempFile
        try {
            Write-CustomLog 'variable default works'
            $content = Get-Content $tempFile -Raw
            $content | Should -Match 'variable default works'
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        }
    }
}

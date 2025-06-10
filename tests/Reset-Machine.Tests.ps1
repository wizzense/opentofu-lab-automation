. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe 'Reset-Machine script' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '9999_Reset-Machine.ps1'
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-Platform.ps1')
    }

    BeforeEach {
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
    }

    It 'calls Restart-Computer on Windows' {
        Mock Get-Platform { 'Windows' }
        Mock Restart-Computer {}
        . $script:ScriptPath -Config ([pscustomobject]@{})
        Assert-MockCalled Restart-Computer -Times 1
    }

    It 'calls Restart-Computer on Linux' {
        Mock Get-Platform { 'Linux' }
        Mock Restart-Computer {}
        . $script:ScriptPath -Config ([pscustomobject]@{})
        Assert-MockCalled Restart-Computer -Times 1
    }

    It 'returns exit code 1 for unknown platform' {
        Mock Get-Platform { 'Unknown' }
        Mock Restart-Computer {}
        try {
            . $script:ScriptPath -Config ([pscustomobject]@{})
            $code = $LASTEXITCODE
        } catch {
            $code = 1
        }
        $code | Should -Be 1
        Assert-MockCalled Restart-Computer -Times 0
    }
}

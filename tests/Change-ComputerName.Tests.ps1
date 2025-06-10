. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0103_Change-ComputerName' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0103_Change-ComputerName.ps1'
    }

    It 'renames computer when enabled and name differs' {
        $cfg = [pscustomobject]@{ SetComputerName = $true; ComputerName = 'NewPC' }
        Mock Get-CimInstance { [pscustomobject]@{ Name = 'OldPC' } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Rename-Computer {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Rename-Computer -ParameterFilter { $NewName -eq 'NewPC' -and $Force } -Times 1
    }

    It 'skips rename when names match' {
        $cfg = [pscustomobject]@{ SetComputerName = $true; ComputerName = 'Same' }
        Mock Get-CimInstance { [pscustomobject]@{ Name = 'Same' } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Rename-Computer {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Rename-Computer -Times 0
    }

    It 'does nothing when SetComputerName is false' {
        $cfg = [pscustomobject]@{ SetComputerName = $false; ComputerName = 'NewPC' }
        Mock Get-CimInstance { [pscustomobject]@{ Name = 'OldPC' } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Rename-Computer {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Rename-Computer -Times 0
    }
}

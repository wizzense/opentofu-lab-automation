. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe 'Format-Config' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Format-Config.ps1')
    }
    It 'formats config as indented JSON' {
        $cfg = [pscustomobject]@{ Foo = 'bar'; Baz = 1 }
        $result = Format-Config -Config $cfg
        $result | Should -Match '"Foo"\s*:\s*"bar"'
        $result | Should -Match '"Baz"\s*:\s*1'
    }

    It 'throws when Config is null' {
        { Format-Config -Config $null } | Should -Throw
    }

    It 'is a terminating error when Config is null' {
        { Format-Config -Config $null } |
            Should -Throw -ErrorType System.ArgumentNullException
    }
}

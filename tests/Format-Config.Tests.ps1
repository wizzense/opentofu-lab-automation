. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
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

    It 'accepts pipeline input' {
        $cfg = [pscustomobject]@{ Foo = 'pipe' }
        $result = $cfg | Format-Config
        $result | Should -Match '"Foo"\s*:\s*"pipe"'
    }

    It 'accepts pipeline input by property name' {
        $cfg = [pscustomobject]@{ Foo = 'prop' }
        $wrapper = [pscustomobject]@{ Config = $cfg }
        $result = $wrapper | Format-Config
        $result | Should -Match '"Foo"\s*:\s*"prop"'
    }

    It 'throws when no Config is provided' {
        try {
            Format-Config -Config $null
            $false | Should -BeTrue
        } catch {
            $_.Exception | Should -BeOfType [System.Management.Automation.ParameterBindingException]
        }
    }

    It 'throws when pipeline is empty' {
        try {
            @() | Format-Config
            $false | Should -BeTrue
        } catch {
            $_.Exception | Should -BeOfType [System.ArgumentException]
        }
    }

    It 'throws when Config is null' {
        { Format-Config -Config $null } | Should -Throw
    }

    It 'is a terminating error when Config is null' {
        try {
            Format-Config -Config $null
            $false | Should -BeTrue
        } catch {
            $_.Exception | Should -BeOfType [System.Management.Automation.ParameterBindingException]
        }
    }

    It 'is a terminating error when piped null' {
        try {
            ,$null | Format-Config
            $false | Should -BeTrue
        } catch {
            $_.Exception | Should -BeOfType [System.ArgumentException]
        }
    }
}

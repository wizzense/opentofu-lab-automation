Describe 'Format-Config' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Format-Config.ps1')
    }
    It 'formats config as key-value lines' {
        $cfg = [pscustomobject]@{ Foo = 'bar'; Baz = 1 }
        $result = Format-Config -Config $cfg
        $result | Should -Match 'Foo: bar'
        $result | Should -Match 'Baz: 1'
    }
}

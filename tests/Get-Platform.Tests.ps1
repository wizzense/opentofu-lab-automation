Describe 'Get-Platform' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-Platform.ps1')
    }

    It 'returns the correct platform for the current OS' {
        $expected = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'MacOS' } else { 'Unknown' }
        Get-Platform | Should -Be $expected
    }
}

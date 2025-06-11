. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe 'Get-MenuSelection' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Menu.ps1')
        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
    }
    AfterEach {
        Remove-Item Function:Read-LoggedInput -ErrorAction SilentlyContinue
    }
    It 'returns all items when user types all' {
        $items = @('0001_Test.ps1','0002_Other.ps1')
        function global:Read-LoggedInput { param($Prompt) 'all' }
        $sel = Get-MenuSelection -Items $items -AllowAll
        $sel | Should -Be $items
    }
    It 'returns item by prefix' {
        $items = @('0001_Test.ps1','0002_Other.ps1')
        $responses = @('0002')
        $script:i = 0
        function global:Read-LoggedInput { param($Prompt) $responses[$script:i++] }
        $sel = Get-MenuSelection -Items $items
        $sel | Should -Be @('0002_Other.ps1')
    }
}

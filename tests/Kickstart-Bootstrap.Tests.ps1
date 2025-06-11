. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe 'kickstart-bootstrap script' {
    It 'exists under pwsh' {
        $path = Join-Path $PSScriptRoot '..' 'pwsh' 'kickstart-bootstrap.sh'
        (Test-Path $path) | Should -BeTrue
    }
    It 'references kickstart.cfg' {
        $path = Join-Path $PSScriptRoot '..' 'pwsh' 'kickstart-bootstrap.sh'
        $content = Get-Content $path -Raw
        $content | Should -Match 'kickstart.cfg'
    }
}

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe 'kickstart-bootstrap script' {
    It 'exists at repo root' {
        $path = Join-Path $PSScriptRoot '..' 'kickstart-bootstrap.sh'
        (Test-Path $path) | Should -BeTrue
    }
    It 'references kickstart.cfg' {
        $path = Join-Path $PSScriptRoot '..' 'kickstart-bootstrap.sh'
        $content = Get-Content $path -Raw
        $content | Should -Match 'kickstart.cfg'
    }
}

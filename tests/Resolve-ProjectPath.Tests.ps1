. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')

Describe 'Resolve-ProjectPath' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'Resolve-ProjectPath.ps1'
        . $modulePath
    }

    It 'finds file recursively and after move' {
        $root = Join-Path $TestDrive 'repo'
        $dir1 = Join-Path $root 'a'
        $dir2 = Join-Path $root 'b'
        New-Item -ItemType Directory -Path $dir1 -Force | Out-Null
        New-Item -ItemType Directory -Path $dir2 -Force | Out-Null
        $file = Join-Path $dir1 'test.ps1'
        'hi' | Set-Content -Path $file
        Resolve-ProjectPath -Name 'test.ps1' -Root $root | Should -Be $file
        Move-Item -Path $file -Destination $dir2
        $expected = Join-Path $dir2 'test.ps1'
        Resolve-ProjectPath -Name 'test.ps1' -Root $root | Should -Be $expected
    }

    It 'resolves path from path-index.yaml' {
        $root = Join-Path $TestDrive 'repo2'
        $scripts = Join-Path $root 'scripts'
        New-Item -ItemType Directory -Path $scripts -Force | Out-Null
        $file = Join-Path $scripts 'script.ps1'
        'hi' | Set-Content -Path $file
        "scripts/script.ps1: scripts/script.ps1" | Set-Content -Path (Join-Path $root 'path-index.yaml')

        $expected = Join-Path $root 'scripts' 'script.ps1'
        Resolve-ProjectPath -Name 'script.ps1' -Root $root | Should -Be $expected
    }

    It 'resolves direct index entry with normalized separators' {
        $root = Join-Path $TestDrive 'repo3'
        $scripts = Join-Path $root 'scripts'
        New-Item -ItemType Directory -Path $scripts -Force | Out-Null
        $file = Join-Path $scripts 'script.ps1'
        'hi' | Set-Content -Path $file
        "script.ps1: scripts/script.ps1" | Set-Content -Path (Join-Path $root 'path-index.yaml')

        $expected = Join-Path $root 'scripts' 'script.ps1'
        Resolve-ProjectPath -Name 'script.ps1' -Root $root | Should -Be $expected
    }
}

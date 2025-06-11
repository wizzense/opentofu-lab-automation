. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe '0002_Setup-Directories' -Skip:($SkipNonWindows) {
    BeforeAll {
        $script:ScriptPath = Get-RunnerScriptPath '0002_Setup-Directories.ps1'
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'Logger.ps1')
    }

    BeforeEach {
        $script:temp = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:temp | Out-Null
    }

    AfterEach {
        Remove-Item -Recurse -Force $script:temp -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
    }

    It 'creates directories when the script runs' {
        $hv  = Join-Path $script:temp 'hyperv'
        $iso = Join-Path $script:temp 'iso'
        $cfg = [pscustomobject]@{ Directories = @{ HyperVPath = $hv; IsoSharePath = $iso } }
        & $script:ScriptPath -Config $cfg
        (Test-Path $hv)  | Should -BeTrue
        (Test-Path $iso) | Should -BeTrue
    }

    It 'handles existing directories gracefully' {
        $hv  = Join-Path $script:temp 'hyperv'
        $iso = Join-Path $script:temp 'iso'
        New-Item -ItemType Directory -Path $hv  | Out-Null
        New-Item -ItemType Directory -Path $iso | Out-Null
        $cfg = [pscustomobject]@{ Directories = @{ HyperVPath = $hv; IsoSharePath = $iso } }
        { & $script:ScriptPath -Config $cfg } | Should -Not -Throw
        (Test-Path $hv)  | Should -BeTrue
        (Test-Path $iso) | Should -BeTrue
    }
}

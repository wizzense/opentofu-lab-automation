Describe 'Invoke-LabScript' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..' 'lab_utils' 'Invoke-LabScript.ps1'
        . $modulePath
    }

    It 'throws when Config is null' {
        { Invoke-LabScript -Config $null -ScriptBlock { } } | Should -Throw
    }

    It 'executes the provided script block' {
        $ran = $false
        Invoke-LabScript -Config @{} -ScriptBlock { $script:ran = $true }
        $ran | Should -BeTrue
    }
}

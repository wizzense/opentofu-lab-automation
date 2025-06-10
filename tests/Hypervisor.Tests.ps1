. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe 'Hypervisor module' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'Hypervisor.psm1') -Force
    }

    It 'Get-HVFacts returns provider information' {
        $facts = Get-HVFacts
        $facts.Provider | Should -Be 'Hyper-V'
        $facts.Version  | Should -Be '0.1'
    }

    It 'Enable-Provider returns confirmation string' {
        Enable-Provider | Should -Be 'Hyper-V provider enabled'
    }

    It 'Deploy-VM returns deployment message' {
        Deploy-VM -Name 'test' | Should -Be 'Deployed test'
    }
}

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'Get-MenuSelection' {
    InModuleScope LabRunner {
        BeforeAll {
            # Ensure we have the Write-CustomLog function available
            Mock Write-CustomLog {}
        }
        
        Context 'returns all items when user types all' {
            It 'returns all items' {
                Mock Read-LoggedInput { 'all' }
                $items = @('0001_Test.ps1','0002_Other.ps1')
                $sel = Get-MenuSelection -Items $items -AllowAll
                $sel | Should -Be $items
            }
        }
        
        Context 'returns item by prefix' {
            It 'returns item by prefix' {
                Mock Read-LoggedInput { '0002' }
                $items = @('0001_Test.ps1','0002_Other.ps1')
                $sel = Get-MenuSelection -Items $items
                $sel | Should -Be @('0002_Other.ps1')
            }
        }
        
        Context 'returns empty array when user types exit' {
            It 'returns empty array' {
                Mock Read-LoggedInput { 'exit' }
                $items = @('0001_Test.ps1','0002_Other.ps1')
                $sel = Get-MenuSelection -Items $items
                $sel | Should -Be @()
            }
        }
        
        Context 'handles invalid input gracefully' {
            It 'returns empty array after max retries' {
                Mock Read-LoggedInput { 'invalid' }
                $items = @('0001_Test.ps1','0002_Other.ps1')
                $sel = Get-MenuSelection -Items $items -MaxRetries 1
                $sel | Should -Be @()
            }
        }
    }

    AfterAll {
        Get-Module LabRunner | Remove-Module -Force -ErrorAction SilentlyContinue
    }
}

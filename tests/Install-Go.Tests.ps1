. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '0007_Install-Go' {
    InModuleScope LabRunner {
        BeforeAll { 
            $script:ScriptPath = Get-RunnerScriptPath '0007_Install-Go.ps1'
            if (-not $script:ScriptPath -or -not (Test-Path $script:ScriptPath)) {
                throw "Script under test not found: 0007_Install-Go.ps1 (resolved path: $script:ScriptPath)"
            }
        }

        It 'installs Go when enabled' {
            $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
            Mock Get-Command {} -ParameterFilter { $Name -eq 'go' }
            Mock Start-Process {}
            Mock Invoke-LabDownload { 
                # Execute the action block if provided
                if ($Action) { & $Action 'test-installer.msi' }
            }
            
            & $script:ScriptPath -Config $cfg
            Should -Invoke -CommandName Invoke-LabDownload -Times 1
            Should -Invoke -CommandName Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'msiexec.exe' }
        }

        It 'skips when InstallGo is false' {
            $cfg = [pscustomobject]@{ InstallGo = $false; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
            Mock Invoke-LabDownload {}
            Mock Start-Process {}
            
            & $script:ScriptPath -Config $cfg
            Should -Invoke -CommandName Invoke-LabDownload -Times 0
            Should -Invoke -CommandName Start-Process -Times 0
        }

        It 'does nothing when Go is already installed' {
            $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
            Mock Get-Command { @{ Name = 'go' } } -ParameterFilter { $Name -eq 'go' }
            Mock Invoke-LabDownload {}
            Mock Start-Process {}
            
            & $script:ScriptPath -Config $cfg
            Should -Invoke -CommandName Invoke-LabDownload -Times 0
            Should -Invoke -CommandName Start-Process -Times 0
        }
    }
    
    AfterAll {
        Get-Module LabRunner | Remove-Module -Force -ErrorAction SilentlyContinue
    }
}

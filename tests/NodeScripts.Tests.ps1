Describe 'Node installation scripts' {
    BeforeAll {
        $scriptRoot = Join-Path $PSScriptRoot '..' 'runner_scripts'
        $core    = (Resolve-Path -ErrorAction Stop (Join-Path $scriptRoot '0201_Install-NodeCore.ps1')).Path
        $global  = (Resolve-Path -ErrorAction Stop (Join-Path $scriptRoot '0202_Install-NodeGlobalPackages.ps1')).Path
        $npm     = (Resolve-Path -ErrorAction Stop (Join-Path $scriptRoot '0203_Install-npm.ps1')).Path

        $env:TEMP = Join-Path ([System.IO.Path]::GetTempPath()) 'pester-temp'
        New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
    }

    It 'resolves script paths from the tests directory' {
        Test-Path $core | Should -BeTrue
        Test-Path $global | Should -BeTrue
        Test-Path $npm   | Should -BeTrue
    }

    It 'uses Node_Dependencies.Node.InstallerUrl when installing Node' {
        $config = @{ Node_Dependencies = @{ InstallNode=$true; Node = @{ InstallerUrl = 'http://example.com/node.msi' } } }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command { @{Name='node'} } -ParameterFilter { $Name -eq 'node' }
        . $core

        Install-NodeCore -Config $config
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq 'http://example.com/node.msi' } -Times 1
    }

    It 'does nothing when InstallNode is $false' {
        $config = @{ Node_Dependencies = @{ InstallNode = $false } }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command {}

        . $core

        Install-NodeCore -Config $config
        Assert-MockNotCalled Invoke-WebRequest
        Assert-MockNotCalled Start-Process
        Assert-MockNotCalled Remove-Item
    }

    It 'installs packages based on Node_Dependencies flags' {
        $config = @{ Node_Dependencies = @{ InstallYarn=$true; InstallVite=$false; InstallNodemon=$true } }
        Mock Get-Command { @{Name='npm'} } -ParameterFilter { $Name -eq 'npm' }
        function npm {
            param([string[]]$testArgs)
            $null = $testArgs
        }
        Mock npm {}
        . $global

        Install-NodeGlobalPackages -Config $config
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','yarn') } -Times 1
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','nodemon') } -Times 1
        Assert-MockNotCalled npm -ParameterFilter { $testArgs -eq @('install','-g','vite') }
    }

    It 'honours -WhatIf for Install-GlobalPackage' {
    
        . $global

        Install-NodeGlobalPackages -Config @{ Node_Dependencies = @{ InstallYarn=$false; InstallVite=$false; InstallNodemon=$false } }
        function npm { param([string[]]$testArgs) }
        Mock npm {}
        Install-GlobalPackage 'yarn' -WhatIf
        Assert-MockNotCalled npm
    }

    It 'uses NpmPath from Node_Dependencies when installing project deps' {
        $temp = Join-Path $env:TEMP ([System.Guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null
        New-Item -ItemType File -Path (Join-Path $temp 'package.json') | Out-Null
        $config = @{ Node_Dependencies = @{ NpmPath = $temp } }
        function npm {
            param([string[]]$testArgs)
            $null = $testArgs
        }
        Mock npm {}
        
        . $npm

        Install-NpmDependencies -Config $config
        Assert-MockCalled npm -ParameterFilter { $testArgs[0] -eq 'install' } -Times 1
        Remove-Item -Recurse -Force $temp
    }

    AfterAll {
        Remove-Item -Recurse -Force $env:TEMP -ErrorAction SilentlyContinue
    }
}

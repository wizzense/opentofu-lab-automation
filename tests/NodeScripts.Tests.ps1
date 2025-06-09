Describe 'Node installation scripts' {
    $scriptRoot = Join-Path $PSScriptRoot '..' 'runner_scripts'
    $core = Join-Path $scriptRoot '0201_Install-NodeCore.ps1'
    $global = Join-Path $scriptRoot '0202_Install-NodeGlobalPackages.ps1'
    $npm = Join-Path $scriptRoot '0203_Install-npm.ps1'

    BeforeAll {
        $env:TEMP = Join-Path ([System.IO.Path]::GetTempPath()) 'pester-temp'
        New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
    }

    It 'uses Node_Dependencies.Node.InstallerUrl when installing Node' {
        $config = @{ Node_Dependencies = @{ InstallNode=$true; Node = @{ InstallerUrl = 'http://example.com/node.msi' } } }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command { @{Name='node'} } -ParameterFilter { $Name -eq 'node' }
        & (Resolve-Path $core) -Config $config
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq 'http://example.com/node.msi' } -Times 1
    }

    It 'does nothing when InstallNode is $false' {
        $config = @{ Node_Dependencies = @{ InstallNode = $false } }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command {}
        & (Resolve-Path $core) -Config $config
        Assert-MockNotCalled Invoke-WebRequest
        Assert-MockNotCalled Start-Process
        Assert-MockNotCalled Remove-Item
    }

    It 'installs packages based on Node_Dependencies flags' {
        $config = @{ Node_Dependencies = @{ InstallYarn=$true; InstallVite=$false; InstallNodemon=$true } }
        Mock Get-Command { @{Name='npm'} } -ParameterFilter { $Name -eq 'npm' }
        function npm { param([string[]]$testArgs) }
        Mock npm {}
        & (Resolve-Path $global) -Config $config
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','yarn') } -Times 1
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','nodemon') } -Times 1
        Assert-MockNotCalled npm -ParameterFilter { $testArgs -eq @('install','-g','vite') }
    }

    It 'honours -WhatIf for Install-GlobalPackage' {
        . (Resolve-Path $global)
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
        function npm { param([string[]]$testArgs) }
        Mock npm {}
        & (Resolve-Path $npm) -Config $config
        Assert-MockCalled npm -ParameterFilter { $testArgs[0] -eq 'install' } -Times 1
        Remove-Item -Recurse -Force $temp
    }

    AfterAll {
        Remove-Item -Recurse -Force $env:TEMP -ErrorAction SilentlyContinue
    }
}

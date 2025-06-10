. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe 'Node installation scripts' {
    BeforeAll {

        $script:scriptRoot = Join-Path $PSScriptRoot '..' 'runner_scripts'
        $script:core   = (Resolve-Path -ErrorAction Stop (Join-Path $script:scriptRoot '0201_Install-NodeCore.ps1')).Path
        $script:global = (Resolve-Path -ErrorAction Stop (Join-Path $script:scriptRoot '0202_Install-NodeGlobalPackages.ps1')).Path
        $script:npm    = (Resolve-Path -ErrorAction Stop (Join-Path $script:scriptRoot '0203_Install-npm.ps1')).Path
        $env:TEMP = Join-Path ([System.IO.Path]::GetTempPath()) 'pester-temp'
        New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
    }

    It 'resolves script paths from the tests directory' {
        $core   = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0201_Install-NodeCore.ps1')).Path
        $global = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0202_Install-NodeGlobalPackages.ps1')).Path
        $npm    = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0203_Install-npm.ps1')).Path
        Test-Path $core | Should -BeTrue
        Test-Path $global | Should -BeTrue
        Test-Path $npm   | Should -BeTrue
    }

    It 'uses Node_Dependencies.Node.InstallerUrl when installing Node' {
        $cfg = @{ Node_Dependencies = @{ InstallNode=$true; Node = @{ InstallerUrl = 'http://example.com/node.msi' } } }
        $core = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0201_Install-NodeCore.ps1')).Path
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command { @{Name='node'} } -ParameterFilter { $Name -eq 'node' }
        . $core -Config $config

        Install-NodeCore -Config $cfg
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq 'http://example.com/node.msi' } -Times 1
    }

    It 'does nothing when InstallNode is $false' {
        $cfg = @{ Node_Dependencies = @{ InstallNode = $false } }
        $core = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0201_Install-NodeCore.ps1')).Path
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command {}

        . $core -Config $config

        Install-NodeCore -Config $cfg
        Should -Invoke -CommandName Invoke-WebRequest -Times 0
        Should -Invoke -CommandName Start-Process -Times 0
        Should -Invoke -CommandName Remove-Item -Times 0
    }

    It 'installs packages listed under GlobalPackages' -Skip:(Get-Command npm -ErrorAction SilentlyContinue | ForEach-Object { $true }) {
        $cfg = @{ Node_Dependencies = @{ GlobalPackages = @('yarn','nodemon') } }
        $global = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0202_Install-NodeGlobalPackages.ps1')).Path
        Mock Get-Command { @{Name='npm'} } -ParameterFilter { $Name -eq 'npm' }
        function npm {
            param([string[]]$testArgs)
            $null = $testArgs
        }
        . $global -Config $config
        Mock npm {}
        $WhatIfPreference = $false
        Install-NodeGlobalPackages -Config $cfg
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','yarn') } -Times 1
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','nodemon') } -Times 1
        Should -Invoke -CommandName npm -Times 0 -ParameterFilter { $testArgs -eq @('install','-g','vite') }
    }

    It 'falls back to boolean flags when GlobalPackages is missing' -Skip:(Get-Command npm -ErrorAction SilentlyContinue | ForEach-Object { $true }) {
        $cfg = @{ Node_Dependencies = @{ InstallYarn=$true; InstallVite=$false; InstallNodemon=$true } }
        $global = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0202_Install-NodeGlobalPackages.ps1')).Path
        Mock Get-Command { @{Name='npm'} } -ParameterFilter { $Name -eq 'npm' }
        function npm {
            param([string[]]$testArgs)
            $null = $testArgs
        }
        . $global -Config $config
        Mock npm {}
        $WhatIfPreference = $false
        Install-NodeGlobalPackages -Config $cfg
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','yarn') } -Times 1
        Assert-MockCalled npm -ParameterFilter { $testArgs -eq @('install','-g','nodemon') } -Times 1
        Should -Invoke -CommandName npm -Times 0 -ParameterFilter { $testArgs -eq @('install','-g','vite') }
    }

    It 'honours -WhatIf for Install-GlobalPackage' {
    
        $global = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0202_Install-NodeGlobalPackages.ps1')).Path

        function npm { param([string[]]$testArgs) }
        Mock npm {}
        . $global
        Install-NodeGlobalPackages -Config @{ Node_Dependencies = @{ InstallYarn=$false; InstallVite=$false; InstallNodemon=$false } } -WhatIf
        Should -Invoke -CommandName npm -Times 0
    }

    It 'uses NpmPath from Node_Dependencies when installing project deps' {
        $temp = Join-Path $env:TEMP ([System.Guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null
        New-Item -ItemType File -Path (Join-Path $temp 'package.json') | Out-Null
        $cfg = @{ Node_Dependencies = @{ NpmPath = $temp } }
        function npm {
            param([string[]]$testArgs)
            $null = $testArgs
        }
        $npmPath = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_scripts' '0203_Install-npm.ps1')).Path
        Mock npm {}

        . $npmPath -Config $config

        Install-NpmDependencies -Config $cfg
        Assert-MockCalled npm -ParameterFilter { $testArgs[0] -eq 'install' } -Times 1
        Remove-Item -Recurse -Force $temp
    }

    AfterAll {
        Remove-Item -Recurse -Force $env:TEMP -ErrorAction SilentlyContinue
    }
}

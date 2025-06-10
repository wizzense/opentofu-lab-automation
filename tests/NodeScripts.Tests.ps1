. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe 'Node installation scripts' {
    BeforeAll {

        $script:nodeScripts = @(
            '0201_Install-NodeCore.ps1'
            '0202_Install-NodeGlobalPackages.ps1'
            '0203_Install-npm.ps1'
        )
        $script:core   = Get-RunnerScriptPath $script:nodeScripts[0]
        $script:global = Get-RunnerScriptPath $script:nodeScripts[1]
        $script:npm    = Get-RunnerScriptPath $script:nodeScripts[2]
        $script:origTemp = $env:TEMP
        $env:TEMP = Join-Path ([System.IO.Path]::GetTempPath()) 'pester-temp'
        New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
        $script:config = [pscustomobject]@{}
    }

    It 'resolves script paths from the tests directory' -TestCases $script:nodeScripts {
        param($scriptName)
        $path = Get-RunnerScriptPath $scriptName
        Test-Path $path | Should -BeTrue
    }

    It 'uses Node_Dependencies.Node.InstallerUrl when installing Node' {
        $cfg = @{ Node_Dependencies = @{ InstallNode=$true; Node = @{ InstallerUrl = 'http://example.com/node.msi' } } }
        $core = Get-RunnerScriptPath '0201_Install-NodeCore.ps1'
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command { @{Name='node'} } -ParameterFilter { $Name -eq 'node' }
        . $core

        Install-NodeCore -Config $cfg
        Should -Invoke -CommandName Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -eq 'http://example.com/node.msi' }
    }

    It 'does nothing when InstallNode is $false' {
        $cfg = @{ Node_Dependencies = @{ InstallNode = $false } }
        $core = Get-RunnerScriptPath '0201_Install-NodeCore.ps1'
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Remove-Item {}
        Mock Get-Command {}

        . $core

        Install-NodeCore -Config $cfg
        Should -Invoke -CommandName Invoke-WebRequest -Times 0
        Should -Invoke -CommandName Start-Process -Times 0
        Should -Invoke -CommandName Remove-Item -Times 0
    }

    It 'installs packages listed under GlobalPackages' -Skip:(Get-Command npm -ErrorAction SilentlyContinue | ForEach-Object { $true }) {
        $cfg = @{ Node_Dependencies = @{ GlobalPackages = @('yarn','nodemon') } }
        $global = Get-RunnerScriptPath '0202_Install-NodeGlobalPackages.ps1'
        Mock Get-Command { @{Name='npm'} } -ParameterFilter { $Name -eq 'npm' }
        function npm {
            param([Parameter(ValueFromRemainingArguments = $true)][string[]]$testArgs)
            $null = $testArgs
        }
        . $global
        Mock npm {}
        $WhatIfPreference = $false
        Install-NodeGlobalPackages -Config $cfg
        Should -Invoke -CommandName npm -Times 1 -ParameterFilter { ($testArgs -join ' ') -eq 'install -g yarn' }
        Should -Invoke -CommandName npm -Times 1 -ParameterFilter { ($testArgs -join ' ') -eq 'install -g nodemon' }
        Should -Invoke -CommandName npm -Times 0 -ParameterFilter { ($testArgs -join ' ') -eq 'install -g vite' }
    }

    It 'falls back to boolean flags when GlobalPackages is missing' -Skip:(Get-Command npm -ErrorAction SilentlyContinue | ForEach-Object { $true }) {
        $cfg = @{ Node_Dependencies = @{ InstallYarn=$true; InstallVite=$false; InstallNodemon=$true } }
        $global = Get-RunnerScriptPath '0202_Install-NodeGlobalPackages.ps1'
        Mock Get-Command { @{Name='npm'} } -ParameterFilter { $Name -eq 'npm' }
        function npm {
            param([Parameter(ValueFromRemainingArguments = $true)][string[]]$testArgs)
            $null = $testArgs
        }
        . $global
        Mock npm {}
        $WhatIfPreference = $false
        Install-NodeGlobalPackages -Config $cfg
        Should -Invoke -CommandName npm -Times 1 -ParameterFilter { ($testArgs -join ' ') -eq 'install -g yarn' }
        Should -Invoke -CommandName npm -Times 1 -ParameterFilter { ($testArgs -join ' ') -eq 'install -g nodemon' }
        Should -Invoke -CommandName npm -Times 0 -ParameterFilter { ($testArgs -join ' ') -eq 'install -g vite' }
    }

    It 'logs start message when running each node script' -TestCases $script:nodeScripts {
        param($scriptName)

        $path = Get-RunnerScriptPath $scriptName
        Mock-WriteLog
        . $path

        switch ($scriptName) {
            '0201_Install-NodeCore.ps1'            { Install-NodeCore -Config $script:config }
            '0202_Install-NodeGlobalPackages.ps1' { Install-NodeGlobalPackages -Config $script:config }
            '0203_Install-npm.ps1'                { Install-NpmDependencies -Config $script:config }
        }

        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq "Running $scriptName" }
    }

    It 'honours -WhatIf for Install-GlobalPackage' {
    
        $global = Get-RunnerScriptPath '0202_Install-NodeGlobalPackages.ps1'

        function npm { param([Parameter(ValueFromRemainingArguments = $true)][string[]]$testArgs) }
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
            param([Parameter(ValueFromRemainingArguments = $true)][string[]]$testArgs)
            $null = $testArgs
        }
        $npmPath = Get-RunnerScriptPath '0203_Install-npm.ps1'
        Mock npm {}


        . $npmPath -Config $cfg

        # Dot-source the script with a minimal config object
        $config = [pscustomobject]@{}

        . $npmPath -Config $config

        Install-NpmDependencies -Config $cfg
        Should -Invoke -CommandName npm -Times 1 -ParameterFilter { $testArgs[0] -eq 'install' }
        Remove-Item -Recurse -Force $temp
    }

    AfterAll {
        Remove-Item -Recurse -Force $env:TEMP -ErrorAction SilentlyContinue
        $env:TEMP = $script:origTemp
    }
}

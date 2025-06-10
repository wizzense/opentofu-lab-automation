. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0203_Install-npm' {
    AfterEach {
        Remove-Item Function:npm -ErrorAction SilentlyContinue
    }
    It 'runs npm install in configured NpmPath' {
        $script = Get-RunnerScriptPath '0203_Install-npm.ps1'
        $npmDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $npmDir
        '{}' | Set-Content -Path (Join-Path $npmDir 'package.json')
        $cfg = @{ Node_Dependencies = @{ NpmPath = $npmDir } }

        $script:calledPath = $null
        function global:npm {
            param([string[]]$NpmArgs)
            $script:calledPath = (Get-Location).Path
            $null = $NpmArgs
        }


        . $script -Config $cfg
        Install-NpmDependencies -Config $cfg

        $script:calledPath | Should -Be (Get-Item $npmDir).FullName

        Remove-Item -Recurse -Force $npmDir
    }

    It 'succeeds when NpmPath exists' {
        $script = Get-RunnerScriptPath '0203_Install-npm.ps1'
        $npmDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $npmDir
        '{}' | Set-Content -Path (Join-Path $npmDir 'package.json')
        $cfg = @{ Node_Dependencies = @{ NpmPath = $npmDir } }

        function global:npm {
            param([string[]]$testArgs)
            $null = $testArgs
        }

        . $script -Config $cfg
        Install-NpmDependencies -Config $cfg
        $success = $?

        $success | Should -BeTrue

        Remove-Item -Recurse -Force $npmDir
    }

    It 'errors when NpmPath is missing and CreateNpmPath is false' {
        $script = Get-RunnerScriptPath '0203_Install-npm.ps1'
        $npmDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $cfg = @{ Node_Dependencies = @{ NpmPath = $npmDir; CreateNpmPath = $false } }

        $script:called = $false
        function global:npm { $script:called = $true }

        . $script -Config $cfg
        { Install-NpmDependencies -Config $cfg } | Should -Throw
        $script:called | Should -BeFalse
    }

    It 'errors when NpmPath is empty string' {
        $script = Get-RunnerScriptPath '0203_Install-npm.ps1'
        $cfg = @{ Node_Dependencies = @{ NpmPath = ''; CreateNpmPath = $false } }

        $script:called = $false
        function global:npm { $script:called = $true }

        . $script -Config $cfg
        { Install-NpmDependencies -Config $cfg } | Should -Throw
        $script:called | Should -BeFalse
    }

    It 'creates NpmPath when CreateNpmPath is true' {
        $script = Get-RunnerScriptPath '0203_Install-npm.ps1'
        $npmDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $cfg = @{ Node_Dependencies = @{ NpmPath = $npmDir; CreateNpmPath = $true } }

        $script:calledPath = $null
        function global:npm { param([string[]]$Args) $script:calledPath = (Get-Location).Path }

        . $script -Config $cfg
        Install-NpmDependencies -Config $cfg

        $script:calledPath | Should -Be (Get-Item $npmDir).FullName
        Test-Path $npmDir | Should -BeTrue

        Remove-Item -Recurse -Force $npmDir
    }
}

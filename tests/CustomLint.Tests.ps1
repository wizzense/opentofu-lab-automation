



# Simple PSScriptAnalyzer import
Import-Module PSScriptAnalyzer -Force

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')

Describe 'CustomLint.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'tools' 'iso' 'CustomLint.ps1'
    }
        It 'parses without errors' {
        $errs = $null
        [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errs) | Out-Null
        $(if ($errs) { $errs.Count  } else { 0 }) | Should -Be 0
    }
        It 'returns exit code 1 when analyzer reports errors' {
        Mock Invoke-ScriptAnalyzer { [pscustomobject]@{ Severity = 'Error' } }
        & $script:ScriptPath -Target $PSScriptRoot > $null
        $LASTEXITCODE | Should -Be 1
    }
        It 'fails when Invoke-WebRequest mock lacks ParameterFilter' {
        Mock Invoke-ScriptAnalyzer { @() }
        $temp = Join-Path $TestDrive 'bad.ps1'
        "Mock Invoke-WebRequest {}" | Set-Content $temp
        & $script:ScriptPath -Target $TestDrive > $null
        $LASTEXITCODE | Should -Be 1
    }
        It 'returns exit code 0 when no errors' {
        Mock Invoke-ScriptAnalyzer { @() }
        $goodDir = Join-Path $TestDrive 'clean'
        New-Item -ItemType Directory -Path $goodDir | Out-Null
        $good = Join-Path $goodDir 'good.ps1'
        'Write-Host hello' | Set-Content $good
        & $script:ScriptPath -Target $goodDir > $null
        $LASTEXITCODE | Should -Be 0
    }
}





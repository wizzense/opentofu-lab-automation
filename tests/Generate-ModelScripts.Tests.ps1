Describe 'GitHub model runner scripts' {
    BeforeAll {
        $runnerDir = Join-Path $PSScriptRoot '..'
        $script15 = Join-Path $runnerDir 'runner_scripts' '0015_Generate-ConfigFromPrompt.ps1'
        $script16 = Join-Path $runnerDir 'runner_scripts' '0016_Generate-Docs.ps1'
        $labUtils  = Join-Path $runnerDir 'lab_utils'
        $utilDir   = Join-Path $runnerDir 'runner_utility_scripts'
        $configDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $configDir | Out-Null
        Copy-Item (Join-Path $runnerDir 'config_files') -Destination $configDir -Recurse
        $script:temp = $configDir
        $script:script15 = $script15
        $script:script16 = $script16
        $script:labUtils  = $labUtils
        $script:utilDir   = $utilDir
    }

    AfterAll {
        Remove-Item -Recurse -Force $script:temp
    }

    It 'creates generated config file' {
        $dest = Join-Path $script:temp 'config_files'
        Copy-Item $script:script15 -Destination $script:temp
        Copy-Item $script:labUtils -Destination $script:temp -Recurse
        Copy-Item $script:utilDir -Destination $script:temp -Recurse
        Push-Location $script:temp
        Mock Invoke-GHModel { 'config-json' }
        & ./0015_Generate-ConfigFromPrompt.ps1 -Config @{} -Prompt 'p'
        Pop-Location
        $outFile = Join-Path $dest 'generated-config.json'
        (Get-Content -Raw $outFile) | Should -Be 'config-json'
    }

    It 'appends docs to README' {
        $dest = $script:temp
        Copy-Item $script:script16 -Destination $dest
        Copy-Item $script:labUtils -Destination $dest -Recurse
        Copy-Item $script:utilDir -Destination $dest -Recurse
        Set-Content -Path (Join-Path $dest 'README.md') -Value 'base'
        Push-Location $dest
        Mock Invoke-GHModel { 'added text' }
        & ./0016_Generate-Docs.ps1 -Config @{} -Prompt 'p'
        Pop-Location
        $readme = Get-Content -Raw (Join-Path $dest 'README.md')
        $readme | Should -Match 'added text'
    }
}

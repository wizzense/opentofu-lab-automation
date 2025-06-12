$helperPath = Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1'
if (-not (Test-Path $helperPath)) {
    throw "Required helper script is missing: $helperPath"
}

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')


$scriptDir = Split-Path (Get-RunnerScriptPath '0001_Reset-Git.ps1')
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'

Describe 'Runner scripts parameter and command checks'  {

    BeforeAll {
        . (Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1')
    }


    $mandatory = @('Write-CustomLog')
    $testCases = $scripts | ForEach-Object {
        @{ Name = $_.Name; File = $_; Commands = $mandatory }
    }

    It 'parses without errors' -TestCases $testCases {
        param($File)
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$errors) | Out-Null
        ($errors ? $errors.Count : 0) | Should -Be 0
    }

    It 'declares a Config parameter when required' -TestCases $testCases {
        param($File, $Commands)
        $ast = Get-ScriptAst $File.FullName
        $paramBlock = $ast.ParamBlock
        $configParam = $null
        if ($paramBlock) {
            $configParam = $paramBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Config' }
        }
        
        if (-not $configParam) {
            Write-Host "No Config parameter found in $($File.FullName)"
        }
        $configParam | Should -Not -BeNullOrEmpty
    }

    It 'contains mandatory command invocations' -TestCases $testCases {
        param($File, $Commands)
        $ast = Get-ScriptAst $File.FullName
        $scriptCommands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
        
        foreach ($cmdName in $Commands) {
            $found = $scriptCommands | Where-Object { $_.GetCommandName() -eq $cmdName }
            if (-not $found) {
                Write-Host "Command '$cmdName' not found in $($File.FullName)"
            }
            ($found | Measure-Object).Count | Should -BeGreaterThan 0
        }
    }

    It 'contains Invoke-LabStep call' -TestCases $testCases {
        param($File, $Commands)
        $ast = Get-ScriptAst $File.FullName
        $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
        $found = $commands | Where-Object { $_.GetCommandName() -eq 'Invoke-LabStep' }
        if (-not $found) {
            Write-Host "Invoke-LabStep not found in $($File.FullName)"
        }
        ($found | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It 'imports LabRunner module' -TestCases $testCases {
        param($File)
        $ast = Get-ScriptAst $File.FullName
        $commands = if ($ast) {
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
        } else { @() }

        $foundImport = $commands | Where-Object {
            $_.GetCommandName() -eq 'Import-Module' -and
            $_.CommandElements.Count -ge 2
        } | ForEach-Object {
            $modulePathElement = $_.CommandElements[1]
            $forceSwitch = $_.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'Force'}

            $modulePathValue = $null
            if ($modulePathElement -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $modulePathValue = $modulePathElement.Value
            } elseif ($modulePathElement -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                if ($modulePathElement.Value -match '\\$PSScriptRoot') {
                    $scriptDirectory = Split-Path $File.FullName
                    try {
                        $resolvedPath = $ExecutionContext.InvokeCommand.ExpandString($modulePathElement.Value.Replace('$PSScriptRoot', "'$scriptDirectory'"))
                        $modulePathValue = $resolvedPath
                    } catch {
                        $modulePathValue = $modulePathElement.Value 
                    }
                } else {
                    $modulePathValue = $modulePathElement.Value
                }
            }
            
            if ($null -ne $modulePathValue -and 
                ([System.IO.Path]::GetFileName($modulePathValue) -in @('LabRunner.psm1', 'LabRunner.psd1')) -and
                $forceSwitch) {
                return $_ 
            }
            return $null 
        } | Where-Object { $null -ne $_ }

        if (-not $foundImport) {
            Write-Host "LabRunner module not imported correctly (expected specific path and -Force) in $($File.FullName)"
        }

        ($foundImport | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It 'resolves PSScriptRoot when run with pwsh -File' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        try {
            $dummy = Join-Path $tempDir 'dummy.ps1'
            # Ensure the here-string content is valid PowerShell
            $scriptContent = @"
Param([pscustomobject]`$Config)
`$env:LAB_CONSOLE_LEVEL = '0';
Import-Module LabRunner;
Invoke-LabStep -Config `$Config -Body { Write-Output `$PSScriptRoot }
"@
            $scriptContent | Set-Content -Path $dummy -Encoding UTF8NoBOM # Specify encoding

            $pwsh = (Get-Command pwsh).Source
            $result = & $pwsh -NoLogo -NoProfile -File $dummy -Config @{}
            $expected = Split-Path $dummy -Parent # PSScriptRoot should be the directory of the script
            
            # Normalize line endings and trim whitespace for comparison
            $normalizedResult = ($result | Out-String).Trim() -replace "\\r\\n", "\\n"
            $normalizedExpected = $expected.Trim() -replace "\\r\\n", "\\n"

            $normalizedResult | Should -Be $normalizedExpected
        }
        finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }
}

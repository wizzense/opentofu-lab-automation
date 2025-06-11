. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0112_Enable-PXE' -Skip:$SkipNonWindows {
    BeforeAll {
        $script:scriptPath = Get-RunnerScriptPath '0112_Enable-PXE.ps1'
        $loggerPath = Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'LabRunner' 'Logger.ps1'
        . $loggerPath
    }

    It 'logs firewall rules when ConfigPXE is true'  {
        $Config = [pscustomobject]@{ ConfigPXE = $true }
        $logPath = Join-Path $env:TEMP ('pxe-log-' + [System.Guid]::NewGuid().ToString() + '.txt')
        $script:LogFilePath = $logPath
        try {
            . $script:scriptPath -Config $Config | Out-Null
            (Test-Path $logPath) | Should -BeTrue
            $log = Get-Content -Raw $logPath
            $log | Should -Match 'prov-pxe-67'
            $log | Should -Match 'prov-pxe-69'
            $log | Should -Match 'prov-pxe-17519'
            $log | Should -Match 'prov-pxe-17530'
        } finally {
            Remove-Item $logPath -ErrorAction SilentlyContinue
            Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        }
    }
}


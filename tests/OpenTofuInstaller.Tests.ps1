Describe 'OpenTofuInstaller error handling' {
    It 'returns install failed exit code when cosign is missing' {
        $scriptPath = Join-Path $PSScriptRoot '..\runner_utility_scripts\OpenTofuInstaller.ps1'
        $arguments = @(
            '-NoLogo',
            '-NoProfile',
            '-File', $scriptPath,
            '-installMethod', 'standalone',
            '-cosignPath', 'nonexistent.exe',
            '-gpgPath', 'nonexistent.exe'
        )
        $proc = Start-Process pwsh -ArgumentList $arguments -Wait -PassThru
        $proc.ExitCode | Should -Be 2
    }
}

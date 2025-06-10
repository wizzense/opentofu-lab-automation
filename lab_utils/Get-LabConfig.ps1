function Get-LabConfig {
    [CmdletBinding()]
    param(

        [string]$Path = (Join-Path $PSScriptRoot '..\config_files\default-config.json')
    )

    if (-not (Test-Path $Path)) {
        throw "Config file not found at $Path"
    }

    try {

        $content = Get-Content -Raw -Path $Path
        if ($Path -match '\.ya?ml$') {
            if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
                try {
                    Import-Module powershell-yaml -ErrorAction Stop
                }
                catch {
                    throw "YAML support requires the 'powershell-yaml' module. Install it with 'Install-Module powershell-yaml'."
                }
            }
            $config = $content | ConvertFrom-Yaml
        }
        else {
            $config = $content | ConvertFrom-Json
        }

        $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
        $dirs = [pscustomobject]@{
            RepoRoot       = $repoRoot.Path
            RunnerScripts  = Join-Path $repoRoot 'runner_scripts'
            UtilityScripts = Join-Path $repoRoot 'runner_utility_scripts'
            ConfigFiles    = Join-Path $repoRoot 'config_files'
            InfraRepo      = if ($config.InfraRepoPath) { $config.InfraRepoPath } else { 'C:\\Temp\\base-infra' }
        }
        Add-Member -InputObject $config -MemberType NoteProperty -Name Directories -Value $dirs -Force
        return $config
    }
    catch {
        throw "Failed to parse config file $Path. $_"


    }
}

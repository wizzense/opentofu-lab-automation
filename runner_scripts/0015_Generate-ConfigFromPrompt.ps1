Param(
    [pscustomobject]$Config,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Prompt,
    [string]$Model = 'llama3-8b'
)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
. "$PSScriptRoot/../lab_utils/Invoke-GHModel.ps1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Generating configuration via GitHub model $Model"
    $text = Invoke-GHModel -Model $Model -Prompt $Prompt
    $outFile = Join-Path $PSScriptRoot '..' 'config_files' 'generated-config.json'
    $text | Out-File -FilePath $outFile -Encoding utf8
    Write-CustomLog "Saved configuration to $outFile"
}

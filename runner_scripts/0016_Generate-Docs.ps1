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
    Write-CustomLog "Generating documentation via GitHub model $Model"
    $text = Invoke-GHModel -Model $Model -Prompt $Prompt
    $readme = Join-Path $PSScriptRoot '..' 'README.md'
    if (Test-Path $readme) {
        Add-Content -Path $readme -Value "`n$text"
        Write-CustomLog "Updated README.md with model output"
    } else {
        Write-CustomLog "README.md not found at $readme"
    }
}

function Invoke-GHModel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Model,

        [Parameter(Mandatory)]
        [string]$Prompt,

        [hashtable]$Parameters
    )

    $token = $env:GITHUB_MODEL_TOKEN
    if (-not $token) { throw 'GITHUB_MODEL_TOKEN is not set' }

    $headers = @{
        Authorization       = "Bearer $token"
        Accept              = 'application/json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    $body = @{ prompt = $Prompt }
    if ($Parameters) { $body.parameters = $Parameters }

    $uri = "https://api.github.com/ai/model-inference/$Model"
    $json = $body | ConvertTo-Json -Depth 5
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json

    return $response.choices[0].message.content
}

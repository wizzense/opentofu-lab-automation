function Invoke-LabWebRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Uri,
        [string]$OutFile,
        [switch]$UseBasicParsing
    )
    Invoke-WebRequest @PSBoundParameters
}

function Invoke-LabNpm {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )
    npm @Args
}

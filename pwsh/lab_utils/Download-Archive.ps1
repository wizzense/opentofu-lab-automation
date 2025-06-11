function Download-Archive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination,
        [switch]$Required,
        [switch]$UseGh
    )

    if ($UseGh) {
        gh api $Url --output $Destination
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to download $(Split-Path $Destination -Leaf) artifact." -ForegroundColor Yellow
            if ($Required) {
                throw "Download failed for required artifact: $(Split-Path $Destination -Leaf)."
            }
        }
    }
    else {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
            if (-not $?) { throw }
        }
        catch {
            Write-Host "Failed to download $(Split-Path $Destination -Leaf) artifact anonymously." -ForegroundColor Yellow
            if ($Required) {
                throw "Download failed for required artifact: $(Split-Path $Destination -Leaf)."
            }
        }
    }
}

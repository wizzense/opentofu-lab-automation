function Format-Config {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [AllowNull()]
        [psobject]$Config
    )

    begin { $hasInput = $false }

    process {
        $hasInput = $true
        if ($null -eq $Config) {
            throw [System.ArgumentNullException]::new('Config')
        }

        # Serialize the configuration object to indented JSON so nested
        # properties are easier to read in the console output.  Depth 10
        # should be sufficient for our current config structure.
        $Config | ConvertTo-Json -Depth 10
    }

    end {
        if (-not $hasInput) {
            throw [System.ArgumentNullException]::new('Config')
        }
    }
}

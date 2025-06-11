function Format-Config {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [psobject]$Config
    )

    begin {
        $hasInput = $false
        if ($PSBoundParameters.ContainsKey('Config') -and $null -eq $Config) {
            throw [System.ArgumentNullException]::new('Config','Config cannot be null.')
        }
    }

    process {
        $hasInput = $true
        if ($null -eq $Config) {
            throw [System.ArgumentNullException]::new('Config','Config cannot be null.')
        }

        # Serialize the configuration object to indented JSON so nested
        # properties are easier to read in the console output.  Depth 10
        # should be sufficient for our current config structure.
        $Config | ConvertTo-Json -Depth 10
    }

    end {
        if (-not $hasInput) {
            throw [System.ArgumentException]::new(
                'A configuration object must be provided via -Config or the pipeline.',
                'Config'
            )
        }
    }
}

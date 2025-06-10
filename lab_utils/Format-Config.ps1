function Format-Config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [psobject]$Config
    )

    process {
        if ($null -eq $Config) {
            throw [System.ArgumentNullException]::new('Config')
        }

        # Serialize the configuration object to indented JSON so nested
        # properties are easier to read in the console output.  Depth 10
        # should be sufficient for our current config structure.
        $Config | ConvertTo-Json -Depth 10
    }
}

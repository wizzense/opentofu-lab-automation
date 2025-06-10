function Format-Config {
    param(
        [pscustomobject]$Config
    )

    if ($null -eq $Config) {
        throw [System.ArgumentNullException]::new('Config')
    }

    # Serialize the configuration object to indented JSON so nested
    # properties are easier to read in the console output.  Depth 10
    # should be sufficient for our current config structure.
    $json = $Config | ConvertTo-Json -Depth 10
    return $json
}

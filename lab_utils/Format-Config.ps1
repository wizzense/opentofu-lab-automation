function Format-Config {
    param(
        [pscustomobject]$Config
    )
    $lines = foreach ($prop in $Config.PSObject.Properties) {
        "{0}: {1}" -f $prop.Name, $prop.Value
    }
    return $lines -join "`n"
}

param(
    [string]$ConfigFile = "./config_files/default-config.json",
    [switch]$AutoAccept,
    [string]$RunScripts
)

# Load logging helper
. "$PSScriptRoot\runner_utility_scripts\Logger.ps1"

function ConvertTo-Hashtable {
    param(
        $obj
    )
    if ($obj -is [System.Collections.IDictionary]) {
        $ht = @{}
        foreach ($key in $obj.Keys) {
            $ht[$key] = ConvertTo-Hashtable $obj[$key]
        }
        return $ht
    }
    elseif ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [string])) {
        $arr = @()
        foreach ($item in $obj) {
            $arr += ConvertTo-Hashtable $item
        }
        return $arr
    }
    elseif ($obj -is [PSCustomObject]) {
        $ht = @{}
        foreach ($prop in $obj.PSObject.Properties) {
            $ht[$prop.Name] = ConvertTo-Hashtable $prop.Value
        }
        return $ht
    }
    else {
        return $obj
    }
}

function Customize-Config {
    param(
        [hashtable]$ConfigObject
    )
    Write-Log "Customize-Config functionality not implemented. Using existing configuration."
    return $ConfigObject
}

Write-Log "==== Loading configuration ===="
if (!(Test-Path $ConfigFile)) {
    Write-Log "ERROR: Cannot find config file at $ConfigFile"
    exit 1
}

try {
    $jsonContent = Get-Content -Path $ConfigFile -Raw
    $ConfigRaw = ConvertFrom-Json $jsonContent
    $Config = ConvertTo-Hashtable $ConfigRaw
} catch {
    Write-Log "ERROR: Failed to parse JSON from $ConfigFile. $_"
    exit 1
}

Write-Log "==== Current configuration ===="
$formattedConfig = $ConfigRaw | ConvertTo-Json -Depth 5
Write-Log $formattedConfig

# If not in AutoAccept mode, allow customization
if (-not $AutoAccept) {
    $customize = Read-Host "Would you like to customize your configuration? (Y/N)"
    if ($customize -match '^(?i)y') {
        $Config = Customize-Config -ConfigObject $Config
        # Save the updated configuration
        $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigFile -Encoding utf8
        Write-Log "Configuration updated and saved to $ConfigFile"
    }
}

Write-Log "==== Locating scripts ===="
$ScriptFiles = Get-ChildItem -Path .\runner_scripts -Filter "????_*.ps1" -File | Sort-Object -Property Name

if (!$ScriptFiles) {
    Write-Log "ERROR: No scripts found matching ????_*.ps1 in current directory."
    exit 1
}

Write-Log "`n==== Found the following scripts ===="
foreach ($Script in $ScriptFiles) {
    $prefix = $Script.Name.Substring(0,4)
    Write-Log "$prefix - $($Script.Name)"
}

# Determine scripts to run based on arguments
if ($RunScripts -eq 'all') {
    $ScriptsToRun = $ScriptFiles
} elseif ($RunScripts) {
    $selectedPrefixes = $RunScripts -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{4}$' }
    if (!$selectedPrefixes) {
        Write-Log "No valid 4-digit prefixes found in argument. Exiting."
        exit 1
    }
    $ScriptsToRun = $ScriptFiles | Where-Object {
        $prefix = $_.Name.Substring(0,4)
        $selectedPrefixes -contains $prefix
    }
    if (!$ScriptsToRun) {
        Write-Log "None of the provided prefixes match the scripts in the folder. Exiting."
        exit 1
    }
} else {
    # Interactive mode if no argument is given
    while ($true) {
        Write-Log "`nTo run ALL scripts, type 'all'."
        Write-Log "To run specific scripts, provide comma-separated 4-digit prefixes (e.g. 0001,0003)."
        Write-Log "Or type 'exit' to quit."
        $selection = Read-Host "Enter selection"

        if ($selection -match '^(?i)exit$') { break }

        if ($selection -eq 'all') {
            $ScriptsToRun = $ScriptFiles
        } else {
            $selectedPrefixes = $selection -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{4}$' }
            if (!$selectedPrefixes) {
                Write-Log "No valid 4-digit prefixes found. Please try again."
                continue
            }
            $ScriptsToRun = $ScriptFiles | Where-Object {
                $prefix = $_.Name.Substring(0,4)
                $selectedPrefixes -contains $prefix
            }
            if (!$ScriptsToRun) {
                Write-Log "None of the provided prefixes match the scripts in the folder. Please try again."
                continue
            }
        }
        break
    }
}

if ($ScriptsToRun) {
    Write-Log "`n==== Executing selected scripts ===="
    foreach ($Script in $ScriptsToRun) {
        Write-Log "`n--- Running: $($Script.Name) ---"
        try {
            & "$PSScriptRoot\runner_scripts\$($Script.Name)" -Config $Config
            if ($LASTEXITCODE -ne 0) {
                Write-Log "ERROR: $($Script.Name) exited with code $LASTEXITCODE."
                exit 1
            }
        }
        catch {
            Write-Log "ERROR: Exception in $($Script.Name). $_"
            exit 1
        }
    }
    Write-Log "`n==== Selected scripts execution completed! ===="
} else {
    Write-Log "No scripts selected to run."
}

Write-Log "`nAll done!"
exit 0

param(
    [string]$ConfigFile = "./config_files/default-config.json",
    [switch]$Auto,
    [string]$Scripts
)

# Load helpers
. "$PSScriptRoot\runner_utility_scripts\Logger.ps1"
. "$PSScriptRoot\lab_utils\Get-LabConfig.ps1"

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

    # Prompt the user for common install flags
    $installPrompts = @{
        InstallGit       = 'Install Git'
        InstallGo        = 'Install Go'
        InstallOpenTofu  = 'Install OpenTofu'
    }

    foreach ($key in $installPrompts.Keys) {
        $current = [bool]$ConfigObject[$key]
        $answer  = Read-Host "$($installPrompts[$key])? (Y/N) [$current]"
        if ($answer) {
            $ConfigObject[$key] = $answer -match '^(?i)y'
        }
    }

    # Prompt for key paths
    $localPath = Read-Host "Local repo path [`$($ConfigObject['LocalPath'])`]"
    if ($localPath) { $ConfigObject['LocalPath'] = $localPath }

    $npmPath = Read-Host "Path to Node project [`$($ConfigObject.Node_Dependencies.NpmPath)`]"
    if ($npmPath) { $ConfigObject.Node_Dependencies.NpmPath = $npmPath }

    return $ConfigObject
}

Write-CustomLog "==== Loading configuration ===="
try {
    $ConfigRaw = Get-LabConfig -Path $ConfigFile
    $Config = ConvertTo-Hashtable $ConfigRaw
} catch {
    Write-CustomLog "ERROR: $_"
    exit 1
}

Write-CustomLog "==== Current configuration ===="
$formattedConfig = $ConfigRaw | ConvertTo-Json -Depth 5
Write-CustomLog $formattedConfig

# If not in Auto mode, allow customization
if (-not $Auto) {
    $customize = Read-Host "Would you like to customize your configuration? (Y/N)"
    if ($customize -match '^(?i)y') {
        $Config = Customize-Config -ConfigObject $Config
        # Save the updated configuration
        $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigFile -Encoding utf8
        Write-CustomLog "Configuration updated and saved to $ConfigFile"
    }
}

Write-CustomLog "==== Locating scripts ===="
$ScriptFiles = Get-ChildItem -Path .\runner_scripts -Filter "????_*.ps1" -File | Sort-Object -Property Name

if (!$ScriptFiles) {
    Write-CustomLog "ERROR: No scripts found matching ????_*.ps1 in current directory."
    exit 1
}

Write-CustomLog "`n==== Found the following scripts ===="
foreach ($Script in $ScriptFiles) {
    $prefix = $Script.Name.Substring(0,4)
    Write-CustomLog "$prefix - $($Script.Name)"
}

# Determine scripts to run based on arguments
if ($Scripts -eq 'all') {
    $ScriptsToRun = $ScriptFiles
} elseif ($Scripts) {
    $selectedPrefixes = $Scripts -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{4}$' }
    if (!$selectedPrefixes) {
        Write-CustomLog "No valid 4-digit prefixes found in argument. Exiting."
        exit 1
    }
    $ScriptsToRun = $ScriptFiles | Where-Object {
        $prefix = $_.Name.Substring(0,4)
        $selectedPrefixes -contains $prefix
    }
    if (!$ScriptsToRun) {
        Write-CustomLog "None of the provided prefixes match the scripts in the folder. Exiting."
        exit 1
    }
} else {
    # Interactive mode if no argument is given
    while ($true) {
        Write-CustomLog "`nTo run ALL scripts, type 'all'."
        Write-CustomLog "To run specific scripts, provide comma-separated 4-digit prefixes (e.g. 0001,0003)."
        Write-CustomLog "Or type 'exit' to quit."
        $selection = Read-Host "Enter selection"

        if ($selection -match '^(?i)exit$') { break }

        if ($selection -eq 'all') {
            $ScriptsToRun = $ScriptFiles
        } else {
            $selectedPrefixes = $selection -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{4}$' }
            if (!$selectedPrefixes) {
                Write-CustomLog "No valid 4-digit prefixes found. Please try again."
                continue
            }
            $ScriptsToRun = $ScriptFiles | Where-Object {
                $prefix = $_.Name.Substring(0,4)
                $selectedPrefixes -contains $prefix
            }
            if (!$ScriptsToRun) {
                Write-CustomLog "None of the provided prefixes match the scripts in the folder. Please try again."
                continue
            }
        }
        break
    }
}

if ($ScriptsToRun) {
    Write-CustomLog "`n==== Executing selected scripts ===="
    foreach ($Script in $ScriptsToRun) {
        Write-CustomLog "`n--- Running: $($Script.Name) ---"
        try {
            & "$PSScriptRoot\runner_scripts\$($Script.Name)" -Config $Config
            if ($LASTEXITCODE -ne 0) {
                Write-CustomLog "ERROR: $($Script.Name) exited with code $LASTEXITCODE."
                exit 1
            }
        }
        catch {
            Write-CustomLog "ERROR: Exception in $($Script.Name). $_"
            exit 1
        }
    }
    Write-CustomLog "`n==== Selected scripts execution completed! ===="
} else {
    Write-CustomLog "No scripts selected to run."
}

Write-CustomLog "`nAll done!"
exit 0

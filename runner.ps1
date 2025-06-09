param(
    [string]$ConfigFile = "./config_files/default-config.json",
    [switch]$Auto,
    [string]$Scripts,
    [switch]$Force
)

# Load helpers
. "$PSScriptRoot\runner_utility_scripts\Logger.ps1"
. "$PSScriptRoot\lab_utils\Get-LabConfig.ps1"

# Set default log file path if none is defined
if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) -and
    -not (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue)) {
    $logDir = $env:LAB_LOG_DIR
    if (-not $logDir) {
        if ($IsWindows) { $logDir = 'C:\\temp' } else { $logDir = [System.IO.Path]::GetTempPath() }
    }
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $script:LogFilePath = Join-Path $logDir 'lab.log'
}

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

function Get-ScriptConfigFlag {
    param([string]$Path)
    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ($content -match '\$Config\.([A-Za-z0-9_\.]+)\s*-eq\s*\$true') {
        return $matches[1]
    }
    elseif ($content -match '\$config\.([A-Za-z0-9_\.]+)\s*-eq\s*\$true') {
        return $matches[1]
    }
    return $null
}

function Get-NestedConfigValue {
    param([hashtable]$Config, [string]$Path)
    $parts = $Path -split '\.'
    $cur = $Config
    foreach ($p in $parts) {
        if ($cur.ContainsKey($p)) { $cur = $cur[$p] } else { return $null }
    }
    return $cur
}

function Set-NestedConfigValue {
    param([hashtable]$Config, [string]$Path, [object]$Value)
    $parts = $Path -split '\.'
    $cur = $Config
    for ($i=0; $i -lt $parts.Length - 1; $i++) {
        $part = $parts[$i]
        if (-not $cur.ContainsKey($part)) { $cur[$part] = @{} }
        $cur = $cur[$part]
    }
    $cur[$parts[-1]] = $Value
}

function Set-LabConfig {
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
        $Config = Set-LabConfig -ConfigObject $Config
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

function Invoke-Scripts {
    param([array]$ScriptsToRun)

    if ($ScriptsToRun.Count -gt 1) {
        $cleanup = $ScriptsToRun | Where-Object { $_.Name.Substring(0,4) -eq '0000' }
        if ($cleanup) {
            Write-CustomLog "WARNING: Cleanup script 0000 will remove local files. Remaining scripts will be unavailable."
            if (-not $Auto) {
                $resp = Read-Host "Continue with cleanup and exit? (Y/N)"
                if ($resp -notmatch '^(?i)y') { Write-CustomLog 'Aborting per user request.'; return }
            }
            $ScriptsToRun = $cleanup
        }
    }

    if ($ScriptsToRun) {
        Write-CustomLog "`n==== Executing selected scripts ===="
        $failed = @()
        foreach ($Script in $ScriptsToRun) {
            Write-CustomLog "`n--- Running: $($Script.Name) ---"
            try {
                $scriptPath = "$PSScriptRoot\runner_scripts\$($Script.Name)"
                $flag = Get-ScriptConfigFlag -Path $scriptPath
                if ($flag) {
                    $current = Get-NestedConfigValue -Config $Config -Path $flag
                    if (-not $current) {
                        if ($Force) {
                            Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                        } elseif (-not $Auto) {
                            $ans = Read-Host "Flag '$flag' is disabled. Enable and run? (Y/N)"
                            if ($ans -match '^(?i)y') { Set-NestedConfigValue -Config $Config -Path $flag -Value $true }
                        }
                    }
                }

                $cmdInfo = Get-Command -Name $scriptPath -ErrorAction SilentlyContinue
                if ($cmdInfo -and $cmdInfo.Parameters.ContainsKey('Config')) {
                    & $scriptPath -Config $Config
                } else {
                    & $scriptPath
                }
                if ($LASTEXITCODE -ne 0) { Write-CustomLog "ERROR: $($Script.Name) exited with code $LASTEXITCODE."; $failed += $Script.Name }
                else { Write-CustomLog "$($Script.Name) completed successfully." }
            } catch {
                Write-CustomLog ("ERROR: Exception in $($Script.Name). {0}`n{1}" -f $PSItem.Exception.Message, $PSItem.ScriptStackTrace)
                $failed += $Script.Name
            }
        }
        $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigFile -Encoding utf8
        Write-CustomLog "`n==== Selected scripts execution completed! ===="
        if ($failed.Count -gt 0) { Write-CustomLog "Failures occurred in: $($failed -join ', ')"; return $false }
    } else {
        Write-CustomLog "No scripts selected to run."
    }
    return $true
}

function Select-Scripts {
    param([string]$Input)
    if ($Input -eq 'all') { return $ScriptFiles }
    $selectedPrefixes = $Input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{4}$' }
    if (!$selectedPrefixes) { Write-CustomLog "No valid 4-digit prefixes found."; return @() }
    $res = $ScriptFiles | Where-Object { $selectedPrefixes -contains $_.Name.Substring(0,4) }
    if (!$res) { Write-CustomLog "None of the provided prefixes match the scripts in the folder." }
    return $res
}

if ($Scripts -eq 'all' -or $Scripts) {
    $selected = if ($Scripts -eq 'all') { $ScriptFiles } else { Select-Scripts -Input $Scripts }
    if ($selected.Count -eq 0) { exit 1 }
    $ok = Invoke-Scripts -ScriptsToRun $selected
    exit (if ($ok) {0} else {1})
}

# Interactive mode
while ($true) {
    Write-CustomLog "`nTo run ALL scripts, type 'all'."
    Write-CustomLog "To run specific scripts, provide comma-separated 4-digit prefixes (e.g. 0001,0003)."
    Write-CustomLog "Or type 'exit' to quit."
    $selection = Read-Host "Enter selection"
    if ($selection -match '^(?i)exit$') { break }
    $chosen = Select-Scripts -Input $selection
    if ($chosen.Count -eq 0) { continue }
    $ok = Invoke-Scripts -ScriptsToRun $chosen
    if (-not $ok) { $LASTEXITCODE = 1 }
}

Write-CustomLog "`nAll done!"
exit $LASTEXITCODE


param(
    [string]$ConfigFile = "./config_files/default-config.json",
    [switch]$Auto,
    [string]$Scripts,
    [switch]$Force
)

# ─── Load helpers ──────────────────────────────────────────────────────────────
. "$PSScriptRoot\runner_utility_scripts\Logger.ps1"
. "$PSScriptRoot\lab_utils\Get-LabConfig.ps1"
. "$PSScriptRoot\lab_utils\Format-Config.ps1"
. "$PSScriptRoot\lab_utils\Menu.ps1"

# ─── Default log path ─────────────────────────────────────────────────────────
if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) -and
    -not (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue)) {

    $logDir = $env:LAB_LOG_DIR
    if (-not $logDir) { $logDir = $IsWindows ? 'C:\temp' : [System.IO.Path]::GetTempPath() }
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $script:LogFilePath = Join-Path $logDir 'lab.log'
}

# ─── Utility helpers ──────────────────────────────────────────────────────────
function ConvertTo-Hashtable {
    param($obj)
    switch ($obj) {
        { $_ -is [System.Collections.IDictionary] } {
            $ht = @{}
            foreach ($k in $_.Keys) { $ht[$k] = ConvertTo-Hashtable $_[$k] }
            return $ht
        }
        { $_ -is [System.Collections.IEnumerable] -and -not ($_ -is [string]) } {
            return $_ | ForEach-Object { ConvertTo-Hashtable $_ }
        }
        { $_ -is [PSCustomObject] } {
            $ht = @{}
            foreach ($p in $_.PSObject.Properties) { $ht[$p.Name] = ConvertTo-Hashtable $p.Value }
            return $ht
        }
        default { return $_ }
    }
}

function Get-ScriptConfigFlag {
    param([string]$Path)
    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ($content -match '\$Config\.([A-Za-z0-9_\.]+)\s*-eq\s*\$true') { return $matches[1] }
    if ($content -match '\$config\.([A-Za-z0-9_\.]+)\s*-eq\s*\$true') { return $matches[1] }
    return $null
}

function Get-NestedConfigValue {
    param([hashtable]$Config, [string]$Path)
    $parts = $Path -split '\.'
    $cur   = $Config
    foreach ($p in $parts) {
        if (-not $cur.ContainsKey($p)) { return $null }
        $cur = $cur[$p]
    }
    return $cur
}

function Set-NestedConfigValue {
    param([hashtable]$Config, [string]$Path, [object]$Value)
    $parts = $Path -split '\.'
    $cur   = $Config
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        if (-not $cur.ContainsKey($parts[$i])) { $cur[$parts[$i]] = @{} }
        $cur = $cur[$parts[$i]]
    }
    $cur[$parts[-1]] = $Value
}

function Set-LabConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$ConfigObject)

    $installPrompts = @{
        InstallGit      = 'Install Git'
        InstallGo       = 'Install Go'
        InstallOpenTofu = 'Install OpenTofu'
    }

    foreach ($k in $installPrompts.Keys) {
        $current = [bool]$ConfigObject[$k]
        $ans     = Read-Host "$($installPrompts[$k])? (Y/N) [$current]"
        if ($ans) { $ConfigObject[$k] = $ans -match '^(?i)y' }
    }

    $localPath = Read-Host "Local repo path [`$($ConfigObject.LocalPath)`]"
    if ($localPath) { $ConfigObject.LocalPath = $localPath }

    $npmPath = Read-Host "Path to Node project [`$($ConfigObject.Node_Dependencies.NpmPath)`]"
    if ($npmPath) { $ConfigObject.Node_Dependencies.NpmPath = $npmPath }
    $createPath = Read-Host "Create NpmPath if missing? (Y/N) [`$($ConfigObject.Node_Dependencies.CreateNpmPath)`]"
    if ($createPath) { $ConfigObject.Node_Dependencies.CreateNpmPath = $createPath -match '^(?i)y' }

    return $ConfigObject
}

# ─── Load configuration ───────────────────────────────────────────────────────
Write-CustomLog "==== Loading configuration ===="
try {
    $ConfigRaw = Get-LabConfig -Path $ConfigFile
    $Config    = ConvertTo-Hashtable $ConfigRaw
} catch {
    Write-CustomLog "ERROR: $_"
    exit 1
}

Write-CustomLog "==== Configuration summary ===="
Write-CustomLog (Format-Config -Config $ConfigRaw)

# ─── Optional customization ──────────────────────────────────────────────────
if (-not $Auto) {
    if ((Read-Host "Customize configuration? (Y/N)") -match '^(?i)y') {
        $Config = Set-LabConfig -ConfigObject $Config
        if ($PSCmdlet.ShouldProcess($ConfigFile, 'Save updated configuration')) {
            $Config | ConvertTo-Json -Depth 5 | Out-File $ConfigFile -Encoding utf8
            Write-CustomLog "Configuration updated and saved to $ConfigFile"
        }
    }
}

# ─── Discover scripts ────────────────────────────────────────────────────────
Write-CustomLog "==== Locating scripts ===="
$ScriptFiles = Get-ChildItem .\runner_scripts -Filter "????_*.ps1" -File | Sort-Object Name
if (-not $ScriptFiles) {
    Write-CustomLog "ERROR: No scripts found matching pattern."
    exit 1
}
Write-CustomLog "`n==== Found scripts ===="
$ScriptFiles | ForEach-Object { Write-CustomLog "$($_.Name.Substring(0,4)) - $($_.Name)" }

# ─── Execution helpers ───────────────────────────────────────────────────────
function Invoke-Scripts {
    param([array]$ScriptsToRun)

    if ($ScriptsToRun.Count -gt 1) {
        $cleanup = $ScriptsToRun | Where-Object { $_.Name.Substring(0,4) -eq '0000' }
        if ($cleanup) {
            Write-CustomLog "WARNING: Cleanup script 0000 will remove local files."
            if (-not $Auto) {
                if ((Read-Host "Continue with cleanup and exit? (Y/N)") -notmatch '^(?i)y') {
                    Write-CustomLog 'Aborting per user request.'; return $false
                }
            }
            $ScriptsToRun = $cleanup
        }
    }

    if (-not $ScriptsToRun) { Write-CustomLog "No scripts selected."; return $true }

    Write-CustomLog "`n==== Executing selected scripts ===="
    $failed = @()
    foreach ($s in $ScriptsToRun) {
        Write-CustomLog "`n--- Running: $($s.Name) ---"
        try {
            $scriptPath = "$PSScriptRoot\runner_scripts\$($s.Name)"
            if ($flag = Get-ScriptConfigFlag -Path $scriptPath) {
                $current = Get-NestedConfigValue -Config $Config -Path $flag
                if (-not $current) {
                    if ($Force)      { Set-NestedConfigValue -Config $Config -Path $flag -Value $true }
                    elseif (-not $Auto -and (Read-Host "Enable flag '$flag' and run? (Y/N)") -match '^(?i)y') {
                        Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                    }
                }
            }

            $cmd = Get-Command -Name $scriptPath -ErrorAction SilentlyContinue
            $global:LASTEXITCODE = 0
            if ($cmd -and $cmd.Parameters.ContainsKey('Config')) { & $scriptPath -Config $Config }
            else                                               { & $scriptPath }

            if ($LASTEXITCODE) {
                Write-CustomLog "ERROR: $($s.Name) exited with code $LASTEXITCODE."
                $failed += $s.Name
            } else {
                Write-CustomLog "$($s.Name) completed successfully."
            }
        } catch {
            Write-CustomLog "ERROR: Exception in $($s.Name): $_"
            $failed += $s.Name
        }
    }

    $Config | ConvertTo-Json -Depth 5 | Out-File $ConfigFile -Encoding utf8
    Write-CustomLog "`n==== Script run complete ===="
    if ($failed) { Write-CustomLog "Failures: $($failed -join ', ')"; return $false }
    return $true
}

function Select-Scripts {
    param([string]$Input)
    if ($Input -eq 'all') { return $ScriptFiles }
    $prefixes = $Input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{4}$' }
    if (-not $prefixes)   { Write-CustomLog "No valid prefixes."; return @() }
    $matches  = $ScriptFiles | Where-Object { $prefixes -contains $_.Name.Substring(0,4) }
    if (-not $matches)    { Write-CustomLog "No matching scripts."; }
    return $matches
}

# ─── Non-interactive or interactive execution ────────────────────────────────
if ($Scripts) {
    $sel = Select-Scripts -Input ($Scripts -eq 'all' ? 'all' : $Scripts)
    if (-not $sel) { exit 1 }
    if (-not (Invoke-Scripts -ScriptsToRun $sel)) { exit 1 }
    exit 0
}

while ($true) {
    Write-CustomLog "`nTo run ALL scripts, type 'all'."
    Write-CustomLog "To run specific scripts, give comma-separated 4-digit prefixes (e.g. 0001,0003)."
    Write-CustomLog "Or type 'exit' to quit."
    $choice = Read-Host "Enter selection"
    if ($choice -match '^(?i)exit$') { break }
    $selected = Select-Scripts -Input $choice
    if ($selected) { if (-not (Invoke-Scripts -ScriptsToRun $selected)) { $LASTEXITCODE = 1 } }
}

Write-CustomLog "`nAll done!"
exit ($LASTEXITCODE -as [int])

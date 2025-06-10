[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigFile = "./config_files/default-config.json",
    [switch]$Auto,
    [string]$Scripts,
    [switch]$Force,
    [switch]$Quiet,
    [ValidateSet('silent','normal','detailed')]
    [string]$Verbosity = 'normal'
)


if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7 or later is required. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# expose quiet flag to logger and apply before console level calculation
if ($Quiet) { $Verbosity = 'silent' }

$script:VerbosityLevels = @{ silent = 0; normal = 1; detailed = 2 }
$script:ConsoleLevel    = $script:VerbosityLevels[$Verbosity]


# ─── Load helpers ──────────────────────────────────────────────────────────────
if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'runner_utility_scripts' 'Logger.ps1')
}
. (Join-Path $PSScriptRoot 'lab_utils' 'Get-LabConfig.ps1')
. (Join-Path $PSScriptRoot 'lab_utils' 'Format-Config.ps1')
$menuPath = Join-Path $PSScriptRoot 'lab_utils' 'Menu.ps1'
if (-not (Test-Path $menuPath)) {
    Write-Error "Menu module not found at $menuPath"
    exit 1
}
if (-not (Get-Command Get-MenuSelection -ErrorAction SilentlyContinue)) {
    . $menuPath
}


# ─── Default log path ─────────────────────────────────────────────────────────
if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) -and
    -not (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue)) {

    $logDir = $env:LAB_LOG_DIR
    if (-not $logDir) {
        if ($IsWindows) { $logDir = 'C:\temp' } else { $logDir = [System.IO.Path]::GetTempPath() }
    }
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

function Apply-RecommendedDefaults {
    param([hashtable]$ConfigObject)

    $recommendedPath = Join-Path $PSScriptRoot 'config_files' 'recommended-config.json'
    if (-not (Test-Path $recommendedPath)) { return $ConfigObject }
    try {
        $recommended = Get-Content -Raw -Path $recommendedPath | ConvertFrom-Json
        foreach ($prop in $recommended.PSObject.Properties) {
            Set-NestedConfigValue -Config $ConfigObject -Path $prop.Name -Value $prop.Value
        }
    } catch {
        Write-CustomLog "WARNING: Failed to load recommended defaults: $_"
    }
    return $ConfigObject
}

function Set-LabConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$ConfigObject)

    function Edit-PrimitiveValue {
        param([string]$Path, [object]$Current)
        $prompt = "New value for '$Path' [$Current]"
        $ans = Read-Host $prompt
        if (-not $ans) { return $Current }
        if ($Current -is [bool]) { return $ans -match '^(?i)y|true$' }
        if ($Current -is [int])  { return [int]$ans }
        return $ans
    }

    function Edit-Section {
        param([hashtable]$Section, [string]$Prefix)
        while ($true) {
            $keys  = $Section.Keys | Sort-Object
            $items = $keys + 'Back'
            $sel   = Get-MenuSelection -Items $items -Title "Edit $Prefix"
            if (-not $sel -or $sel -eq 'Back') { break }
            foreach ($key in @($sel)) {
                $path = if ($Prefix) { "$Prefix.$key" } else { $key }
                $val  = $Section[$key]
                if ($val -is [hashtable]) {
                    Edit-Section -Section $val -Prefix $path
                } else {
                    $Section[$key] = Edit-PrimitiveValue -Path $path -Current $val
                }
            }
        }
    }

    while ($true) {
        $opts = $ConfigObject.Keys | Sort-Object
        $menu = $opts + @('Apply recommended defaults','Done')
        $choice = Get-MenuSelection -Items $menu -Title 'Edit configuration'
        if (-not $choice) { break }
        foreach ($sel in @($choice)) {
            switch ($sel) {
                'Done' { return $ConfigObject }
                'Apply recommended defaults' {
                    $ConfigObject = Apply-RecommendedDefaults -ConfigObject $ConfigObject
                }
                default {
                    $val = $ConfigObject[$sel]
                    if ($val -is [hashtable]) {
                        Edit-Section -Section $val -Prefix $sel
                    } else {
                        $ConfigObject[$sel] = Edit-PrimitiveValue -Path $sel -Current $val
                    }
                }
            }
        }
    }
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

    if ($ScriptsToRun.Count -eq 0) { Write-CustomLog "No scripts selected."; return $true }

    $names = $ScriptsToRun | ForEach-Object { $_.Name }
    Write-CustomLog "Selected script order: $($names -join ', ')"
    Write-CustomLog "`n==== Executing selected scripts ===="
    $failed = @()
    $results = @{}
    foreach ($s in $ScriptsToRun) {
        Write-CustomLog "`n--- Running: $($s.Name) ---"
        try {
            $scriptPath = Join-Path $PSScriptRoot "runner_scripts" $($s.Name)
            if (-not (Test-Path $scriptPath)) {
                Write-CustomLog "ERROR: Script not found at $scriptPath"
                $failed += $s.Name
                continue
            }
            if ($flag = Get-ScriptConfigFlag -Path $scriptPath) {
                $current = Get-NestedConfigValue -Config $Config -Path $flag
                if (-not $current) {
                    if ($Force) {
                        Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                    }
                    elseif (-not $Auto -and (Read-Host "Enable flag '$flag' and run? (Y/N)") -match '^(?i)y') {
                        Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                    }
                }
            }

            $tempCfg = [System.IO.Path]::GetTempFileName()
            $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $tempCfg -Encoding utf8
            $sb = {
                param($cfgPath, $scr, $verbosity)
                $vl = @{ silent = 0; normal = 1; detailed = 2 }
                $script:ConsoleLevel = $vl[$verbosity]
                $cfg = Get-Content -Raw -Path $cfgPath | ConvertFrom-Json
                try {
                    $args = @{ Config = $cfg }
                    if ((Get-Command $scr).Parameters.ContainsKey('AsJson')) { $args.AsJson = $true }
                    $result = & $scr @args
                    $exit = if ($LASTEXITCODE) { $LASTEXITCODE } elseif (-not $?) { 1 } else { 0 }
                    Write-Output $result
                    exit $exit
                } catch {
                    $_ | Out-String | Write-Error
                    exit 1
                }
            }

            $output = & pwsh -NoLogo -NoProfile -Command $sb -Args $tempCfg, $scriptPath, $Verbosity *>&1

            $exitCode = $LASTEXITCODE

            foreach ($line in $output) {
                if (-not $line) { continue }
                if ($line -is [System.Management.Automation.ErrorRecord]) {
                    Write-Error $line.ToString()
                } elseif ($line -is [System.Management.Automation.WarningRecord]) {
                    Write-Warning $line.ToString()
                } else {
                    Write-CustomLog $line.ToString()

                }
            }

            Remove-Item $tempCfg -ErrorAction SilentlyContinue

            $results[$s.Name] = $exitCode
            if ($exitCode) {
                Write-CustomLog "ERROR: $($s.Name) exited with code $exitCode."
                $failed += $s.Name
            } else {
                Write-CustomLog "$($s.Name) completed successfully."
            }


        } catch {
            Write-CustomLog "ERROR: Exception in $($s.Name): $_"
            $results[$s.Name] = 1
            $global:LASTEXITCODE = 1
            $results[$s.Name] = $LASTEXITCODE
            $failed += $s.Name
        }
    }


    $Config | ConvertTo-Json -Depth 5 | Out-File $ConfigFile -Encoding utf8
    $summary = $results.GetEnumerator() |
        ForEach-Object { "$(($_.Key))=$($_.Value)" } |
        Sort-Object |
        Join-String -Separator ', '
    Write-CustomLog "Results: $summary"
    Write-CustomLog "`n==== Script run complete ===="
    if ($failed) {
        Write-CustomLog "Failures: $($failed -join ', ')"
        $global:LASTEXITCODE = 1
        return $false
    }
    $global:LASTEXITCODE = 0
    return $true
}

function Select-Scripts {
    param([string]$Spec)

    if (-not $Spec) { Write-CustomLog 'No script selection provided.'; return @() }
    if ($Spec -eq 'all') { return $ScriptFiles }

    $prefixes = $Spec -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d{4}$' }

    if (-not $prefixes) { Write-CustomLog 'No valid prefixes.'; return @() }

    $matches = $ScriptFiles | Where-Object { $prefixes -contains $_.Name.Substring(0,4) }

    if (-not $matches) { Write-CustomLog 'No matching scripts.' }
    return $matches
}

function Prompt-Scripts {
    $names = $ScriptFiles | ForEach-Object { $_.Name }
    $selNames = Get-MenuSelection -Items $names -Title 'Select scripts to run' -AllowAll
    if (-not $selNames) { return @() }
    $selNames = @($selNames)  # ensure array semantics for single selections
    return $ScriptFiles | Where-Object { $selNames -contains $_.Name }
}

# ─── Non-interactive or interactive execution ────────────────────────────────
if ($Scripts) {
    if ($Scripts -eq 'all') { $sel = Select-Scripts -Spec 'all' }
    else                    { $sel = Select-Scripts -Spec $Scripts }
    if (-not $sel -or $sel.Count -eq 0) { $global:LASTEXITCODE = 1; exit 1 }
    Invoke-Scripts -ScriptsToRun $sel | Out-Null
    exit $LASTEXITCODE
}

$overallSuccess = $true
while ($true) {
    $selection = Prompt-Scripts
    if ($selection.Count -eq 0) {
        Write-CustomLog 'No scripts selected.'
        break
    }
    if (-not (Invoke-Scripts -ScriptsToRun $selection)) { $overallSuccess = $false }
}

Write-CustomLog "`nAll done!"
if (-not $overallSuccess) { $global:LASTEXITCODE = 1 } else { $global:LASTEXITCODE = 0 }
exit $LASTEXITCODE

CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Verbose')
param(
    Parameter(ParameterSetName='Quiet')







    switch$Quiet,

    Parameter(ParameterSetName='Verbose')
    ValidateSet('silent','normal','detailed')
    string$Verbosity = 'normal',
    string$ConfigFile,
    #string$ConfigFile = (Join-Path $PSScriptRoot 'default-config.json'),
    switch$Auto,
    string$Scripts,
    switch$Force
)

# repo root is this script's directory
$repoRoot   = $PSScriptRoot
$indexPath  = Join-Path $repoRoot 'path-index.yaml'
$script:PathIndex = @{}
if (Test-Path $indexPath) {
    try { $script:PathIndex = Get-Content -Raw -Path $indexPath  ConvertFrom-Yaml } catch { $script:PathIndex = @{} }
}

Import-Module "$PSScriptRoot/modules/LabRunner" -Force)

function Resolve-IndexPath {
    param(string$Key)
    






if ($script:PathIndex.ContainsKey($Key)) {
        $relative = Normalize-RelativePath $script:PathIndex$Key
        return Join-Path $repoRoot $relative
    }
    return $null
}

# apply default ConfigFile if not provided
if (-not $PSBoundParameters.ContainsKey('ConfigFile')) {
    $ConfigFile = Resolve-IndexPath 'configs/default-config.json'
    if (-not $ConfigFile) {
        $ConfigFile = Join-Path $repoRoot '..' 'configs' 'default-config.json'
    }
}


# Determine pwsh executable path early for nested script execution
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    $exeName = if ($IsWindows) { 'pwsh.exe'    } else { 'pwsh'    }
    $pwshPath = Join-Path $PSHOME $exeName
}
if (-not (Test-Path $pwshPath)) {
    Write-Error "pwsh executable not found. Install PowerShell 7 or adjust PATH."
    exit 1
}



# Re-launch under PowerShell 7 when invoked from Windows PowerShell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $argList = @()
    foreach ($kvp in $PSBoundParameters.GetEnumerator()) {
        if ($kvp.Value -is System.Management.Automation.SwitchParameter) {
            if ($kvp.Value.IsPresent) { $argList += "-$($kvp.Key)" }
        } else {
            $argList += "-$($kvp.Key)"
            $argList += $kvp.Value
        }
    }
    & $pwshPath -File $PSCommandPath @argList
    exit $LASTEXITCODE
}

# expose quiet flag to logger and apply before console level calculation
if ($Quiet) { $Verbosity = 'silent' }

$script:VerbosityLevels = @{ silent = 0; normal = 1; detailed = 2 }
$script:ConsoleLevel    = $script:VerbosityLevels$Verbosity


# ─── Load helpers ──────────────────────────────────────────────────────────────
# Import unified LabRunner module instead of individual lab_utils scripts
Import-Module "$PSScriptRoot/modules/LabRunner" -Force

# Set console verbosity level for LabRunner
$env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels[$Verbosity]
# ─── Default log path ─────────────────────────────────────────────────────────
if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) -and
    -not (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue)) {

    $logDir = $env:LAB_LOG_DIR
    if (-not $logDir) {
        if ($IsWindows) { $logDir = 'C:\temp' } else { $logDir = System.IO.Path::GetTempPath() }
    }
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null}
    $script:LogFilePath = Join-Path $logDir 'lab.log'
}

# ─── Utility helpers ──────────────────────────────────────────────────────────
function ConvertTo-Hashtable {
    param($obj)
    






switch ($obj) {
        { $_ -is System.Collections.IDictionary } {
            $ht = @{}
            foreach ($k in $_.Keys) { $ht$k = ConvertTo-Hashtable $_$k }
            return $ht
        }
        { $_ -is System.Collections.IEnumerable -and -not ($_ -is string) } {
            return _ | ForEach-Object{ ConvertTo-Hashtable $_ }
        }
        { $_ -is PSCustomObject } {
            $ht = @{}
            foreach ($p in $_.PSObject.Properties) { $ht$p.Name = ConvertTo-Hashtable $p.Value }
            return $ht
        }
        default { return $_ }
    }
}

function Get-ScriptConfigFlag {
    param(string$Path)
    






$content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ($content -match '\$Config\.(A-Za-z0-9_\.+)\s*-eq\s*\$true') { return $matches1 }
    if ($content -match '\$config\.(A-Za-z0-9_\.+)\s*-eq\s*\$true') { return $matches1 }
    return $null
}

function Get-NestedConfigValue {
    param(hashtable$Config, string$Path)
    






$parts = $Path -split '\.'
    $cur   = $Config
    foreach ($p in $parts) {
        if (-not $cur.ContainsKey($p)) { return $null }
        $cur = $cur$p
    }
    return $cur
}

function Set-NestedConfigValue {
    param(hashtable$Config, string$Path, object$Value)
    






$parts = $Path -split '\.'
    $cur   = $Config
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        if (-not $cur.ContainsKey($parts$i)) { $cur$parts$i = @{} }
        $cur = $cur$parts$i
    }
    $cur$parts-1 = $Value
}

function Apply-RecommendedDefaults {
    param(hashtable$ConfigObject)

    






$recommendedPath = Join-Path $configFilesDir 'recommended-config.json'
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
    CmdletBinding(SupportsShouldProcess)
    param(hashtable$ConfigObject)

    






function Edit-PrimitiveValue {
        param(string$Path, object$Current)
        






$prompt = "New value for '$Path' $Current"
        $ans = Read-LoggedInput $prompt
        if (-not $ans) { return $Current }
        if ($Current -is bool) { return $ans -match '^(?i)ytrue$' }
        if ($Current -is int)  { return int$ans }
        return $ans
    }

    function Edit-Section {
        param(hashtable$Section, string$Prefix)
        






while ($true) {
            $keys  = $Section.Keys | Sort-Object$items = $keys + 'Back'
            $sel   = Get-MenuSelection -Items $items -Title "Edit $Prefix"
            if (-not $sel -or $sel -eq 'Back') { break }
            foreach ($key in @($sel)) {
                $path = if ($Prefix) { "$Prefix.$key"    } else { $key    }
                $val  = $Section$key
                if ($val -is hashtable) {
                    Edit-Section -Section $val -Prefix $path
                } else {
                    $Section$key = Edit-PrimitiveValue -Path $path -Current $val
                }
            }
        }
    }

    while ($true) {
        $opts = $ConfigObject.Keys | Sort-Object$menu = $opts + @('Apply recommended defaults','Done')
        $choice = Get-MenuSelection -Items $menu -Title 'Edit configuration'
        if (-not $choice) { break }
        foreach ($sel in @($choice)) {
            switch ($sel) {
                'Done' { return $ConfigObject }
                'Apply recommended defaults' {
                    $ConfigObject = Apply-RecommendedDefaults -ConfigObject $ConfigObject
                }
                default {
                    $val = $ConfigObject$sel
                    if ($val -is hashtable) {
                        Edit-Section -Section $val -Prefix $sel
                    } else {
                        $ConfigObject$sel = Edit-PrimitiveValue -Path $sel -Current $val
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
    if ((Read-LoggedInput "Customize configuration? (Y/N)") -match '^(?i)y') {
        $Config = Set-LabConfig -ConfigObject $Config
        if ($PSCmdlet.ShouldProcess($ConfigFile, 'Save updated configuration')) {
            Config | ConvertTo-Json-Depth 5  Out-File $ConfigFile -Encoding utf8
            Write-CustomLog "Configuration updated and saved to $ConfigFile"
        }
    }
}

# ─── Discover scripts ────────────────────────────────────────────────────────
Write-CustomLog "==== Locating scripts ===="

try {

$ScriptFiles = Get-ChildItem (Join-Path $PSScriptRoot 'runner_scripts') -Filter "????_*.ps1" -File -Recurse | Sort-ObjectName

}
catch {

$ScriptFiles = Get-ChildItem $runnerScriptsDir -Filter "????_*.ps1" -File | Sort-ObjectName
}

if (-not $ScriptFiles) {
    Write-CustomLog "ERROR: No scripts found matching pattern."
    exit 1
}
Write-CustomLog "`n==== Found scripts ===="
ScriptFiles | ForEach-Object{ Write-CustomLog "$($_.Name.Substring(0,4)) - $($_.Name)" }

# ─── Execution helpers ───────────────────────────────────────────────────────
function Invoke-Scripts {
    param(array$ScriptsToRun)

    






if ($ScriptsToRun.Count -gt 1) {
        $cleanup = ScriptsToRun | Where-Object{ $_.Name.Substring(0,4) -eq '0000' }
        if ($cleanup) {
            Write-CustomLog "WARNING: Cleanup script 0000 will remove local files."
            if (-not $Auto) {
                if ((Read-LoggedInput "Continue with cleanup and exit? (Y/N)") -notmatch '^(?i)y') {
                    Write-CustomLog 'Aborting per user request.'; return $false
                }
            }
            $ScriptsToRun = $cleanup
        }
    }

    if ($ScriptsToRun.Count -eq 0) { Write-CustomLog "No scripts selected."; return $true }

    $names = ScriptsToRun | ForEach-Object{ $_.Name }
    Write-CustomLog "Selected script order: $($names -join ', ')"
    Write-CustomLog "`n==== Executing selected scripts ===="
    $failed = @()
    $results = @{}
    foreach ($s in $ScriptsToRun) {
        Write-CustomLog "`n--- Running: $($s.Name) ---"
        try {
            $scriptPath = Resolve-ProjectPath -Name $($s.Name)
            if (-not $scriptPath) {
                Write-CustomLog "ERROR: Script not found for $($s.Name)"
                $failed += $s.Name
                continue
            }
                        # Validate script syntax before execution
            try {
                $scriptContent = Get-Content $scriptPath -Raw
                $null = System.Management.Automation.PSParser::Tokenize($scriptContent, ref$null)
                Write-CustomLog "Script syntax validation passed for $($s.Name)"
            } catch {
                Write-CustomLog "ERROR: Script has syntax errors: $scriptPath - CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Verbose')
param(
    Parameter(ParameterSetName='Quiet')







    switch$Quiet,

    Parameter(ParameterSetName='Verbose')
    ValidateSet('silent','normal','detailed')
    string$Verbosity = 'normal',
    string$ConfigFile,
    #string$ConfigFile = (Join-Path $PSScriptRoot 'default-config.json'),
    switch$Auto,
    string$Scripts,
    switch$Force
)

# repo root is this script's directory
$repoRoot   = $PSScriptRoot
$indexPath  = Join-Path $repoRoot 'path-index.yaml'
$script:PathIndex = @{}
if (Test-Path $indexPath) {
    try { $script:PathIndex = Get-Content -Raw -Path $indexPath  ConvertFrom-Yaml } catch { $script:PathIndex = @{} }
}

Import-Module "$PSScriptRoot/modules/LabRunner" -Force)

function Resolve-IndexPath {
    param(string$Key)
    






if ($script:PathIndex.ContainsKey($Key)) {
        $relative = Normalize-RelativePath $script:PathIndex$Key
        return Join-Path $repoRoot $relative
    }
    return $null
}

# apply default ConfigFile if not provided
if (-not $PSBoundParameters.ContainsKey('ConfigFile')) {
    $ConfigFile = Resolve-IndexPath 'configs/default-config.json'
    if (-not $ConfigFile) {
        $ConfigFile = Join-Path $repoRoot '..' 'configs' 'default-config.json'
    }
}


# Determine pwsh executable path early for nested script execution
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    $exeName = if ($IsWindows) { 'pwsh.exe'    } else { 'pwsh'    }
    $pwshPath = Join-Path $PSHOME $exeName
}
if (-not (Test-Path $pwshPath)) {
    Write-Error "pwsh executable not found. Install PowerShell 7 or adjust PATH."
    exit 1
}



# Re-launch under PowerShell 7 when invoked from Windows PowerShell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $argList = @()
    foreach ($kvp in $PSBoundParameters.GetEnumerator()) {
        if ($kvp.Value -is System.Management.Automation.SwitchParameter) {
            if ($kvp.Value.IsPresent) { $argList += "-$($kvp.Key)" }
        } else {
            $argList += "-$($kvp.Key)"
            $argList += $kvp.Value
        }
    }
    & $pwshPath -File $PSCommandPath @argList
    exit $LASTEXITCODE
}

# expose quiet flag to logger and apply before console level calculation
if ($Quiet) { $Verbosity = 'silent' }

$script:VerbosityLevels = @{ silent = 0; normal = 1; detailed = 2 }
$script:ConsoleLevel    = $script:VerbosityLevels$Verbosity


# ─── Load helpers ──────────────────────────────────────────────────────────────
# Import unified LabRunner module instead of individual lab_utils scripts
Import-Module "$PSScriptRoot/modules/LabRunner" -Force

# Set console verbosity level for LabRunner
$env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels[$Verbosity]
# ─── Default log path ─────────────────────────────────────────────────────────
if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) -and
    -not (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue)) {

    $logDir = $env:LAB_LOG_DIR
    if (-not $logDir) {
        if ($IsWindows) { $logDir = 'C:\temp' } else { $logDir = System.IO.Path::GetTempPath() }
    }
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null}
    $script:LogFilePath = Join-Path $logDir 'lab.log'
}

# ─── Utility helpers ──────────────────────────────────────────────────────────
function ConvertTo-Hashtable {
    param($obj)
    






switch ($obj) {
        { $_ -is System.Collections.IDictionary } {
            $ht = @{}
            foreach ($k in $_.Keys) { $ht$k = ConvertTo-Hashtable $_$k }
            return $ht
        }
        { $_ -is System.Collections.IEnumerable -and -not ($_ -is string) } {
            return _ | ForEach-Object{ ConvertTo-Hashtable $_ }
        }
        { $_ -is PSCustomObject } {
            $ht = @{}
            foreach ($p in $_.PSObject.Properties) { $ht$p.Name = ConvertTo-Hashtable $p.Value }
            return $ht
        }
        default { return $_ }
    }
}

function Get-ScriptConfigFlag {
    param(string$Path)
    






$content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ($content -match '\$Config\.(A-Za-z0-9_\.+)\s*-eq\s*\$true') { return $matches1 }
    if ($content -match '\$config\.(A-Za-z0-9_\.+)\s*-eq\s*\$true') { return $matches1 }
    return $null
}

function Get-NestedConfigValue {
    param(hashtable$Config, string$Path)
    






$parts = $Path -split '\.'
    $cur   = $Config
    foreach ($p in $parts) {
        if (-not $cur.ContainsKey($p)) { return $null }
        $cur = $cur$p
    }
    return $cur
}

function Set-NestedConfigValue {
    param(hashtable$Config, string$Path, object$Value)
    






$parts = $Path -split '\.'
    $cur   = $Config
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        if (-not $cur.ContainsKey($parts$i)) { $cur$parts$i = @{} }
        $cur = $cur$parts$i
    }
    $cur$parts-1 = $Value
}

function Apply-RecommendedDefaults {
    param(hashtable$ConfigObject)

    






$recommendedPath = Join-Path $configFilesDir 'recommended-config.json'
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
    CmdletBinding(SupportsShouldProcess)
    param(hashtable$ConfigObject)

    






function Edit-PrimitiveValue {
        param(string$Path, object$Current)
        






$prompt = "New value for '$Path' $Current"
        $ans = Read-LoggedInput $prompt
        if (-not $ans) { return $Current }
        if ($Current -is bool) { return $ans -match '^(?i)ytrue$' }
        if ($Current -is int)  { return int$ans }
        return $ans
    }

    function Edit-Section {
        param(hashtable$Section, string$Prefix)
        






while ($true) {
            $keys  = $Section.Keys | Sort-Object$items = $keys + 'Back'
            $sel   = Get-MenuSelection -Items $items -Title "Edit $Prefix"
            if (-not $sel -or $sel -eq 'Back') { break }
            foreach ($key in @($sel)) {
                $path = if ($Prefix) { "$Prefix.$key"    } else { $key    }
                $val  = $Section$key
                if ($val -is hashtable) {
                    Edit-Section -Section $val -Prefix $path
                } else {
                    $Section$key = Edit-PrimitiveValue -Path $path -Current $val
                }
            }
        }
    }

    while ($true) {
        $opts = $ConfigObject.Keys | Sort-Object$menu = $opts + @('Apply recommended defaults','Done')
        $choice = Get-MenuSelection -Items $menu -Title 'Edit configuration'
        if (-not $choice) { break }
        foreach ($sel in @($choice)) {
            switch ($sel) {
                'Done' { return $ConfigObject }
                'Apply recommended defaults' {
                    $ConfigObject = Apply-RecommendedDefaults -ConfigObject $ConfigObject
                }
                default {
                    $val = $ConfigObject$sel
                    if ($val -is hashtable) {
                        Edit-Section -Section $val -Prefix $sel
                    } else {
                        $ConfigObject$sel = Edit-PrimitiveValue -Path $sel -Current $val
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
    if ((Read-LoggedInput "Customize configuration? (Y/N)") -match '^(?i)y') {
        $Config = Set-LabConfig -ConfigObject $Config
        if ($PSCmdlet.ShouldProcess($ConfigFile, 'Save updated configuration')) {
            Config | ConvertTo-Json-Depth 5  Out-File $ConfigFile -Encoding utf8
            Write-CustomLog "Configuration updated and saved to $ConfigFile"
        }
    }
}

# ─── Discover scripts ────────────────────────────────────────────────────────
Write-CustomLog "==== Locating scripts ===="

try {

$ScriptFiles = Get-ChildItem (Join-Path $PSScriptRoot 'runner_scripts') -Filter "????_*.ps1" -File -Recurse | Sort-ObjectName

}
catch {

$ScriptFiles = Get-ChildItem $runnerScriptsDir -Filter "????_*.ps1" -File | Sort-ObjectName
}

if (-not $ScriptFiles) {
    Write-CustomLog "ERROR: No scripts found matching pattern."
    exit 1
}
Write-CustomLog "`n==== Found scripts ===="
ScriptFiles | ForEach-Object{ Write-CustomLog "$($_.Name.Substring(0,4)) - $($_.Name)" }

# ─── Execution helpers ───────────────────────────────────────────────────────
function Invoke-Scripts {
    param(array$ScriptsToRun)

    






if ($ScriptsToRun.Count -gt 1) {
        $cleanup = ScriptsToRun | Where-Object{ $_.Name.Substring(0,4) -eq '0000' }
        if ($cleanup) {
            Write-CustomLog "WARNING: Cleanup script 0000 will remove local files."
            if (-not $Auto) {
                if ((Read-LoggedInput "Continue with cleanup and exit? (Y/N)") -notmatch '^(?i)y') {
                    Write-CustomLog 'Aborting per user request.'; return $false
                }
            }
            $ScriptsToRun = $cleanup
        }
    }

    if ($ScriptsToRun.Count -eq 0) { Write-CustomLog "No scripts selected."; return $true }

    $names = ScriptsToRun | ForEach-Object{ $_.Name }
    Write-CustomLog "Selected script order: $($names -join ', ')"
    Write-CustomLog "`n==== Executing selected scripts ===="
    $failed = @()
    $results = @{}
    foreach ($s in $ScriptsToRun) {
        Write-CustomLog "`n--- Running: $($s.Name) ---"
        try {
            $scriptPath = Resolve-ProjectPath -Name $($s.Name)
            if (-not $scriptPath) {
                Write-CustomLog "ERROR: Script not found for $($s.Name)"
                $failed += $s.Name
                continue
            }
            if ($flag = Get-ScriptConfigFlag -Path $scriptPath) {
                $current = Get-NestedConfigValue -Config $Config -Path $flag
                if (-not $current) {
                    if ($Force) {
                        Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                        Config | ConvertTo-Json-Depth 5  Out-File -FilePath $ConfigFile -Encoding utf8
                        $current = $true
                    }
                    elseif (-not $Auto -and (Read-LoggedInput "Enable flag '$flag' and run? (Y/N)") -match '^(?i)y') {
                        Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                        Config | ConvertTo-Json-Depth 5  Out-File -FilePath $ConfigFile -Encoding utf8
                        $current = $true
                    }
                }
                if (-not $current) {
                    Write-CustomLog "Flag '$flag' disabled - skipping $($s.Name)"
                    continue
                }
            }

            $tempCfg = System.IO.Path::GetTempFileName()
            Config | ConvertTo-Json-Depth 5  Out-File -FilePath $tempCfg -Encoding utf8 -NoNewline
            $scriptArgs = @('-File', $scriptPath, '-Config', $tempCfg)
            if ((Get-Command $scriptPath).Parameters.ContainsKey('AsJson')) { $scriptArgs += '-AsJson' }
            $env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels$Verbosity
            $output = & $pwshPath -NoLogo -NoProfile @scriptArgs *>&1
            Remove-Item Env:LAB_CONSOLE_LEVEL -ErrorAction SilentlyContinue

            $exitCode = $LASTEXITCODE

            foreach ($line in $output) {
                if (-not $line) { continue }
                
                $lineStr = $line.ToString().Trim()
                
                # Detect PowerShell parameter binding errors
                if ($lineStr -match "The term 'Param' is not recognized" -or 
                    $lineStr -match "ParameterBindingException" -or
                    $lineStr -match "positional parameter cannot be found") {
                    Write-CustomLog "ERROR: Parameter binding issue detected in $($s.Name): $lineStr" 'ERROR'
                    $exitCode = 1
                } elseif ($line -is System.Management.Automation.ErrorRecord -or $lineStr.StartsWith('ERROR:')) {
                    Write-CustomLog "ERROR: $lineStr" 'ERROR'
                    $exitCode = 1
                } elseif ($line -is System.Management.Automation.WarningRecord -or $lineStr.StartsWith('WARNING:')) {
                    Write-CustomLog "WARNING: $lineStr" 'WARN'
                } else {
                    Write-CustomLog $lineStr
                }
            }

            Remove-Item $tempCfg -ErrorAction SilentlyContinue

            Config | ConvertTo-Json-Depth 5 
                Out-File -FilePath $ConfigFile -Encoding utf8

            $results$s.Name = $exitCode
            if ($exitCode) {
                Write-CustomLog "ERROR: $($s.Name) exited with code $exitCode."
                $failed += $s.Name
            } else {
                Write-CustomLog "$($s.Name) completed successfully."
            }


        } catch {
            Write-CustomLog "ERROR: Exception in $($s.Name): $_"
            $results$s.Name = 1
            $global:LASTEXITCODE = 1
            $results$s.Name = $LASTEXITCODE
            $failed += $s.Name
        }
    }


    Config | ConvertTo-Json-Depth 5  Out-File $ConfigFile -Encoding utf8
    $summary = $results.GetEnumerator() | ForEach-Object{ "$(($_.Key))=$($_.Value)" } | Sort-ObjectJoin-String -Separator ', '
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
    param(string$Spec)

    






if (-not $Spec) { Write-CustomLog 'No script selection provided.'; return @() }
    if ($Spec -eq 'all') { return $ScriptFiles }

    $prefixes = $Spec -split ',' | ForEach-Object{ $_.Trim() } | Where-Object{ $_ -match '^\d{4}$' }

    if (-not $prefixes) { Write-CustomLog 'No valid prefixes.'; return @() }

    $matches = ScriptFiles | Where-Object{ $prefixes -contains $_.Name.Substring(0,4) }

    if (-not $matches) { Write-CustomLog 'No matching scripts.' }
    return $matches
}

function Prompt-Scripts {
    $names = ScriptFiles | ForEach-Object{ $_.Name }
    $selNames = Get-MenuSelection -Items $names -Title 'Select scripts to run' -AllowAll
    if (-not $selNames) { return @() }
    $selNames = @($selNames)  # ensure array semantics for single selections
    return ScriptFiles | Where-Object{ $selNames -contains $_.Name }
}

# ─── Non-interactive or interactive execution ────────────────────────────────
if ($Scripts) {
    if ($Scripts -eq 'all') { $sel = Select-Scripts -Spec 'all' }
    else                    { $sel = Select-Scripts -Spec $Scripts }
    if (-not $sel -or $sel.Count -eq 0) { $global:LASTEXITCODE = 1; exit 1 }
    Invoke-Scripts -ScriptsToRun sel | Out-Null
exit $LASTEXITCODE
}

$overallSuccess = $true
do {
    $selection = Prompt-Scripts
    if ($selection.Count -eq 0) {
        Write-CustomLog 'No scripts selected.'
    } else {
        if (-not (Invoke-Scripts -ScriptsToRun $selection)) { $overallSuccess = $false }
    }
} while ($Auto -and $selection.Count -gt 0)

Write-CustomLog "`nAll done!"
if (-not $overallSuccess) { $global:LASTEXITCODE = 1 } else { $global:LASTEXITCODE = 0 }
Remove-Item Env:LAB_CONSOLE_LEVEL -ErrorAction SilentlyContinue
exit $LASTEXITCODE
" 'ERROR'
                $failed += $s.Name
                continue
            }
            if ($flag = Get-ScriptConfigFlag -Path $scriptPath) {
                $current = Get-NestedConfigValue -Config $Config -Path $flag
                if (-not $current) {
                    if ($Force) {
                        Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                        Config | ConvertTo-Json-Depth 5  Out-File -FilePath $ConfigFile -Encoding utf8
                        $current = $true
                    }
                    elseif (-not $Auto -and (Read-LoggedInput "Enable flag '$flag' and run? (Y/N)") -match '^(?i)y') {
                        Set-NestedConfigValue -Config $Config -Path $flag -Value $true
                        Config | ConvertTo-Json-Depth 5  Out-File -FilePath $ConfigFile -Encoding utf8
                        $current = $true
                    }
                }
                if (-not $current) {
                    Write-CustomLog "Flag '$flag' disabled - skipping $($s.Name)"
                    continue
                }
            }

            $tempCfg = System.IO.Path::GetTempFileName()
            Config | ConvertTo-Json-Depth 5  Out-File -FilePath $tempCfg -Encoding utf8 -NoNewline
            $scriptArgs = @('-File', $scriptPath, '-Config', $tempCfg)
            if ((Get-Command $scriptPath).Parameters.ContainsKey('AsJson')) { $scriptArgs += '-AsJson' }
            $env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels$Verbosity
            $output = & $pwshPath -NoLogo -NoProfile @scriptArgs *>&1
            Remove-Item Env:LAB_CONSOLE_LEVEL -ErrorAction SilentlyContinue

            $exitCode = $LASTEXITCODE

            foreach ($line in $output) {
                if (-not $line) { continue }
                
                $lineStr = $line.ToString().Trim()
                
                # Detect PowerShell parameter binding errors
                if ($lineStr -match "The term 'Param' is not recognized" -or 
                    $lineStr -match "ParameterBindingException" -or
                    $lineStr -match "positional parameter cannot be found") {
                    Write-CustomLog "ERROR: Parameter binding issue detected in $($s.Name): $lineStr" 'ERROR'
                    $exitCode = 1
                } elseif ($line -is System.Management.Automation.ErrorRecord -or $lineStr.StartsWith('ERROR:')) {
                    Write-CustomLog "ERROR: $lineStr" 'ERROR'
                    $exitCode = 1
                } elseif ($line -is System.Management.Automation.WarningRecord -or $lineStr.StartsWith('WARNING:')) {
                    Write-CustomLog "WARNING: $lineStr" 'WARN'
                } else {
                    Write-CustomLog $lineStr
                }
            }

            Remove-Item $tempCfg -ErrorAction SilentlyContinue

            Config | ConvertTo-Json-Depth 5 
                Out-File -FilePath $ConfigFile -Encoding utf8

            $results$s.Name = $exitCode
            if ($exitCode) {
                Write-CustomLog "ERROR: $($s.Name) exited with code $exitCode."
                $failed += $s.Name
            } else {
                Write-CustomLog "$($s.Name) completed successfully."
            }


        } catch {
            Write-CustomLog "ERROR: Exception in $($s.Name): $_"
            $results$s.Name = 1
            $global:LASTEXITCODE = 1
            $results$s.Name = $LASTEXITCODE
            $failed += $s.Name
        }
    }


    Config | ConvertTo-Json-Depth 5  Out-File $ConfigFile -Encoding utf8
    $summary = $results.GetEnumerator() | ForEach-Object{ "$(($_.Key))=$($_.Value)" } | Sort-ObjectJoin-String -Separator ', '
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
    param(string$Spec)

    






if (-not $Spec) { Write-CustomLog 'No script selection provided.'; return @() }
    if ($Spec -eq 'all') { return $ScriptFiles }

    $prefixes = $Spec -split ',' | ForEach-Object{ $_.Trim() } | Where-Object{ $_ -match '^\d{4}$' }

    if (-not $prefixes) { Write-CustomLog 'No valid prefixes.'; return @() }

    $matches = ScriptFiles | Where-Object{ $prefixes -contains $_.Name.Substring(0,4) }

    if (-not $matches) { Write-CustomLog 'No matching scripts.' }
    return $matches
}

function Prompt-Scripts {
    $names = ScriptFiles | ForEach-Object{ $_.Name }
    $selNames = Get-MenuSelection -Items $names -Title 'Select scripts to run' -AllowAll
    if (-not $selNames) { return @() }
    $selNames = @($selNames)  # ensure array semantics for single selections
    return ScriptFiles | Where-Object{ $selNames -contains $_.Name }
}

# ─── Non-interactive or interactive execution ────────────────────────────────
if ($Scripts) {
    if ($Scripts -eq 'all') { $sel = Select-Scripts -Spec 'all' }
    else                    { $sel = Select-Scripts -Spec $Scripts }
    if (-not $sel -or $sel.Count -eq 0) { $global:LASTEXITCODE = 1; exit 1 }
    Invoke-Scripts -ScriptsToRun sel | Out-Null
exit $LASTEXITCODE
}

$overallSuccess = $true
do {
    $selection = Prompt-Scripts
    if ($selection.Count -eq 0) {
        Write-CustomLog 'No scripts selected.'
    } else {
        if (-not (Invoke-Scripts -ScriptsToRun $selection)) { $overallSuccess = $false }
    }
} while ($Auto -and $selection.Count -gt 0)

Write-CustomLog "`nAll done!"
if (-not $overallSuccess) { $global:LASTEXITCODE = 1 } else { $global:LASTEXITCODE = 0 }
Remove-Item Env:LAB_CONSOLE_LEVEL -ErrorAction SilentlyContinue
exit $LASTEXITCODE











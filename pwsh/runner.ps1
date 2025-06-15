[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='Verbose')]
param(
    [Parameter(ParameterSetName='Quiet')]
    [switch]$Quiet,

    [Parameter(ParameterSetName='Verbose')]
    [ValidateSet('silent','normal','detailed')]
    [string]$Verbosity = 'normal',
    [string]$ConfigFile,
    #[string]$ConfigFile = (Join-Path $PSScriptRoot 'config_files' 'default-config.json'),
    [switch]$Auto,
    [string]$Scripts,
    [switch]$Force
)

# Import PatchManager for maintenance
Import-Module "/pwsh/modules/PatchManager" -Force

# Update path resolution to use absolute paths
$repoRoot = "/workspaces/opentofu-lab-automation"
$indexPath = Join-Path $repoRoot "configs/path-index.yaml"
$script:PathIndex = @{}
if (Test-Path $indexPath) {
    try {
        $script:PathIndex = Get-Content -Raw -Path $indexPath | ConvertFrom-Yaml
    } catch {
        Write-Error "Failed to load path index from $indexPath"
        exit 1
    }
}

function Resolve-IndexPath {
    param([string]$Key)
    if ($script:PathIndex.ContainsKey($Key)) {
        $relative = Normalize-RelativePath $script:PathIndex[$Key]
        return Join-Path $repoRoot $relative
    }
    Write-Error "Path key $Key not found in index"
    return $null
}

# Validate PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7 or higher is required. Please upgrade."
    exit 1
}

# Load helpers with absolute paths
$labUtilsDir = Resolve-IndexPath "lab_utils"
if (-not $labUtilsDir) {
    Write-Error "Failed to resolve lab_utils directory"
    exit 1
}

$runnerScriptsDir = Resolve-IndexPath "runner_scripts"
if (-not $runnerScriptsDir) {
    Write-Error "Failed to resolve runner_scripts directory"
    exit 1
}

$configFilesDir = Resolve-IndexPath "configs/config_files"
if (-not $configFilesDir) {
    Write-Error "Failed to resolve config_files directory"
    exit 1
}

# Load required scripts
. (Join-Path $labUtilsDir "LabRunner/Logger.ps1")
. (Join-Path $labUtilsDir "Get-LabConfig.ps1")
. (Join-Path $labUtilsDir "Format-Config.ps1")
. (Join-Path $labUtilsDir "Get-Platform.ps1")
. (Join-Path $labUtilsDir "Resolve-ProjectPath.ps1")
$menuPath = Join-Path $PSScriptRoot (Join-Path 'lab_utils' 'Menu.ps1')

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

function Set-RecommendedDefaults {
    param([hashtable]$ConfigObject)
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
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$ConfigObject)

    if ($PSCmdlet.ShouldProcess("Configuration update")) {
        function Edit-PrimitiveValue {
            param([string]$Path, [object]$Current)
$prompt = "New value for '$Path' [$Current]"
            $ans = Read-LoggedInput $prompt
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
                    $path = if ($Prefix) { "$Prefix.$key"    } else { $key    }
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
            $Config | ConvertTo-Json -Depth 5 | Out-File $ConfigFile -Encoding utf8
            Write-CustomLog "Configuration updated and saved to $ConfigFile"
        }
    }
}

# ─── Discover scripts ────────────────────────────────────────────────────────
Write-CustomLog "==== Locating scripts ===="

try {

$ScriptFiles = Get-ChildItem (Join-Path $PSScriptRoot 'runner_scripts') -Filter "????_*.ps1" -File -Recurse | Sort-Object Name

}
catch {

$ScriptFiles = Get-ChildItem $runnerScriptsDir -Filter "????_*.ps1" -File | Sort-Object Name
}

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
                if ((Read-LoggedInput "Continue with cleanup and exit? (Y/N)") -notmatch '^(?i)y') {
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
                $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)
                Write-CustomLog "Script syntax validation passed for $($s.Name)"
            } catch {
                Write-CustomLog "ERROR: Script has syntax errors: $scriptPath"
                $failed += $s.Name
                continue
            }

            # Execute script
            . $scriptPath
            Write-CustomLog "Execution completed for $($s.Name)"
        } catch {
            Write-CustomLog "ERROR: Failed to execute script $($s.Name)"
            $failed += $s.Name
        }
    }

    if ($failed.Count -gt 0) {
        Write-CustomLog "`n==== Failed scripts ===="
        $failed | ForEach-Object { Write-CustomLog $_ }
        return $false
    }

    Write-CustomLog "`n==== All scripts executed successfully ===="
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

    $scriptMatches = $ScriptFiles | Where-Object { $prefixes -contains $_.Name.Substring(0,4) }

    if (-not $scriptMatches) { Write-CustomLog 'No matching scripts.' }
    return $scriptMatches
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
do {
    $selection = Select-Scripts
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





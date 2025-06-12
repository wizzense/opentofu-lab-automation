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

# repo root is this script's directory
$repoRoot   = $PSScriptRoot
$indexPath  = Join-Path $repoRoot 'path-index.yaml'
$script:PathIndex = @{}
if (Test-Path $indexPath) {
    try { $script:PathIndex = Get-Content -Raw -Path $indexPath | ConvertFrom-Yaml } catch { $script:PathIndex = @{} }
}

. (Join-Path $repoRoot (Join-Path 'lab_utils' 'PathUtils.ps1'))

function Resolve-IndexPath {
    param([string]$Key)
    if ($script:PathIndex.ContainsKey($Key)) {
        $relative = Normalize-RelativePath $script:PathIndex[$Key]
        return Join-Path $repoRoot $relative
    }
    return $null
}

# apply default ConfigFile if not provided
if (-not $PSBoundParameters.ContainsKey('ConfigFile')) {
    $ConfigFile = Resolve-IndexPath 'configs/config_files/default-config.json'
    if (-not $ConfigFile) {
        $ConfigFile = Join-Path $repoRoot '..' 'configs' 'config_files' 'default-config.json'
    }
}

# Determine pwsh executable path early for nested script execution
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    $exeName  = if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' }
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
        if ($kvp.Value -is [System.Management.Automation.SwitchParameter]) {
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
$script:ConsoleLevel    = $script:VerbosityLevels[$Verbosity]

# ─── Load helpers ──────────────────────────────────────────────────────────────
$labUtilsDir      = Resolve-IndexPath 'lab_utils';      if (-not $labUtilsDir)      { $labUtilsDir      = Join-Path $repoRoot 'lab_utils' }
$runnerScriptsDir = Resolve-IndexPath 'runner_scripts'; if (-not $runnerScriptsDir) { $runnerScriptsDir = Join-Path $repoRoot 'runner_scripts' }
$configFilesDir   = Resolve-IndexPath 'configs/config_files'; if (-not $configFilesDir) { $configFilesDir = Join-Path $repoRoot '..' 'configs' 'config_files' }

if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    . (Join-Path $labUtilsDir (Join-Path 'LabRunner' 'Logger.ps1'))
}
$env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels[$Verbosity]
. (Join-Path $PSScriptRoot (Join-Path 'lab_utils' 'Get-LabConfig.ps1'))
. (Join-Path $PSScriptRoot (Join-Path 'lab_utils' 'Format-Config.ps1'))
. (Join-Path $PSScriptRoot (Join-Path 'lab_utils' 'Get-Platform.ps1'))
. (Join-Path $PSScriptRoot (Join-Path 'lab_utils' 'Resolve-ProjectPath.ps1'))
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
function ConvertTo-Hashtable { ... }
function Get-ScriptConfigFlag { ... }
function Get-NestedConfigValue { ... }
function Set-NestedConfigValue { ... }
function Apply-RecommendedDefaults { ... }
function Set-LabConfig { ... }

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
if (-not $Auto) { ... }

# ─── Discover scripts ────────────────────────────────────────────────────────
Write-CustomLog "==== Locating scripts ===="
try {
    $ScriptFiles = Get-ChildItem (Join-Path $PSScriptRoot 'runner_scripts') -Filter "????_*.ps1" -File -Recurse | Sort-Object Name
} catch {
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

    if ($ScriptsToRun.Count -gt 1) { ... }
    if ($ScriptsToRun.Count -eq 0) { Write-CustomLog "No scripts selected."; return $true }

    $names = $ScriptsToRun | ForEach-Object { $_.Name }
    Write-CustomLog "Selected script order: $($names -join ', ')"
    Write-CustomLog "`n==== Executing selected scripts ===="
    $failed = @()
    $results = @{}

    foreach ($s in $ScriptsToRun) {
        Write-CustomLog "`n--- Running: $($s.Name) ---"
        try {
            # syntax check
            $scriptPath    = Resolve-ProjectPath -Name $($s.Name)
            $scriptContent = Get-Content $scriptPath -Raw
            $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)
            Write-CustomLog "Script syntax validation passed for $($s.Name)"
        } catch {
            Write-CustomLog "ERROR: Script has syntax errors in $scriptPath. Exception: $_" 'ERROR'
            $failed += $s.Name
            continue
        }

        # flag-check, temp config, execution, output parsing...
        # (unchanged)
    }

    # summary and exit-code handling...
}

function Select-Scripts { ... }
function Prompt-Scripts  { ... }

# ─── Non-interactive or interactive execution ────────────────────────────────
if ($Scripts) {
    ...
}

$overallSuccess = $true
do { ... } while ($Auto -and $selection.Count -gt 0)

Write-CustomLog "`nAll done!"
if (-not $overallSuccess) { $global:LASTEXITCODE = 1 } else { $global:LASTEXITCODE = 0 }
Remove-Item Env:LAB_CONSOLE_LEVEL -ErrorAction SilentlyContinue
exit $LASTEXITCODE

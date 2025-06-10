function Ensure-PSModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$RequiredVersion
    )

    $module = if ($RequiredVersion) {
        Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
            Where-Object { $_.Version -eq [version]$RequiredVersion } |
            Select-Object -First 1
    } else {
        Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
            Select-Object -First 1
    }

    if (-not $module) {
        Write-Output "Installing $Name..."
        $params = @{ Name = $Name; Force = $true; Scope = 'CurrentUser' }
        if ($RequiredVersion) { $params.RequiredVersion = $RequiredVersion }
        try {
            Install-Module @params -ErrorAction Stop
            Write-Output "$Name installed"
        } catch {
            Write-Error "Failed to install $Name: $_"
        }
    } else {
        Write-Output "$Name $($module.Version) already installed"
    }
}

function Install-TestDependencies {
    [CmdletBinding()]
    param()

    Ensure-PSModule -Name Pester
    Ensure-PSModule -Name PSScriptAnalyzer -RequiredVersion '1.24.0'
    Ensure-PSModule -Name powershell-yaml

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        Write-Output 'Installing ruff via pip...'
        try {
            & $python.Path -m pip install --user ruff | Out-Null
            Write-Output 'ruff installed'
        } catch {
            Write-Warning "Failed to install ruff: $_"
        }
    } else {
        Write-Output 'Python not found. Skipping ruff installation.'
    }
}

Install-TestDependencies

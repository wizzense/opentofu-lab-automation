#!/usr/bin/env pwsh
<#
.SYNOPSIS
    OpenTofu Lab Automation - Cross-Platform Installer
    
.DESCRIPTION
    Downloads and sets up OpenTofu Lab Automation on any system with PowerShell.
    Works on Windows (GUI/Server Core), Linux, macOS.
    
.PARAMETER Component
    What to download: 'launcher' (default), 'gui', 'deploy', 'all'
    
.PARAMETER NoMenu
    Skip interactive menu and download launcher only
    
.EXAMPLE
    # Quick start (downloads launcher and runs interactive menu)
    ./install.ps1
    
.EXAMPLE
    # Download specific component
    ./install.ps1 -Component gui
    
.EXAMPLE
    # Silent download
    ./install.ps1 -NoMenu
#>

param(
    [ValidateSet('launcher', 'gui', 'deploy', 'all')]
    [string]$Component = 'launcher',
    [switch]$NoMenu
)

# Cross-platform console colors
$script:Colors = @{
    Red = if ($PSVersionTable.Platform -eq 'Win32NT') { 'Red' } else { "`e[31m" }
    Green = if ($PSVersionTable.Platform -eq 'Win32NT') { 'Green' } else { "`e[32m" }
    Yellow = if ($PSVersionTable.Platform -eq 'Win32NT') { 'Yellow' } else { "`e[33m" }
    Blue = if ($PSVersionTable.Platform -eq 'Win32NT') { 'Blue' } else { "`e[34m" }
    Reset = if ($PSVersionTable.Platform -eq 'Win32NT') { 'White' } else { "`e[0m" }
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    
    if ($PSVersionTable.Platform -eq 'Win32NT') {
        Write-Host $Message -ForegroundColor $Color
    } else {
        $colorCode = $script:Colors[$Color]
        $resetCode = $script:Colors['Reset']
        Write-Host "$colorCode$Message$resetCode"
    }
}

function Get-PlatformInfo {
    $platform = @{
        OS = $PSVersionTable.Platform ?? 'Win32NT'
        PSVersion = $PSVersionTable.PSVersion
        Architecture = $env:PROCESSOR_ARCHITECTURE ?? 'Unknown'
    }
    
    if ($platform.OS -eq 'Win32NT') {
        $platform.Type = if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue) { 'Windows Server' } else { 'Windows Desktop' }
        $platform.GUI = -not (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels' -ErrorAction SilentlyContinue).ServerCore
    } else {
        $platform.Type = $platform.OS
        $platform.GUI = $env:DISPLAY -ne $null -or $env:WAYLAND_DISPLAY -ne $null
    }
    
    return $platform
}

function Test-InternetConnectivity {
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add('User-Agent', 'OpenTofu-Installer/1.0')
        $null = $webClient.DownloadString('https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/README.md')
        $webClient.Dispose()
        return $true
    }
    catch {
        return $false
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$DestinationPath
    )
    
    Write-ColorOutput "� Downloading: $DestinationPath" 'Blue'
    
    try {
        # Try modern method first
        if (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue) {
            Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing
        }
        else {
            # Fallback for older PowerShell
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add('User-Agent', 'OpenTofu-Installer/1.0')
            $webClient.DownloadFile($Url, $DestinationPath)
            $webClient.Dispose()
        }
        
        if (Test-Path $DestinationPath) {
            Write-ColorOutput "[PASS] Downloaded successfully: $DestinationPath" 'Green'
            return $true
        } else {
            throw "File not found after download"
        }
    }
    catch {
        Write-ColorOutput "[FAIL] Download failed: $_" 'Red'
        return $false
    }
}

function Show-Header {
    Write-ColorOutput "" 'White'
    Write-ColorOutput "======================================================" 'Blue'
    Write-ColorOutput "  OpenTofu Lab Automation - Cross-Platform Installer" 'Blue'
    Write-ColorOutput "======================================================" 'Blue'
    Write-ColorOutput "" 'White'
}

function Show-PlatformInfo {
    $platform = Get-PlatformInfo
    
    Write-ColorOutput "�  Platform Information:" 'Yellow'
    Write-ColorOutput "   OS: $($platform.Type)" 'White'
    Write-ColorOutput "   PowerShell: $($platform.PSVersion)" 'White'
    Write-ColorOutput "   Architecture: $($platform.Architecture)" 'White'
    Write-ColorOutput "   GUI Available: $($platform.GUI)" 'White'
    Write-ColorOutput "" 'White'
}

function Get-ComponentUrls {
    $baseUrl = "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD"
    
    return @{
        'launcher' = @{
            'launcher.py' = "$baseUrl/launcher.py"
        }
        'gui' = @{
            'gui.py' = "$baseUrl/gui.py"
        }
        'deploy' = @{
            'deploy.py' = "$baseUrl/deploy.py"
        }
        'all' = @{
            'launcher.py' = "$baseUrl/launcher.py"
            'gui.py' = "$baseUrl/gui.py"
            'deploy.py' = "$baseUrl/deploy.py"
            'README.md' = "$baseUrl/README.md"
        }
    }
}

function Install-Components {
    param([string]$ComponentType)
    
    $urls = Get-ComponentUrls
    $componentUrls = $urls[$ComponentType]
    
    if (-not $componentUrls) {
        Write-ColorOutput "[FAIL] Unknown component: $ComponentType" 'Red'
        return $false
    }
    
    $allSuccess = $true
    foreach ($file in $componentUrls.Keys) {
        $url = $componentUrls[$file]
        if (-not (Download-File -Url $url -DestinationPath $file)) {
            $allSuccess = $false
        }
    }
    
    return $allSuccess
}

function Test-PythonAvailability {
    $pythonCommands = @('python3', 'python')
    
    foreach ($cmd in $pythonCommands) {
        try {
            $version = & $cmd --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $version -match 'Python 3\.\d+') {
                Write-ColorOutput "[PASS] Python found: $version" 'Green'
                return $cmd
            }
        }
        catch {
            # Command not found, continue
        }
    }
    
    Write-ColorOutput "[WARN]  Python 3.7+ not found" 'Yellow'
    return $null
}

function Show-PostInstallInstructions {
    param([string]$PythonCmd)
    
    Write-ColorOutput "" 'White'
    Write-ColorOutput " Next Steps:" 'Green'
    
    if ($PythonCmd) {
        Write-ColorOutput "   1. Run: $PythonCmd launcher.py" 'White'
        Write-ColorOutput "   2. Select 'Deploy Lab Environment' for first-time setup" 'White'
        Write-ColorOutput "   3. Use 'Launch GUI Interface' for graphical management" 'White'
    } else {
        Write-ColorOutput "   1. Install Python 3.7+ from:" 'White'
        $platform = Get-PlatformInfo
        if ($platform.OS -eq 'Win32NT') {
            Write-ColorOutput "      https://www.python.org/downloads/" 'White'
            Write-ColorOutput "      (Make sure to check 'Add Python to PATH')" 'White'
        } else {
            Write-ColorOutput "      • Ubuntu/Debian: sudo apt install python3" 'White'
            Write-ColorOutput "      • CentOS/RHEL: sudo yum install python3" 'White'
            Write-ColorOutput "      • macOS: brew install python3" 'White'
        }
        Write-ColorOutput "   2. Run: python launcher.py" 'White'
    }
    
    Write-ColorOutput "" 'White'
    Write-ColorOutput "� Available Commands:" 'Blue'
    Write-ColorOutput "   launcher.py          # Interactive menu" 'White'
    Write-ColorOutput "   launcher.py deploy   # Deploy lab environment" 'White'
    Write-ColorOutput "   launcher.py gui      # Launch GUI interface" 'White'
    Write-ColorOutput "   launcher.py health   # Run health check" 'White'
}

function main {
    Show-Header
    Show-PlatformInfo
    
    # Check internet connectivity
    Write-ColorOutput "� Checking internet connectivity..." 'Blue'
    if (-not (Test-InternetConnectivity)) {
        Write-ColorOutput "[FAIL] No internet connection. Please check your network." 'Red'
        return 1
    }
    Write-ColorOutput "[PASS] Internet connection confirmed" 'Green'
    Write-ColorOutput "" 'White'
    
    # Download components
    Write-ColorOutput "� Downloading components..." 'Blue'
    if (-not (Install-Components -ComponentType $Component)) {
        Write-ColorOutput "[FAIL] Download failed. Please try again later." 'Red'
        return 1
    }
    
    Write-ColorOutput "" 'White'
    Write-ColorOutput "[PASS] Download completed successfully!" 'Green'
    
    # Check Python
    $pythonCmd = Test-PythonAvailability
    
    # Show instructions
    Show-PostInstallInstructions -PythonCmd $pythonCmd
    
    # Auto-launch if not in NoMenu mode and Python is available
    if (-not $NoMenu -and $pythonCmd -and (Test-Path 'launcher.py')) {
        Write-ColorOutput "" 'White'
        Write-ColorOutput " Launching interactive menu..." 'Green'
        & $pythonCmd 'launcher.py'
    }
    
    return 0
}

# Run the installer
exit (main)

Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"

if (-not (Get-Command Convert-CerToPem -ErrorAction SilentlyContinue)) {
function Convert-CerToPem {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CerPath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PemPath
    )
    if (-not $PSCmdlet.ShouldProcess($PemPath, 'Create PEM file')) { return }

    $bytes = [System.IO.File]::ReadAllBytes($CerPath)

    $b64   = [System.Convert]::ToBase64String($bytes, 'InsertLineBreaks')
    "-----BEGIN CERTIFICATE-----`n$b64`n-----END CERTIFICATE-----" | Set-Content -Path $PemPath
}
}

if (-not (Get-Command Convert-PfxToPem -ErrorAction SilentlyContinue)) {
function Convert-PfxToPem {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PfxPath,
        [securestring]$Password,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CertPath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath
    )
    if (-not $PSCmdlet.ShouldProcess($PfxPath, 'Convert PFX to PEM')) { return }
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($PfxPath,$Password,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    $certB64   = [System.Convert]::ToBase64String($certBytes,'InsertLineBreaks')
    if ($PSCmdlet.ShouldProcess($CertPath, 'Write certificate PEM')) {
        "-----BEGIN CERTIFICATE-----`n$certB64`n-----END CERTIFICATE-----" | Set-Content -Path $CertPath
    }
    $rsa = $cert.GetRSAPrivateKey()
    $keyBytes = $rsa.ExportPkcs8PrivateKey()
    $keyB64   = [System.Convert]::ToBase64String($keyBytes,'InsertLineBreaks')
    if ($PSCmdlet.ShouldProcess($KeyPath, 'Write key PEM')) {
        "-----BEGIN PRIVATE KEY-----`n$keyB64`n-----END PRIVATE KEY-----" | Set-Content -Path $KeyPath
    }
}
}

if (-not (Get-Command Get-HyperVProviderVersion -ErrorAction SilentlyContinue)) {
function Get-HyperVProviderVersion {
    [CmdletBinding()]
    param(
        [string]$MainTfPath
    )

    $defaultVersion = '1.2.1'
    $searchPaths = @()

    if ($MainTfPath) { $searchPaths += $MainTfPath }
    $searchPaths += Join-Path $PSScriptRoot '..\example-infrastructure\main.tf'
    $searchPaths += Join-Path $PSScriptRoot '..\main.tf'

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $content = Get-Content -Path $path -Raw
            if ($content -match 'hyperv\s*=\s*\{[^\}]*?version\s*=\s*"([^"]+)"') {
                return $matches[1]
            }
            Write-Warning "Failed to parse hyperv provider version from $path"
            return $defaultVersion
        }
    }

    Write-Warning "main.tf not found. Using default Hyper-V provider version $defaultVersion"
    return $defaultVersion
}
}

if ($MyInvocation.InvocationName -ne '.') {
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0010_Prepare-HyperVProvider.ps1'

if ($Config.PrepareHyperVHost -eq $true) {

# Use Config to find the infra repo path early so certificate
# operations can copy files correctly.
    $infraRepoPath = if ([string]::IsNullOrWhiteSpace($Config.InfraRepoPath)) {
        Join-Path $PSScriptRoot "my-infra"
    } else {
        $Config.InfraRepoPath
    }



# ------------------------------
# 1) Environment Preparation
# ------------------------------

# Check if Hyper-V feature is enabled
$hvFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
if ($hvFeature.State -ne "Enabled") {
    Write-CustomLog "Enabling Hyper-V feature..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
} else {
    Write-CustomLog "Hyper-V is already enabled."
}

# Check if WinRM is enabled by testing the local WSMan endpoint
try {
    Test-WSMan -ComputerName localhost -ErrorAction Stop | Out-Null
    Write-CustomLog "WinRM is already enabled."
}
catch {
    Write-CustomLog "Enabling WinRM..."
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
}

# Check and set WinRS MaxMemoryPerShellMB to 1024 if needed
$currentMaxMemory = (Get-WSManInstance -ResourceURI winrm/config/WinRS).MaxMemoryPerShellMB
if ($currentMaxMemory -ne 1024) {
    Write-CustomLog "Setting WinRS MaxMemoryPerShellMB to 1024..."
    Set-WSManInstance -ResourceURI winrm/config/WinRS -ValueSet @{MaxMemoryPerShellMB = 1024}
}
else {
    Write-CustomLog "WinRS MaxMemoryPerShellMB is already 1024."
}

# Check and set WinRM MaxTimeoutms to 1800000 if needed
$currentTimeout = (Get-WSManInstance -ResourceURI winrm/config).MaxTimeoutms
if ($currentTimeout -ne 1800000) {
    Write-CustomLog "Setting WinRM MaxTimeoutms to 1800000..."
    Set-WSManInstance -ResourceURI winrm/config -ValueSet @{MaxTimeoutms = 1800000}
}
else {
    Write-CustomLog "WinRM MaxTimeoutms is already 1800000."
}

# Check and set TrustedHosts to "*" for the WinRM client if needed
$currentTrustedHosts = (Get-WSManInstance -ResourceURI winrm/config/Client).TrustedHosts
if ($currentTrustedHosts -ne "*") {
    Write-CustomLog "Setting TrustedHosts to '*'..."
    try {
        Set-WSManInstance -ResourceURI winrm/config/Client -ValueSet @{TrustedHosts = "*"}
    }
    catch {
        Write-CustomLog "TrustedHosts is set by policy."
    }
}
else {
    Write-CustomLog "TrustedHosts is already set to '*'."
}

# Check and set Negotiate to True in WinRM service auth if needed
$currentNegotiate = (Get-WSManInstance -ResourceURI winrm/config/Service/Auth).Negotiate
if (-not $currentNegotiate) {
    Write-CustomLog "Setting Negotiate to True..."
    Set-WSManInstance -ResourceURI winrm/config/Service/Auth -ValueSet @{Negotiate = $true}
}
else {
    Write-CustomLog "Negotiate is already set to True."
}

# ------------------------------
# 2) Configure WinRM HTTPS
# ------------------------------

$rootCaName = $config.CertificateAuthority.CommonName
$UserInput = Read-Host -Prompt "Enter the password for the Root CA certificate" -AsSecureString
$rootCaPassword = $UserInput
$rootCaCertificate = Get-ChildItem cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=$rootCaName"}

if (-not $rootCaCertificate) {
    $cerPath = ".\$rootCaName.cer"
    $pfxPath = ".\$rootCaName.pfx"
    $cerExists = Test-Path $cerPath
    $pfxExists = Test-Path $pfxPath

    if ($cerExists -and $pfxExists) {
        Write-CustomLog "Importing existing Root CA certificates..."
        Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -eq "CN=$rootCaName"} | Remove-Item -Force -ErrorAction SilentlyContinue
        Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\Root -Password $rootCaPassword -Exportable -Verbose | Out-Null
        Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\My -Password $rootCaPassword -Exportable -Verbose | Out-Null
        $rootCaCertificate = Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -eq "CN=$rootCaName"}
    } else {
        # Cleanup if present
        Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -eq "CN=$rootCaName"} | Remove-Item -Force -ErrorAction SilentlyContinue
        if ($cerExists) { Remove-Item $cerPath -Force -ErrorAction SilentlyContinue }
        if ($pfxExists) { Remove-Item $pfxPath -Force -ErrorAction SilentlyContinue }

        $params = @{
            Type              = 'Custom'
            DnsName           = $rootCaName
            Subject           = "CN=$rootCaName"
            KeyExportPolicy   = 'Exportable'
            CertStoreLocation = 'Cert:\LocalMachine\My'
            KeyUsageProperty  = 'All'
            KeyUsage          = 'None'
            Provider          = 'Microsoft Strong Cryptographic Provider'
            KeySpec           = 'KeyExchange'
            KeyLength         = 4096
            HashAlgorithm     = 'SHA256'
            KeyAlgorithm      = 'RSA'
            NotAfter          = (Get-Date).AddYears(5)
        }

        Write-CustomLog "Creating Root CA..."
        $rootCaCertificate = New-SelfSignedCertificate @params

        Export-Certificate -Cert $rootCaCertificate -FilePath $cerPath -Verbose
        Export-PfxCertificate -Cert $rootCaCertificate -FilePath $pfxPath -Password $rootCaPassword -Verbose

        # Re-import to Root store & My store
        Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -eq "CN=$rootCaName"} | Remove-Item -Force -ErrorAction SilentlyContinue
        Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\Root -Password $rootCaPassword -Exportable -Verbose | Out-Null
        Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\My -Password $rootCaPassword -Exportable -Verbose | Out-Null

        $rootCaCertificate = Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -eq "CN=$rootCaName"}
    }
} else {
    Export-Certificate -Cert $rootCaCertificate -FilePath ".\$rootCaName.cer" -Force -Verbose
    Export-PfxCertificate -Cert $rootCaCertificate -FilePath ".\$rootCaName.pfx" -Password $rootCaPassword -Force -Verbose
}

# Create Host Certificate
$hostName      = [System.Net.Dns]::GetHostName()
$UserInput = Read-Host -Prompt "Enter the password for the host." -AsSecureString
$hostPassword = $UserInput
$hostCertificate = Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=$hostName"}

if (-not $hostCertificate) {
    # Cleanup if present
    Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -eq "CN=$hostName"} | Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Item ".\$hostName.cer" -Force -ErrorAction SilentlyContinue
    Remove-Item ".\$hostName.pfx" -Force -ErrorAction SilentlyContinue

    $dnsNames = @($hostName, "localhost", "127.0.0.1") + [System.Net.Dns]::GetHostByName($env:ComputerName).AddressList.IPAddressToString
    $params = @{
        Type              = 'Custom'
        DnsName           = $dnsNames
        Subject           = "CN=$hostName"
        KeyExportPolicy   = 'Exportable'
        CertStoreLocation = 'Cert:\LocalMachine\My'
        KeyUsageProperty  = 'All'
        KeyUsage          = @('KeyEncipherment','DigitalSignature','NonRepudiation')
        TextExtension     = @("2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2")
        Signer            = $rootCaCertificate
        Provider          = 'Microsoft Strong Cryptographic Provider'
        KeySpec           = 'KeyExchange'
        KeyLength         = 2048
        HashAlgorithm     = 'SHA256'
        KeyAlgorithm      = 'RSA'
        NotAfter          = (Get-Date).AddYears(2)
    }

    Write-CustomLog "Creating host certificate..."
    $hostCertificate = New-SelfSignedCertificate @params

    Export-Certificate -Cert $hostCertificate -FilePath ".\$hostName.cer" -Verbose
    Export-PfxCertificate -Cert $hostCertificate -FilePath ".\$hostName.pfx" -Password $hostPassword -Verbose

    Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=$hostName"} | Remove-Item -Force -ErrorAction SilentlyContinue
    Import-PfxCertificate -FilePath ".\$hostName.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $hostPassword -Exportable -Verbose

    $hostCertificate = Get-ChildItem cert:\LocalMachine\My | Where-Object {$_.subject -eq "CN=$hostName"}
} else {
    Export-Certificate -Cert $hostCertificate -FilePath ".\$hostName.cer" -Force -Verbose
    Export-PfxCertificate -Cert $hostCertificate -FilePath ".\$hostName.pfx" -Password $hostPassword -Force -Verbose
}

    Convert-CerToPem -CerPath ".\$rootCaName.cer" -PemPath ".\$rootCaName.pem"
    Convert-PfxToPem -PfxPath ".\$hostName.pfx" -Password $hostPassword -CertPath ".\$hostName.pem" -KeyPath ".\$hostName-key.pem"

    Copy-Item ".\$rootCaName.pem" -Destination (Join-Path $infraRepoPath "$rootCaName.pem") -Force
    Copy-Item ".\$hostName.pem" -Destination (Join-Path $infraRepoPath "$hostName.pem") -Force
    Copy-Item ".\$hostName-key.pem" -Destination (Join-Path $infraRepoPath "$hostName-key.pem") -Force

Write-CustomLog "Configuring WinRM HTTPS listener..."
Get-ChildItem wsman:\localhost\Listener\ | Where-Object -Property Keys -eq 'Transport=HTTPS' | Remove-Item -Recurse -ErrorAction SilentlyContinue
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $($hostCertificate.Thumbprint) -Force -Verbose
Restart-Service WinRM -Verbose -Force

Write-CustomLog "Allowing HTTPS (5986) through firewall..."
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "WinRMHTTPSIn" -Profile Any -LocalPort 5986 -Protocol TCP -Verbose

# ------------------------------
# 3) Configure WinRM HTTP (optional)
# ------------------------------
<#
$PubNets = Get-NetConnectionProfile -NetworkCategory Public -ErrorAction SilentlyContinue
foreach ($PubNet in $PubNets) {
    Set-NetConnectionProfile -InterfaceIndex $PubNet.InterfaceIndex -NetworkCategory Private
}

Set-WSManInstance WinRM/Config/Service -ValueSet @{AllowUnencrypted = $true}

foreach ($PubNet in $PubNets) {
    Set-NetConnectionProfile -InterfaceIndex $PubNet.InterfaceIndex -NetworkCategory Public
}

Get-ChildItem wsman:\localhost\Listener\ | Where-Object -Property Keys -eq 'Transport=HTTP' | Remove-Item -Recurse -ErrorAction SilentlyContinue
New-Item -Path WSMan:\localhost\Listener -Transport HTTP -Address * -Force -Verbose
Restart-Service WinRM -Verbose -Force

Write-CustomLog "Allowing HTTP (5985) through firewall..."
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Name "WinRMHTTPIn" -Profile Any -LocalPort 5985 -Protocol TCP -Verbose
#>

# ------------------------------
# 4) Build & Install Hyper-V Provider in InfraRepoPath
# ------------------------------


# infraRepoPath is already set earlier; ensure it exists before build
$null = New-Item -ItemType Directory -Force -Path $infraRepoPath -ErrorAction SilentlyContinue

Write-CustomLog "InfraRepoPath for hyperv provider: $infraRepoPath"

Write-CustomLog "Setting up Go environment..."
$goWorkspace = "C:\\GoWorkspace"
$env:GOPATH = $goWorkspace
[System.Environment]::SetEnvironmentVariable('GOPATH', $goWorkspace, 'User')

Write-CustomLog "Ensuring taliesins provider dir structure..."
$taliesinsDir = Join-Path -Path $env:GOPATH -ChildPath "src\\github.com\\taliesins"
if (!(Test-Path $taliesinsDir)) {
    New-Item -ItemType Directory -Force -Path $taliesinsDir | Out-Null
}
Push-Location
try {
    Set-Location $taliesinsDir

# Define the provider directory/exe
$providerDir     = Join-Path $taliesinsDir "terraform-provider-hyperv"
$providerExePath = Join-Path $providerDir  "terraform-provider-hyperv.exe"

Write-CustomLog "Checking if we need to clone or rebuild the hyperv provider..."
if (!(Test-Path $providerExePath)) {
    Write-CustomLog "Provider exe not found; cloning from GitHub..."
    git clone https://github.com/taliesins/terraform-provider-hyperv.git
}
Set-Location $providerDir

Write-CustomLog "Building hyperv provider with go..."
go build -o terraform-provider-hyperv.exe

# Determine provider version from example-infrastructure/main.tf
try {
    $providerVersion = Get-HyperVProviderVersion
    Write-CustomLog "Using Hyper-V provider version $providerVersion"
} catch {
    Write-Warning $_
    $providerVersion = '1.2.1'
    Write-CustomLog "Falling back to Hyper-V provider version $providerVersion"
}

$hypervProviderDir = Join-Path $infraRepoPath ".terraform\\providers\\registry.opentofu.org\\taliesins\\hyperv\\$providerVersion"
if (!(Test-Path $hypervProviderDir)) {
    New-Item -ItemType Directory -Force -Path $hypervProviderDir | Out-Null
}

Write-CustomLog "Copying provider exe -> $hypervProviderDir"
$destinationBinary = Join-Path $hypervProviderDir "terraform-provider-hyperv.exe"
Copy-Item -Path $providerExePath -Destination $destinationBinary -Force -Verbose

Write-CustomLog "Hyper-V provider installed at: $destinationBinary"
}
finally {
    # Restore the original directory even if build fails
    Pop-Location
}

# ------------------------------
# 5) Update Provider Config File (providers.tf)
# ------------------------------
$tfFile = Join-Path -Path $infraRepoPath -ChildPath "providers.tf"
if (Test-Path $tfFile) {
    Write-CustomLog "Updating providers configuration in providers.tf with certificate paths..."

    $rootCAPath   = (Resolve-Path (Join-Path -Path $infraRepoPath -ChildPath "$rootCaName.pem")).Path
    $hostCertPath = (Resolve-Path (Join-Path -Path $infraRepoPath -ChildPath "$hostName.pem")).Path
    $hostKeyPath  = (Resolve-Path (Join-Path -Path $infraRepoPath -ChildPath "$hostName-key.pem")).Path

    $escapedRootCAPath   = $rootCAPath.Replace('\\', '\\\\')
    $escapedHostCertPath = $hostCertPath.Replace('\\', '\\\\')
    $escapedHostKeyPath  = $hostKeyPath.Replace('\\', '\\\\')

    $content = Get-Content $tfFile -Raw
    $content = $content -replace '(insecure\s*=\s*)(true|false)', '${1}false'
    $content = $content -replace '(tls_server_name\s*=\s*")[^"]*"', '${1}' + $hostName + '"'
    $content = $content -replace '(cacert_path\s*=\s*")[^"]*"', '${1}' + $escapedRootCAPath + '"'
    $content = $content -replace '(cert_path\s*=\s*")[^"]*"', '${1}' + $escapedHostCertPath + '"'
    $content = $content -replace '(key_path\s*=\s*")[^"]*"', '${1}' + $escapedHostKeyPath + '"'
    Set-Content -Path $tfFile -Value $content
    Write-CustomLog "Updated providers.tf successfully."
} else {
    Write-CustomLog "providers.tf not found in $infraRepoPath; skipping provider config update."
}
Write-CustomLog @"
Done preparing Hyper-V host and installing the provider.
You can now run 'tofu plan'/'tofu apply' in $infraRepoPath.
"@
} else {
    Write-CustomLog "PrepareHyperVHost flag is disabled. Skipping Hyper-V host preparation."
}
}
}

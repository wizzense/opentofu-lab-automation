Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

if ($Config.InstallCA -eq $true) {
Write-Log "Checking for existing Certificate Authority (Standalone Root CA)..."

# Only proceed if you actually want to install a CA.
if ($null -eq $Config.CertificateAuthority) {
    Write-Log "No CA config found. Skipping CA installation."
    return
}

$CAName        = $Config.CertificateAuthority.CommonName
$ValidityYears = $Config.CertificateAuthority.ValidityYears

if (-not $CAName) {
    Write-Log "Missing CAName in config. Skipping CA installation."
    return
}

# Check if the CA role is already installed
$role = Get-WindowsFeature -Name Adcs-Cert-Authority
if ($role.Installed) {
    Write-Log "Certificate Authority role is already installed. Checking CA configuration..."
    
    # Check if a CA is already configured
    $existingCA = Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration' -ErrorAction SilentlyContinue
    if ($existingCA) {
        Write-Log "A Certificate Authority is already configured. Skipping installation."
        return
    }

    Write-Log "CA role is installed but no CA is configured. Proceeding with installation."
} else {
    Write-Log "Installing Certificate Authority role..."
    Install-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools -ErrorAction Stop
}

# If the script reaches this point, it means no existing CA is detected, and installation should proceed.
Write-Log "Configuring CA: $CAName with $($ValidityYears) year validity..."

Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `
    -CACommonName $CAName `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits $ValidityYears `
    -Force

Write-Log "Standalone Root CA '$CAName' installation complete."

}
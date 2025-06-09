Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

if ($Config.InstallCA -eq $true) {
Write-CustomLog "Checking for existing Certificate Authority (Standalone Root CA)..."

# Only proceed if you actually want to install a CA.
if ($null -eq $Config.CertificateAuthority) {
    Write-CustomLog "No CA config found. Skipping CA installation."
    return
}

$CAName        = $Config.CertificateAuthority.CommonName
$ValidityYears = $Config.CertificateAuthority.ValidityYears

if (-not $CAName) {
    Write-CustomLog "Missing CAName in config. Skipping CA installation."
    return
}

# Check if the CA role is already installed
$role = Get-WindowsFeature -Name Adcs-Cert-Authority
if ($role.Installed) {
    Write-CustomLog "Certificate Authority role is already installed. Checking CA configuration..."
    
    # Check if a CA is already configured
    $existingCA = Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration' -ErrorAction SilentlyContinue
    if ($existingCA) {
        Write-CustomLog "A Certificate Authority is already configured. Skipping installation."
        return
    }

    Write-CustomLog "CA role is installed but no CA is configured. Proceeding with installation."
} else {
    Write-CustomLog "Installing Certificate Authority role..."
    Install-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools -ErrorAction Stop
}

# If the script reaches this point, it means no existing CA is detected, and installation should proceed.
Write-CustomLog "Configuring CA: $CAName with $($ValidityYears) year validity..."

Install-AdcsCertificationAuthority `
    -CAType StandaloneRootCA `
    -CACommonName $CAName `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -ValidityPeriod Years `
    -ValidityPeriodUnits $ValidityYears `
    -Force

Write-CustomLog "Standalone Root CA '$CAName' installation complete."

} else {
    Write-CustomLog "InstallCA flag is disabled. Skipping CA installation."
}
}


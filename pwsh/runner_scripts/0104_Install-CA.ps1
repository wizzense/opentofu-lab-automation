Param([object]$Config)







Import-Module "/pwsh/modules/LabRunner/"  -Force
Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-CA {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    






Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

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
    if ($PSCmdlet.ShouldProcess('ADCS role', 'Install CA Windows feature')) {
        Install-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools -ErrorAction Stop
    }
}

# If the script reaches this point, it means no existing CA is detected, and installation should proceed.
Write-CustomLog "Configuring CA: $CAName with $($ValidityYears) year validity..."

if ($PSCmdlet.ShouldProcess($CAName, 'Configure Standalone Root CA')) {
    # Resolve the cmdlet after any Pester mocks have been defined

    $installCmd = Get-Command Install-AdcsCertificationAuthority -ErrorAction SilentlyContinue
    if (-not $installCmd) {
        if (Get-Module -ListAvailable -Name ADCSDeployment) {
            $installCmd = Get-Command Install-AdcsCertificationAuthority -ErrorAction SilentlyContinue
        }
    }
    if (-not $installCmd) {
        Write-CustomLog 'Install-AdcsCertificationAuthority command not found. Ensure AD CS features are available.'
        return
    }
    & $installCmd `
        -CAType StandaloneRootCA `
        -CACommonName $CAName `
        -KeyLength 2048 `
        -HashAlgorithm SHA256 `
        -ValidityPeriod Years `
        -ValidityPeriodUnits $ValidityYears `
        -Force
}

Write-CustomLog "Standalone Root CA '$CAName' installation complete."

} else {
    Write-CustomLog "InstallCA flag is disabled. Skipping CA installation."
}
}
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
if ($MyInvocation.InvocationName -ne '.') { Install-CA @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
















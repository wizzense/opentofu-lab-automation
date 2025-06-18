
<#

# Define local paths for the installer files.
$adkInstaller    = Join-Path $PSScriptRoot "adksetup.exe"
$peAddonInstaller = Join-Path $PSScriptRoot "adkwinpesetup.exe"

# Install Windows ADK silently.
Write-CustomLog "Installing Windows ADK for Server 2025..."
try {
    Start-Process -FilePath $adkInstaller -ArgumentList "/quiet", "/norestart", "/features optionid.deploymenttools optionid.userstatemigrationtool" -Wait -ErrorAction Stop
    Write-CustomLog "Windows ADK installation complete."
}
catch {
    Write-Error "Installation of Windows ADK failed: $_"
    exit 1
}

# Install Windows PE Add-on silently.
Write-CustomLog "Installing Windows PE Add-on for Windows ADK..."
try {
    Start-Process -FilePath $peAddonInstaller -ArgumentList "/quiet", "/norestart" -Wait -ErrorAction Stop
    Write-CustomLog "Windows PE Add-on installation complete."
}
catch {
    Write-Error "Installation of Windows PE Add-on failed: $_"
    exit 1
}


Mount-DiskImage -ImagePath "E:\2_auto_unattend_en-us_windows_server_2025_updated_feb_2025_x64_dvd_3733c10e.iso"
robocopy H:\ E:\CustomISO\ /E
if (-not (Test-Path E:\Mount)) { New-Item -ItemType Directory -Path E:\Mount -Force | Out-Null }
dism /mount-image /ImageFile:E:\CustomISO\sources\install.wim /Index:3 /MountDir:E:\Mount
copy-item "C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\bootstrap.ps1" E:\mount\Windows\bootstrap.ps1
Copy-Item $UnattendXML -Destination "E:\Mount\Windows\autounattend.xml" -Force
dism /Unmount-Image /MountDir:E:\Mount /Commit
Set-Location -path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
.\oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,bE:\CustomISO\boot\etfsboot.com#pEF,e,bE:\CustomISO\efi\microsoft\boot\efisys.bin E:\CustomISO E:\CustomWinISO.iso
Dismount-DiskImage -ImagePath "E:\2_auto_unattend_en-us_windows_server_2025_updated_feb_2025_x64_dvd_3733c10e.iso"
#>

# Script parameters with sensible defaults so the script can be reused
param(
    string$ISOPath = "E:\2_auto_unattend_en-us_windows_server_2025_updated_feb_2025_x64_dvd_3733c10e.iso",
    string$ExtractPath = "E:\CustomISO",
    string$MountPath = "E:\Mount",
    string$SetupScript = "E:\bootstrap.ps1",
    string$UnattendXML = "E:\Path\to\autounattend.xml",
    string$OutputISO = "E:\CustomWinISO.iso",
    string$OscdimgExe = "C:\Program Files (x86)






\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    int$WIMIndex = 3
)

# Ensure target paths exist for extraction and mounting
if (Test-Path $MountPath) {
    Remove-Item -Recurse -Force $MountPath
}
if (-not (Test-Path $ExtractPath)) { New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null }

# Derived path to the WIM file inside the extracted ISO
$WIMFile = Join-Path $ExtractPath "sources\install.wim"

# Ensure running as Administrator
if (-not (Security.Principal.WindowsPrincipal Security.Principal.WindowsIdentity::GetCurrent()).IsInRole(Security.Principal.WindowsBuiltInRole "Administrator")) {

    $scriptPath = $PSCommandPath
    $warnMsg1 = "This script requires administrator privileges."
    Write-CustomLog $warnMsg1 -Level WARN
    Write-Host $warnMsg1 -ForegroundColor Red

    $warnMsg2 = 'Rerun using: Start-Process -FilePath (Get-Process -Id `$PID).Path -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -Verb RunAs -ErrorAction Stop' -f $scriptPath

    Write-CustomLog $warnMsg2 -Level WARN
    Write-Host $warnMsg2 -ForegroundColor Yellow
    if ($scriptPath) {
        try {
            Start-Process -FilePath (Get-Process -Id $PID).Path `

                -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $scriptPath) `

                -Verb RunAs -ErrorAction Stop
            exit
        } catch {
            Write-Warning "Automatic elevation failed: $_"
        }
    }

    Write-CustomLog "Please run this script as Administrator!"

    exit
}

# Step 1: Mount the Windows ISO
Write-CustomLog "Mounting Windows ISO..."
$ISO = Mount-DiskImage -ImagePath $ISOPath -PassThru
$DriveLetter = (Get-Volume -DiskImage $ISO).DriveLetter + ":"

# Step 2: Extract ISO contents
Write-CustomLog "Extracting ISO contents to $ExtractPath..."
if (-not (Test-Path $ExtractPath)) { New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null }
dism /Mount-Image /ImageFile:$WIMFile /Index:$WIMIndex /MountDir:$MountPath

# Step 5: Copy bootstrap.ps1 into Windows
Write-CustomLog "Copying setup.ps1 into Windows..."
Copy-Item $SetupScript -Destination "$MountPath\Windows\bootstrap.ps1" -Force

# Step 6: Commit Changes & Unmount WIM
Write-CustomLog "Committing changes and unmounting install.wim..."
dism /Unmount-Image /MountDir:$MountPath /Commit

# Step 7: Add autounattend.xml to ISO root
Write-CustomLog "Copying autounattend.xml to ISO root..."
Copy-Item $UnattendXML -Destination "$ExtractPath\autounattend.xml" -Force

# Step 8: Recreate Bootable ISO
Write-CustomLog "Recreating bootable ISO..."
Start-Process -FilePath $OscdimgExe -ArgumentList @(
    "-m",
    "-o",
    "-u2",
    "-udfver102",
    "-bootdata:2#p0,e,b`"$ExtractPath\boot\etfsboot.com`"#pEF,e,b`"$ExtractPath\efi\microsoft\boot\efisys.bin`"",
    "`"$ExtractPath`"",
    "`"$OutputISO`""
) -NoNewWindow -Wait

Write-CustomLog "Custom ISO creation complete! New ISO saved as $OutputISO"








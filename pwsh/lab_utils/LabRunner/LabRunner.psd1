@{
    RootModule = 'LabRunner.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c0000000-0000-4000-8000-000000000001'
    NestedModules = @('../LabSetup/LabSetup.psd1')
    Author = 'OpenTofu'
    FunctionsToExport = @('Invoke-LabStep','Invoke-LabDownload','Write-CustomLog','Read-LoggedInput','Get-Platform','Invoke-LabWebRequest','Invoke-LabNpm','Invoke-OpenTofuInstaller')
}

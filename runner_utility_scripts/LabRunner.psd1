@{
    RootModule = 'LabRunner.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c0000000-0000-4000-8000-000000000001'
        NestedModules = @('../lab_utils/LabSetup/LabSetup.psd1')
    Author = 'OpenTofu'
    FunctionsToExport = @('Invoke-LabStep','Write-CustomLog','Read-LoggedInput','Get-Platform','Get-LabConfig')
}

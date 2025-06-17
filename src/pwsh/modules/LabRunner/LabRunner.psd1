

@{
    RootModule = 'LabRunner.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c0000000-0000-4000-8000-000000000001'
    NestedModules = @('Resolve-ProjectPath.psm1')
    Author = 'OpenTofu'
    FunctionsToExport = @(
        'Invoke-LabStep',
        'Invoke-LabDownload',
        'Write-CustomLog',
        'Read-LoggedInput',
        'Get-Platform',
        'Invoke-LabWebRequest',
        'Invoke-LabNpm',
        'Invoke-OpenTofuInstaller',
        'Resolve-ProjectPath',
        'Invoke-ArchiveDownload',
        'Format-Config',
        'Expand-All',
        'Get-MenuSelection',        'Get-GhDownloadArgs',
        'Get-LabConfig',
        'Test-IsAdmin',
        'Invoke-ParallelLabRunner',
        'Test-ParallelRunnerSupport'
    )
}


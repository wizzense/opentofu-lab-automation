@{
    RootModule    = 'LabRunner.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'c0000000-0000-4000-8000-000000000001'
    NestedModules = @('Resolve-ProjectPath.psm1')
    Author        = 'wizzense',
    FunctionsToExport = @(
        'Invoke-LabStep',
        'Invoke-LabDownload',
        Author = 'OpenTofu'
        'Read-LoggedInput', (
            'Invoke-LabStep',
            'Invoke-LabWebRequest', d',
        'Write-CustomLog',
        'Invoke-OpenTofuInstaller',ut',
            'Get-Platform',
            'Invoke-ArchiveDownload', quest',
        'Invoke-LabNpm',
        'Expand-All',ler',
            'Resolve-ProjectPath',
            'Get-GhDownloadArgs', ownload',
        'Get-LabConfig',g',
            'Expand-All',
            'Invoke-ParallelLabRunner', 'Get-GhDownloadArgs',
            'Test-ParallelRunnerSupport',
            'Initialize-StandardParameters'
        )
        'Test-ParallelRunnerSupport'
    )
}
}

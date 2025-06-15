@{
    RootModule = 'PatchManager.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'e4c7e8f5-5f4d-41ae-a89c-b2b86c5295a1'
    Author = 'OpenTofu Lab Automation Team'
    CompanyName = 'OpenTofu'
    Copyright = '(c) 2025 OpenTofu. All rights reserved.'
    Description = 'Module for managing patches, fixes, and maintenance tasks in the OpenTofu Lab Automation project'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Invoke-UnifiedMaintenance',
        'Invoke-YamlValidation',
        'Invoke-InfrastructureFix',
        'Invoke-ArchiveCleanup',
        'Show-MaintenanceReport',
        'Test-PatchingRequirements',
        'Invoke-RecurringIssueCheck',
        'Invoke-PatchCleanup',
        'Invoke-TestFileFix',
        'Invoke-SelfHeal',
        'New-ModuleValidationTests',
        'Invoke-GitControlledPatch',
        'Invoke-PatchValidation',
        'New-PatchPullRequest'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenTofu', 'Maintenance', 'Patching', 'YAML', 'Validation')
            LicenseUri = 'https://github.com/yourusername/opentofu-lab-automation/blob/main/LICENSE'
            ProjectUri = 'https://github.com/yourusername/opentofu-lab-automation'
            ReleaseNotes = 'Initial release of the PatchManager module.'
        }
    }
}

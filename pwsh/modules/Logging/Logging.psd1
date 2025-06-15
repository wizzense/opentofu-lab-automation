# Module manifest for module 'Logging'

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Logger.ps1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = '9c2f1c2e-6845-4bc0-ae24-a1f867c4d5f9'
    
    # Author of this module
    Author = 'OpenTofu Lab Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'OpenTofu Lab Automation Project'
    
    # Copyright statement for this module
    Copyright = '(c) 2024-2025 OpenTofu Lab Automation Project. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Standardized logging for the OpenTofu Lab Automation project'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Write-CustomLog', 
        'Read-LoggedInput', 
        'Set-LoggingPath', 
        'Merge-LogFiles', 
        'Set-LogVerbosity'
    )
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # Tags applied to this module. These help with module discovery in online galleries.
    Tags = @('Logging', 'OpenTofu', 'Lab', 'Automation')
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData = @{
        PSData = @{
            # Prerelease string of this module
            Prerelease = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of standardized logging module'
        }
    }
}

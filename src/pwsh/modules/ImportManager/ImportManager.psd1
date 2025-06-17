@{
    ModuleVersion = '1.0.0'
    GUID = 'f8a1b2c3-d4e5-f6a7-b8c9-d0e1f2a3b4c5'
    Author = 'OpenTofu Lab Automation'
    Description = 'Centralized module import manager with proper error handling and fallbacks'
    PowerShellVersion = '7.0'
    
    FunctionsToExport = @(
        'Import-ModuleWithFallback',
        'Import-LoggingModule', 
        'Import-PatchManagerModule',
        'Import-AllCoreModules',
        'Get-ImportStatus'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    RequiredModules = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Import', 'Module', 'ErrorHandling', 'Fallback')
        }
    }
}

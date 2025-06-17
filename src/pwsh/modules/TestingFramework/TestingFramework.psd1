@{
    RootModule = 'TestingFramework.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'OpenTofu Lab Automation Team'
    CompanyName = 'OpenTofu Lab Automation'
    Copyright = '(c) 2025 OpenTofu Lab Automation. All rights reserved.'
    Description = 'Unified testing framework consolidating all scattered testing functionality with VS Code integration'
    
    PowerShellVersion = '7.0'
    
    RequiredModules = @(
        @{ModuleName='Pester'; ModuleVersion='5.0.0'; Guid='a699dea5-2c73-4616-a270-1f7abb777e71'}
    )
    
    FunctionsToExport = @(
        'Invoke-UnifiedTestExecution',
        'Invoke-PesterTests', 
        'Invoke-PytestTests',
        'Invoke-SyntaxValidation'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Testing', 'Pester', 'Pytest', 'OpenTofu', 'VS Code', 'Automation')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release consolidating scattered testing scripts into unified framework'
        }
    }
}

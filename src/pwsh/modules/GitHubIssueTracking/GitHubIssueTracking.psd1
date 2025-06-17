@{
    RootModule = 'GitHubIssueTracking.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a4b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'OpenTofu Lab Automation'
    CompanyName = 'Wizzense'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'GitHub Issue Tracking Integration for PSScriptAnalyzer and Testing Framework'
    
    PowerShellVersion = '7.0'
    
    RequiredModules = @(
        @{
            ModuleName = 'PatchManager'
            ModuleVersion = '1.0.0'
        }
    )
    
    FunctionsToExport = @(
        'Get-GitHubIssue',
        'New-GitHubIssue', 
        'Update-GitHubIssue',
        'New-TestFailureIssue',
        'New-BuildFailureIssue',
        'Close-ResolvedIssues',
        'Test-IssueResolved',
        'Close-GitHubIssue'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('GitHub', 'Issues', 'Automation', 'PSScriptAnalyzer', 'Testing')
            ProjectUri = 'https://github.com/your-org/opentofu-lab-automation'
            ReleaseNotes = 'Initial release of GitHub Issue Tracking integration'
        }
    }
}

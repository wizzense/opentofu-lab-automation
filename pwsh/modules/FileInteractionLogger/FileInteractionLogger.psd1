@{
    RootModule = 'FileInteractionLogger.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'OpenTofu Lab Automation'
    Description = 'Comprehensive file interaction logging for tracking all file operations'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Start-FileInteractionLogging',
        'Stop-FileInteractionLogging', 
        'Write-FileInteractionLog',
        'Get-FileInteractionLog',
        'Set-Content',
        'Add-Content',
        'Get-Content',
        'Remove-Item',
        'Copy-Item',
        'Move-Item',
        'New-Item'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}

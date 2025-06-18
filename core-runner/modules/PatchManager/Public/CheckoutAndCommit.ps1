#Requires -Version 7.0

param(
    [string]$BranchName,
    [string]$BaseBranch = 'main',
    [string]$CommitMessage
)

Import-Module -Name "$(Join-Path $PSScriptRoot 'GitOperations.ps1')" -Force

try {
    # Create a new branch
    CreatePatchBranch -BranchName $BranchName -BaseBranch $BaseBranch
    Write-Host "Branch '$BranchName' created successfully." -ForegroundColor Green

    # Stage all changes
    git add -A
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to stage changes."
    }

    # Commit changes
    CommitChanges -CommitMessage $CommitMessage
    Write-Host "Changes committed successfully with message: '$CommitMessage'." -ForegroundColor Green
} catch {
    Write-Error "An error occurred: $_"
    throw
}

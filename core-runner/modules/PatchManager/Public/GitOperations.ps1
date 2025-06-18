function CreatePatchBranch {
    param(
        [string]$BranchName,
        [string]$BaseBranch
    )

    Write-Host "Creating patch branch: $BranchName from base branch: $BaseBranch" -ForegroundColor Cyan
    git checkout -b $BranchName $BaseBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create branch: $BranchName"
    }
}

function CommitChanges {
    param(
        [string]$CommitMessage
    )

    Write-Host "Committing changes..." -ForegroundColor Cyan
    git commit -m $CommitMessage
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to commit changes."
    }
}

CmdletBinding()
param(
    string$Repo = 'wizzense/opentofu-lab-automation',
    string$Workflow = 'pester.yml',
    long$RunId
)








$tempDir = Join-Path (System.IO.Path::GetTempPath()) "gh-artifacts-$(System.Guid::NewGuid())"
New-Item -ItemType Directory -Path tempDir | | Out-Null

$downloadArgs = @{}
. $PSScriptRoot/Download-Archive.ps1
$downloadArgs = Get-GhDownloadArgs
$useGh = $downloadArgs.ContainsKey('UseGh')

if ($useGh) {
    if ($RunId) {
        $artJson = gh api "repos/$Repo/actions/runs/$RunId/artifacts"
        if ($artJson) {
            $artifacts = (ConvertFrom-Json $artJson).artifacts
        } else {
            $artifacts = @()
        }
        $cov = artifacts | Where-Object { $_.name -match 'coverage.*windows-latest' }
        $res = artifacts | Where-Object { $_.name -match 'results.*windows-latest' }
        if ($res) {
            if ($cov) {
                Download-Archive $cov.archive_download_url (Join-Path $tempDir 'coverage.zip') @downloadArgs
            }
            Download-Archive $res.archive_download_url (Join-Path $tempDir 'results.zip') -Required @downloadArgs

        } else {
            Write-Host "No artifacts for windows-latest found on run $RunId. Use gh run view $RunId for details." -ForegroundColor Yellow
            exit 1
        }
    } else {
        $runsJson = gh api "repos/$Repo/actions/workflows/$Workflow/runs?branch=main&status=completed&per_page=10"
        $runs = if ($runsJson) { (ConvertFrom-Json $runsJson).workflow_runs    } else { @()    }

        $found = $false
        foreach ($run in $runs) {
            $artJson = gh api "repos/$Repo/actions/runs/$($run.id)/artifacts"
            $artifacts = if ($artJson) { (ConvertFrom-Json $artJson).artifacts    } else { @()    }
            $cov = artifacts | Where-Object { $_.name -match 'coverage.*windows-latest' }
            $res = artifacts | Where-Object { $_.name -match 'results.*windows-latest' }
            if ($res) {
                if ($cov) {
                    Download-Archive $cov.archive_download_url (Join-Path $tempDir 'coverage.zip') @downloadArgs
                }
                Download-Archive $res.archive_download_url (Join-Path $tempDir 'results.zip') -Required @downloadArgs

                $found = $true
                break
            }
        }

        if (-not $found) {
            Write-Host 'No artifacts found in recent Windows runs. Try specifying -RunId to select a specific run.' -ForegroundColor Yellow
            exit 1
        }
    }
} else {
    if ($RunId) {
        $covUrl = "https://nightly.link/$Repo/actions/runs/$RunId/pester-coverage-windows-latest.zip"
        $resUrl = "https://nightly.link/$Repo/actions/runs/$RunId/pester-results-windows-latest.zip"
    } else {
        $covUrl = "https://nightly.link/$Repo/workflows/$Workflow/main/pester-coverage-windows-latest.zip"
        $resUrl = "https://nightly.link/$Repo/workflows/$Workflow/main/pester-results-windows-latest.zip"
    }

    Download-Archive $covUrl (Join-Path $tempDir 'coverage.zip') @downloadArgs
    Download-Archive $resUrl (Join-Path $tempDir 'results.zip') -Required @downloadArgs

}

$covDir = Join-Path $tempDir 'coverage'
$resDir = Join-Path $tempDir 'results'
if (Test-Path (Join-Path $tempDir 'coverage.zip')) {
    Expand-Archive -Path (Join-Path $tempDir 'coverage.zip') -DestinationPath $covDir -Force
}
if (Test-Path (Join-Path $tempDir 'results.zip')) {
    Expand-Archive -Path (Join-Path $tempDir 'results.zip') -DestinationPath $resDir -Force
} else {
    Write-Host 'Results artifact was not downloaded.' -ForegroundColor Yellow
    exit 1
}

$resultsFile = Get-ChildItem -Path $resDir -Filter *.xml -Recurse  Select-Object -First 1
if (-not $resultsFile) {
    Write-Host 'Results file not found.' -ForegroundColor Yellow
    exit 1
}

$failed = Select-Xml -Path $resultsFile.FullName -XPath '//test-case@result="Failed" or @outcome="Failed"' 
    ForEach-Object { $_.Node.name }
if ($failed) {
    Write-Host 'Failing tests:' -ForegroundColor Red
    failed | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host 'All tests passed.' -ForegroundColor Green
}





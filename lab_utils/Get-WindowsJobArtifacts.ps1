[CmdletBinding()]
param(
    [string]$Repo = 'wizzense/opentofu-lab-automation',
    [string]$Workflow = 'pester.yml',
    [long]$RunId
)

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "gh-artifacts-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

$useGh = $false
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        gh auth status --hostname github.com *> $null
        $useGh = $true
    } catch {
        Write-Host 'gh authentication failed; using public download URLs.' -ForegroundColor Yellow
    }
}

if ($useGh) {
    if ($RunId) {
        $artJson = gh "api repos/$Repo/actions/runs/$RunId/artifacts"
        $artifacts = (ConvertFrom-Json $artJson).artifacts
        $cov = $artifacts | Where-Object { $_.name -match 'coverage.*windows-latest' }
        $res = $artifacts | Where-Object { $_.name -match 'results.*windows-latest' }
        if ($res) {
            if ($cov) {
                gh $cov.archive_download_url --output (Join-Path $tempDir 'coverage.zip')
                if ($LASTEXITCODE -ne 0) {
                    Write-Host 'Failed to download coverage artifact.' -ForegroundColor Yellow
                }
            }
            gh $res.archive_download_url --output (Join-Path $tempDir 'results.zip')
            if ($LASTEXITCODE -ne 0) {
                Write-Host 'Failed to download results artifact.' -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host "No artifacts for windows-latest found on run $RunId. Use gh run view $RunId for details." -ForegroundColor Yellow
            exit 1
        }
    } else {
        $runsJson = gh "api repos/$Repo/actions/workflows/$Workflow/runs?branch=main&status=completed&per_page=10"
        $runs = (ConvertFrom-Json $runsJson).workflow_runs

        $found = $false
        foreach ($run in $runs) {
            $artJson = gh "api repos/$Repo/actions/runs/$($run.id)/artifacts"
            $artifacts = (ConvertFrom-Json $artJson).artifacts
            $cov = $artifacts | Where-Object { $_.name -match 'coverage.*windows-latest' }
            $res = $artifacts | Where-Object { $_.name -match 'results.*windows-latest' }
            if ($res) {
                if ($cov) {
                    gh $cov.archive_download_url --output (Join-Path $tempDir 'coverage.zip')
                }
                gh $res.archive_download_url --output (Join-Path $tempDir 'results.zip')
                $found = $true
                break
            }
        }

        if (-not $found) {
            Write-Host 'No Windows artifacts found in recent runs. Try specifying -RunId to select a specific run.' -ForegroundColor Yellow
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
    try {
        Invoke-WebRequest -Uri $covUrl -OutFile (Join-Path $tempDir 'coverage.zip') -UseBasicParsing
        if (-not $?) {
            Write-Host 'Failed to download coverage artifact anonymously.' -ForegroundColor Yellow
        }
    } catch {
        Write-Host 'Failed to download coverage artifact anonymously.' -ForegroundColor Yellow
    }
    try {
        Invoke-WebRequest -Uri $resUrl -OutFile (Join-Path $tempDir 'results.zip') -UseBasicParsing
        if (-not $?) {
            Write-Host 'Failed to download results artifact anonymously.' -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host 'Failed to download results artifact anonymously.' -ForegroundColor Yellow
        exit 1
    }
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

$resultsFile = Get-ChildItem -Path $resDir -Filter *.xml -Recurse | Select-Object -First 1
if (-not $resultsFile) {
    Write-Host 'Results file not found.' -ForegroundColor Yellow
    exit 1
}

$failed = Select-Xml -Path $resultsFile.FullName -XPath '//test-case[@result="Failed" or @outcome="Failed"]' |
    ForEach-Object { $_.Node.name }
if ($failed) {
    Write-Host 'Failing tests:' -ForegroundColor Red
    $failed | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host 'All tests passed.' -ForegroundColor Green
}

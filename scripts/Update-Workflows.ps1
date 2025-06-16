# Update-Workflows.ps1
# Script to update GitHub Actions workflows to use the CodeFixer module
CmdletBinding()
param(
    switch$Force,
    switch$SkipBackup
)








$ErrorActionPreference = 'Stop'

# Helper function to backup files before modifying them
function Backup-File {
    param(
        string$FilePath
    )

    






if ($SkipBackup) {
        return
    }

    $backupDir = Join-Path $PSScriptRoot ".." "backups" "workflows" (Get-Date -Format "yyyyMMdd-HHmmss")
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }

    $fileName = Split-Path -Path $FilePath -Leaf
    $backupPath = Join-Path $backupDir $fileName

    try {
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "Backed up $FilePath to $backupPath" -ForegroundColor Cyan
    }
    catch {
        Write-Warning "Failed to back up $FilePath : $_"
    }
}

function Update-WorkflowFile {
    param(
        string$FilePath
    )

    






if (-not (Test-Path $FilePath)) {
        Write-Warning "Workflow file $FilePath does not exist. Skipping."
        return
    }

    Backup-File -FilePath $FilePath

    $content = Get-Content -Path $FilePath -Raw

    # Update for different workflow files based on their filenames
    if ($FilePath -like '*unified-ci.yml') {
        # Update the unified CI workflow
        
        # Update the lint job to use the CodeFixer module
        if ($content -match 'name: Run comprehensive linting' -and $content -notmatch 'Invoke-PowerShellLint') {
            $content = $content -replace '(?sm)(name: Run comprehensive linting.*?shell: pwsh\s+run: \\s+\./comprehensive-lint.ps1)', @"
name: Run comprehensive linting
        shell: pwsh
        run: 
          # Import the CodeFixer module
          Import-Module .//pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
          
          # Run PowerShell linting using the module
          ./comprehensive-lint.ps1 -FixErrors -OutputFormat CI
"@
        }
        
        # Update Pester tests step
        if ($content -match 'name: Run Pester Tests' -and $content -notmatch 'Invoke-AutoFix') {
            $content = $content -replace '(?sm)(name: Run Pester Tests.*?shell: pwsh\s+run: \)', @"
name: Run Pester Tests
        shell: pwsh
        run: 
          # Import the CodeFixer module
          Import-Module .//pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
          
          # Run any necessary fixes before tests
          ./auto-fix.ps1 -Apply -Quiet
"@
        }

        # Add a new job for comprehensive validation if it doesn't exist
        if ($content -notmatch 'name: Comprehensive Validation') {
            # Find where to insert the new job - before the workflow-health job
            $content = $content -replace '(?sm)(  # Workflow health monitor\s+workflow-health:)', @"
  # Comprehensive validation 
  comprehensive-validation:
    name: Comprehensive Validation
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install PowerShell
        shell: bash
        run: 
          sudo apt-get update
          sudo apt-get install -y wget apt-transport-https software-properties-common
          wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
          sudo dpkg -i packages-microsoft-prod.deb
          sudo apt-get update
          sudo apt-get install -y powershell
      
      - name: Install Pester and PSScriptAnalyzer
        shell: pwsh
        run: 
          Install-Module -Name Pester -RequiredVersion 5.7.1 -Force -Scope CurrentUser
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
      
      - name: Run Comprehensive Validation
        shell: pwsh
        run: 
          ./invoke-comprehensive-validation.ps1 -Fix -OutputFormat CI -SaveResults
      
      - name: Upload validation report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: validation-report
          path: reports/validation/*.json

  # Workflow health monitor
  workflow-health:
"@
            
            # Update the needs section of the summary job to include the new comprehensive-validation job
            $content = $content -replace '(?m)(needs: \validate, lint, pytest, pester-linux, health-check, workflow-health\)', 'needs: validate, lint, pytest, pester-linux, health-check, comprehensive-validation, workflow-health'
            
            # Update the summary table to include the new job
            $content = $content -replace '(?m)(echo " Health Check \ \$\{\{ needs\.health-check\.result \}\} \" >> \$GITHUB_STEP_SUMMARY)', @"
`$1
          echo " Comprehensive Validation  `$`{{ needs.comprehensive-validation.result `}} " >> `$GITHUB_STEP_SUMMARY
"@

            # Update the condition check to include the new job
            $content = $content -replace '(?m)(\s+if \\ "\$\{\{ needs\.validate\.result \}\}" != "success" \\)', @"
          if  "`$`{{ needs.validate.result `}}" != "success" 
                "`$`{{ needs.comprehensive-validation.result `}}" != "success" 
"@
        }
    }
    elseif ($FilePath -like '*auto-test-generation-execution.yml') {
        # Update the auto-test generation execution workflow
        
        # Update test generation step to use the CodeFixer module
        if ($content -match 'name: Generate Tests' -and $content -notmatch 'New-AutoTest') {
            $content = $content -replace '(?sm)(name: Generate Tests.*?shell: pwsh\s+run: \)', @"
name: Generate Tests
        shell: pwsh
        run: 
          # Import the CodeFixer module
          Import-Module .//pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
"@

            # Add the new test generator call
            $content = $content -replace '(?m)(# Process each changed script\s+\$changedScripts)', @"
# Use the CodeFixer module to generate tests
Write-Host "Available scripts to process: \$changedScripts"
foreach (\$scriptPath in \$changedScripts) {
    Write-Host "Generating tests for \$scriptPath using CodeFixer module..."
    New-AutoTest -ScriptPath \$scriptPath -Force
}

# Fallback to legacy method if needed
# Process each changed script
\$changedScripts
"@
        }
    }

    Set-Content -Path $FilePath -Value $content -Force
    Write-Host "Updated workflow file $FilePath with CodeFixer module integration" -ForegroundColor Green
}

# Main script execution
try {
    $workflowDir = Join-Path $PSScriptRoot ".." ".github" "workflows"
    
    if (-not (Test-Path $workflowDir)) {
        Write-Warning "GitHub workflows directory not found at $workflowDir"
        exit 1
    }
    
    # Update specific workflow files
    $workflowFiles = @(
        "unified-ci.yml",
        "auto-test-generation-execution.yml"
    )
    
    foreach ($file in $workflowFiles) {
        $filePath = Join-Path $workflowDir $file
        if (Test-Path $filePath) {
            Write-Host "Updating workflow file: $file" -ForegroundColor Cyan
            Update-WorkflowFile -FilePath $filePath
        } else {
            Write-Warning "Workflow file not found: $file"
        }
    }
    
    Write-Host "`nWorkflow updates completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "Workflow update failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}




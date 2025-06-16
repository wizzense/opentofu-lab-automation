


function Initialize-PSScriptAnalyzer {
 <#
 .SYNOPSIS
 Robust PSScriptAnalyzer initialization using proven patterns from the project
 #>
 
 try {
 # Simple import first (the pattern that works)
 Import-Module PSScriptAnalyzer -Force
 
 # Test it works
 $null = Invoke-ScriptAnalyzer -ScriptDefinition "Write-Host 'test'" -ErrorAction Stop
 
 Write-Host "PASS PSScriptAnalyzer ready" -ForegroundColor Green
 return $true
 } catch {
 Write-Host "WARN PSScriptAnalyzer not available, using fallback methods" -ForegroundColor Yellow
 
 # Install using the proven method from fix-psscriptanalyzer.ps1
 try {
 Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
 Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -AllowClobber -SkipPublisherCheck
 Import-Module PSScriptAnalyzer -Force
 
 Write-Host "PASS PSScriptAnalyzer installed and ready" -ForegroundColor Green
 return $true
 } catch {
 Write-Host "FAIL PSScriptAnalyzer initialization failed: $($_.Exception.Message)" -ForegroundColor Red
 return $false
 }
 }
}


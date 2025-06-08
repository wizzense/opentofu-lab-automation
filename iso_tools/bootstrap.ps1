Set-ExecutionPolicy -ExecutionPolicy Bypass

Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/dev/kicker-bootstrap.ps1' -OutFile '.\kicker-bootstrap.ps1'

if (Test-Path '.\kicker-bootstrap.ps1') {
  Write-Host "Downloaded kicker-bootstrap.ps1 to $(Resolve-Path '.\kicker-bootstrap.ps1')"
  & .\kicker-bootstrap.ps1
} else {
  Write-Error 'kicker-bootstrap.ps1 was not found after download.'
}

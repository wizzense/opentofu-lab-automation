#!/usr/bin/env pwsh
# Secure Code Signing Fix - Address plain text key security issue
# Author: wizzense  Contact: wizzense@wizzense.com

CmdletBinding()
param(
 switch$AnalyzeOnly,
 switch$BackupCurrent,
 switch$GenerateNewKey,
 switch$SecureExisting,
 switch$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host " OpenTofu Lab Automation - Code Signing Security Fix" -ForegroundColor Cyan
Write-Host "Author: wizzense (wizzense@wizzense.com)" -ForegroundColor Green
Write-Host ""

# Analyze current security state
function Analyze-CurrentSecurity {
 Write-Host " Analyzing current code signing security..." -ForegroundColor Yellow
 
 $analysis = @{
 PlainTextKeyExists = Test-Path "keys/signing_key.txt"
 SignedFilesCount = (Get-ChildItem "signed" -ErrorAction SilentlyContinue  Measure-Object).Count
 KeyInfoExists = Test-Path "keys/key_info.json"
 SecureKeyExists = Test-Path "keys/signing_key_secure.dat"
 }
 
 Write-Host " Security Analysis Results:" -ForegroundColor Cyan
 Write-Host " Plain Text Key: $(if($analysis.PlainTextKeyExists) {'WARN FOUND (SECURITY RISK)'} else {'PASS Not Found'})"
 Write-Host " Signed Files: $($analysis.SignedFilesCount) files"
 Write-Host " Key Info: $(if($analysis.KeyInfoExists) {'PASS Present'} else {'FAIL Missing'})"
 Write-Host " Secure Key: $(if($analysis.SecureKeyExists) {'PASS Present'} else {'FAIL Missing'})"
 
 if ($analysis.PlainTextKeyExists) {
 $keyContent = Get-Content "keys/signing_key.txt" -Raw
 Write-Warning " CRITICAL: Plain text signing key detected!"
 Write-Host " Key Preview: $($keyContent.Substring(0, Math::Min(16, $keyContent.Length)))..."
 Write-Host " Key Length: $($keyContent.Length) characters"
 }
 
 return $analysis
}

# Backup current key securely
function Backup-CurrentKey {
 if (-not (Test-Path "keys/signing_key.txt")) {
 Write-Warning "No plain text key found to backup."
 return
 }
 
 Write-Host "� Creating secure backup of current key..." -ForegroundColor Yellow
 
 $currentKey = Get-Content "keys/signing_key.txt" -Raw
 $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
 
 # Create encrypted backup using DPAPI (Windows Data Protection API)
 if ($PSVersionTable.Platform -ne "Unix") {
 try {
 $secureString = ConvertTo-SecureString $currentKey -AsPlainText -Force
 $encryptedKey = ConvertFrom-SecureString $secureString
 $backupPath = "keys/backup_key_$timestamp.dat"
 
 if ($WhatIf) {
 Write-Host "WHATIF: Would create encrypted backup at $backupPath"
 } else {
 encryptedKey | Out-File $backupPath -Encoding UTF8
 Write-Host "PASS Encrypted backup created: $backupPath" -ForegroundColor Green
 }
 } catch {
 Write-Error "Failed to create encrypted backup: $($_.Exception.Message)"
 }
 } else {
 # For Linux/macOS, use base64 encoding (less secure but better than plain text)
 $encodedKey = System.Convert::ToBase64String(System.Text.Encoding::UTF8.GetBytes($currentKey))
 $backupPath = "keys/backup_key_$timestamp.b64"
 
 if ($WhatIf) {
 Write-Host "WHATIF: Would create base64 backup at $backupPath"
 } else {
 encodedKey | Out-File $backupPath -Encoding UTF8
 Write-Host "PASS Base64 backup created: $backupPath" -ForegroundColor Green
 Write-Warning "Note: Base64 encoding is not encryption. Consider using a proper secrets manager."
 }
 }
}

# Generate new secure signing key
function Generate-NewSecureKey {
 Write-Host "� Generating new secure signing key..." -ForegroundColor Yellow
 
 try {
 # Generate cryptographically secure random key
 $rng = System.Security.Cryptography.RandomNumberGenerator::Create()
 $keyBytes = New-Object byte 32 # 256-bit key
 $rng.GetBytes($keyBytes)
 $newKeyHex = System.BitConverter::ToString($keyBytes) -replace '-', ''
 
 # Create key metadata
 $keyInfo = @{
 created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.ffffff")
 algorithm = "HMAC-SHA256"
 key_length = 256
 purpose = "OpenTofu Lab Automation Code Signing - wizzense"
 version = "2.0-secure"
 author = "wizzense"
 contact = "wizzense@wizzense.com"
 }
 
 if ($WhatIf) {
 Write-Host "WHATIF: Would generate new 256-bit secure key"
 Write-Host "WHATIF: Would update key_info.json with new metadata"
 return $newKeyHex
 }
 
 # Save encrypted key
 if ($PSVersionTable.Platform -ne "Unix") {
 $secureString = ConvertTo-SecureString $newKeyHex -AsPlainText -Force
 $encryptedKey = ConvertFrom-SecureString $secureString
 encryptedKey | Out-File "keys/signing_key_secure.dat" -Encoding UTF8
 Write-Host "PASS New secure key generated and encrypted" -ForegroundColor Green
 } else {
 # For Linux/macOS, at least use base64
 $encodedKey = System.Convert::ToBase64String(System.Text.Encoding::UTF8.GetBytes($newKeyHex))
 encodedKey | Out-File "keys/signing_key_secure.b64" -Encoding UTF8
 Write-Host "PASS New key generated and base64 encoded" -ForegroundColor Green
 }
 
 # Update key info
 keyInfo | ConvertTo-Json -Depth 10  Out-File "keys/key_info.json" -Encoding UTF8
 Write-Host "PASS Key metadata updated" -ForegroundColor Green
 
 return $newKeyHex
 } catch {
 Write-Error "Failed to generate new key: $($_.Exception.Message)"
 } finally {
 if ($rng) { $rng.Dispose() }
 }
}

# Secure existing plain text key
function Secure-ExistingKey {
 if (-not (Test-Path "keys/signing_key.txt")) {
 Write-Warning "No plain text key found to secure."
 return
 }
 
 Write-Host "� Securing existing plain text key..." -ForegroundColor Yellow
 
 $currentKey = Get-Content "keys/signing_key.txt" -Raw
 
 try {
 if ($PSVersionTable.Platform -ne "Unix") {
 $secureString = ConvertTo-SecureString $currentKey -AsPlainText -Force
 $encryptedKey = ConvertFrom-SecureString $secureString
 
 if ($WhatIf) {
 Write-Host "WHATIF: Would encrypt existing key and remove plain text file"
 } else {
 encryptedKey | Out-File "keys/signing_key_secure.dat" -Encoding UTF8
 Remove-Item "keys/signing_key.txt" -Force
 Write-Host "PASS Existing key secured and plain text removed" -ForegroundColor Green
 }
 } else {
 $encodedKey = System.Convert::ToBase64String(System.Text.Encoding::UTF8.GetBytes($currentKey))
 
 if ($WhatIf) {
 Write-Host "WHATIF: Would base64 encode existing key and remove plain text file"
 } else {
 encodedKey | Out-File "keys/signing_key_secure.b64" -Encoding UTF8
 Remove-Item "keys/signing_key.txt" -Force
 Write-Host "PASS Existing key encoded and plain text removed" -ForegroundColor Green
 }
 }
 } catch {
 Write-Error "Failed to secure existing key: $($_.Exception.Message)"
 }
}

# Main execution
try {
 $analysis = Analyze-CurrentSecurity
 
 if ($AnalyzeOnly) {
 Write-Host ""
 Write-Host " Recommendations:" -ForegroundColor Cyan
 if ($analysis.PlainTextKeyExists) {
 Write-Host " 1. Run with -BackupCurrent to create secure backup"
 Write-Host " 2. Run with -GenerateNewKey to create new secure key"
 Write-Host " 3. Or run with -SecureExisting to encrypt current key"
 } else {
 Write-Host " PASS No plain text key found - security is good!"
 }
 return
 }
 
 if ($BackupCurrent) {
 Backup-CurrentKey
 }
 
 if ($GenerateNewKey) {
 $newKey = Generate-NewSecureKey
 Write-Host " Consider re-signing all $($analysis.SignedFilesCount) files with new key" -ForegroundColor Yellow
 }
 
 if ($SecureExisting) {
 Secure-ExistingKey
 }
 
 # Final security check
 Write-Host ""
 Write-Host " Final Security Check:" -ForegroundColor Cyan
 $finalCheck = Analyze-CurrentSecurity
 
 if (-not $finalCheck.PlainTextKeyExists) {
 Write-Host "PASS SUCCESS: No plain text keys detected!" -ForegroundColor Green
 } else {
 Write-Warning "WARN Plain text key still exists. Run with appropriate flags to secure it."
 }
 
} catch {
 Write-Error "Security fix failed: $($_.Exception.Message)"
 Write-Host "Contact: wizzense@wizzense.com for support" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "� Code signing security analysis complete." -ForegroundColor Cyan
Write-Host "Project: OpenTofu Lab Automation  Author: wizzense" -ForegroundColor Green


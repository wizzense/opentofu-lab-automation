#!/usr/bin/env python3
"""
Windows Code Signing Implementation for OpenTofu Lab Automation

Uses Windows built-in PowerShell certificate capabilities.
"""

import os
import sys
import subprocess
import json
import hashlib
from pathlib import Path
from datetime import datetime, timedelta
import platform

class WindowsCodeSigner:
    """Handle Windows code signing operations"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.certs_dir = project_root / "certs"
        self.signed_dir = project_root / "signed"
        
        # Create directories
        self.certs_dir.mkdir(exist_ok=True)
        self.signed_dir.mkdir(exist_ok=True)
        
        self.cert_subject = "CN=OpenTofu Lab Automation Code Signing"
        self.cert_password = "OpenTofu2025!"
        
    def create_windows_certificate(self):
        """Create Windows code signing certificate using PowerShell"""
        print("🔐 Creating Windows code signing certificate...")
        
        cert_file = self.certs_dir / "code_signing.pfx"
        
        if cert_file.exists():
            print("✅ Certificate already exists")
            return True
          # PowerShell script to create self-signed certificate
        ps_script = f'''
        try {{
            # Create the certificate
            $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "{self.cert_subject}" -CertStoreLocation "Cert:\\\\CurrentUser\\\\My" -NotAfter (Get-Date).AddDays(365) -KeyUsage DigitalSignature -KeyUsageProperty All -KeyLength 2048
            
            # Export to PFX file
            $password = ConvertTo-SecureString -String "{self.cert_password}" -Force -AsPlainText
            $cert | Export-PfxCertificate -FilePath "{cert_file}" -Password $password -Force
            
            # Also export public certificate
            $cert | Export-Certificate -FilePath "{self.certs_dir}\\public_cert.cer" -Force
            
            Write-Host "SUCCESS: Certificate created with thumbprint: $($cert.Thumbprint)"
            Write-Host "SUCCESS: PFX file: {cert_file}"
            Write-Host "SUCCESS: Public cert: {self.certs_dir}\\public_cert.cer"
            
            # Create certificate info file
            $certInfo = @{{
                Thumbprint = $cert.Thumbprint
                Subject = $cert.Subject
                NotBefore = $cert.NotBefore.ToString()
                NotAfter = $cert.NotAfter.ToString()
                PfxFile = "{cert_file}"
                PublicCert = "{self.certs_dir}\\public_cert.cer"
                Created = (Get-Date).ToString()
            }}
            
            $certInfo | ConvertTo-Json | Out-File "{self.certs_dir}\\cert_info.json" -Encoding UTF8
            
            exit 0
        }}
        catch {{
            Write-Host "ERROR: $_"
            exit 1
        }}
        '''
        
        try:
            result = subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-Command', ps_script], 
                                   capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                print("✅ Windows certificate created successfully")
                print(result.stdout)
                return True
            else:
                print(f"❌ Failed to create Windows certificate:")
                print(f"   stdout: {result.stdout}")
                print(f"   stderr: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Certificate creation timed out")
            return False
        except Exception as e:
            print(f"❌ Error creating Windows certificate: {e}")
            return False
    
    def sign_file_windows(self, file_path: Path):
        """Sign a file using Windows SignTool"""
        if not file_path.exists():
            return False
            
        cert_file = self.certs_dir / "code_signing.pfx"
        if not cert_file.exists():
            print("❌ Certificate file not found")
            return False
        
        # Try to use signtool if available
        try:
            result = subprocess.run([
                'signtool', 'sign', 
                '/f', str(cert_file),
                '/p', self.cert_password,
                '/fd', 'SHA256',
                '/t', 'http://timestamp.sectigo.com',
                str(file_path)
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                print(f"✅ Signed with signtool: {file_path.name}")
                return True
            else:
                print(f"⚠️  signtool failed for {file_path.name}: {result.stderr}")
                
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            pass  # Fall back to PowerShell method
        
        # Fallback: Use PowerShell Set-AuthenticodeSignature
        return self.sign_file_powershell(file_path)
    
    def sign_file_powershell(self, file_path: Path):
        """Sign a file using PowerShell Set-AuthenticodeSignature"""
        cert_file = self.certs_dir / "code_signing.pfx"
        
        ps_script = f'''
        try {{
            $password = ConvertTo-SecureString -String "{self.cert_password}" -Force -AsPlainText
            $cert = Get-PfxCertificate -FilePath "{cert_file}" -Password $password
            
            $result = Set-AuthenticodeSignature -FilePath "{file_path}" -Certificate $cert -TimestampServer "http://timestamp.sectigo.com"
            
            if ($result.Status -eq "Valid") {{
                Write-Host "SUCCESS: Signed {file_path.name}"
                exit 0
            }} else {{
                Write-Host "ERROR: Failed to sign {file_path.name} - Status: $($result.Status)"
                exit 1
            }}
        }}
        catch {{
            Write-Host "ERROR: $_"
            exit 1
        }}
        '''
        
        try:
            result = subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-Command', ps_script], 
                                   capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                print(f"✅ Signed with PowerShell: {file_path.name}")
                return True
            else:
                print(f"❌ PowerShell signing failed for {file_path.name}: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            print(f"❌ Signing timeout for {file_path.name}")
            return False
        except Exception as e:
            print(f"❌ Error signing {file_path.name}: {e}")
            return False
    
    def create_file_signature(self, file_path: Path):
        """Create a JSON signature for any file"""
        if not file_path.exists():
            return None
            
        # Calculate file hash
        with open(file_path, 'rb') as f:
            file_hash = hashlib.sha256(f.read()).hexdigest()
        
        # Get file info
        stat = file_path.stat()
        
        signature = {
            'file': str(file_path.relative_to(self.project_root)),
            'hash': file_hash,
            'algorithm': 'SHA256',
            'size': stat.st_size,
            'modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
            'signed_by': 'OpenTofu Lab Automation',
            'signed_at': datetime.now().isoformat()
        }
        
        # Save signature file
        sig_file = self.signed_dir / f"{file_path.name}.sig"
        with open(sig_file, 'w') as f:
            json.dump(signature, f, indent=2)
        
        return signature
    
    def sign_all_files(self):
        """Sign all relevant files in the project"""
        print("🖋️  Signing all files...")
        
        # File extensions to sign
        signable_extensions = {'.exe', '.msi', '.ps1', '.py', '.bat'}
        other_extensions = {'.sh', '.json', '.yaml', '.yml', '.md'}
        
        signed_count = 0
        json_signed_count = 0
        
        for file_path in self.project_root.rglob('*'):
            # Skip directories and hidden/system files
            if (file_path.is_dir() or 
                file_path.name.startswith('.') or
                any(part in str(file_path) for part in ['__pycache__', '.git', 'node_modules', 'venv', 'certs', 'signed'])):
                continue
            
            extension = file_path.suffix.lower()
            
            # Try Windows code signing for executable files
            if extension in signable_extensions:
                if self.sign_file_windows(file_path):
                    signed_count += 1
                # Always create JSON signature as well
                if self.create_file_signature(file_path):
                    json_signed_count += 1
            
            # Create JSON signatures for other important files
            elif extension in other_extensions:
                if self.create_file_signature(file_path):
                    json_signed_count += 1
        
        # Create signing manifest
        manifest = {
            'project': 'OpenTofu Lab Automation',
            'signed_at': datetime.now().isoformat(),
            'windows_signed_files': signed_count,
            'json_signed_files': json_signed_count,
            'certificate_subject': self.cert_subject,
            'signatures_location': str(self.signed_dir.relative_to(self.project_root))
        }
        
        manifest_file = self.signed_dir / "signing_manifest.json"
        with open(manifest_file, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        print(f"✅ Windows signed: {signed_count} files")
        print(f"✅ JSON signed: {json_signed_count} files")
        print(f"📋 Manifest: {manifest_file}")
        
        return True
    
    def verify_signature(self, file_path: Path):
        """Verify file signature"""
        # Check Windows signature first
        if file_path.suffix.lower() in {'.exe', '.msi', '.ps1', '.py', '.bat'}:
            ps_script = f'''
            try {{
                $result = Get-AuthenticodeSignature -FilePath "{file_path}"
                if ($result.Status -eq "Valid") {{
                    Write-Host "VALID: Windows signature is valid"
                    exit 0
                }} else {{
                    Write-Host "INVALID: Windows signature status: $($result.Status)"
                }}
            }}
            catch {{
                Write-Host "ERROR: $_"
            }}
            '''
            
            try:
                result = subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-Command', ps_script], 
                                       capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    return True, "Windows signature valid"
            except:
                pass
        
        # Check JSON signature
        sig_file = self.signed_dir / f"{file_path.name}.sig"
        if not sig_file.exists():
            return False, "No signature found"
        
        try:
            with open(sig_file, 'r') as f:
                signature = json.load(f)
            
            # Verify file hash
            with open(file_path, 'rb') as f:
                current_hash = hashlib.sha256(f.read()).hexdigest()
            
            if current_hash == signature['hash']:
                return True, "JSON signature valid"
            else:
                return False, "File hash mismatch"
                
        except Exception as e:
            return False, f"Verification error: {e}"

def main():
    """Main entry point"""
    if platform.system() != "Windows":
        print("❌ This script is designed for Windows only")
        return 1
    
    project_root = Path(__file__).parent.parent
    signer = WindowsCodeSigner(project_root)
    
    print("🔐 OpenTofu Lab Automation - Windows Code Signing")
    print("=" * 55)
    
    # Create certificate
    if not signer.create_windows_certificate():
        print("❌ Failed to create certificate")
        return 1
    
    # Sign all files
    if not signer.sign_all_files():
        print("❌ Failed to sign files")
        return 1
    
    print("\n🎉 Code signing completed!")
    print(f"📁 Certificates: {signer.certs_dir}")
    print(f"📁 Signatures: {signer.signed_dir}")
    
    # Test verification on a sample file
    test_file = project_root / "gui.py"
    if test_file.exists():
        valid, message = signer.verify_signature(test_file)
        print(f"🔍 Test verification of gui.py: {message}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

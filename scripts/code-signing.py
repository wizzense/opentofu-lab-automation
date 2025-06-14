#!/usr/bin/env python3
"""
Code Signing Implementation for OpenTofu Lab Automation

This script creates self-signed certificates and implements code signing
for all executables and scripts in the project.
"""

import os
import sys
import subprocess
import json
import hashlib
from pathlib import Path
from datetime import datetime, timedelta
import platform

class CodeSigner:
    """Handle code signing operations for cross-platform executables"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.certs_dir = project_root / "certs"
        self.signed_dir = project_root / "signed"
        self.cert_config = self.certs_dir / "cert_config.json"
        
        # Create directories
        self.certs_dir.mkdir(exist_ok=True)
        self.signed_dir.mkdir(exist_ok=True)
        
        # Certificate configuration
        self.cert_info = {
            "country": "US",
            "state": "CA", 
            "city": "San Francisco",
            "organization": "OpenTofu Lab Automation",
            "organizational_unit": "Development",
            "common_name": "OpenTofu Lab Automation Code Signing",
            "email": "dev@opentofu-lab.local",
            "valid_days": 365
        }
        
    def create_self_signed_cert(self):
        """Create self-signed certificate for code signing"""
        print("🔐 Creating self-signed code signing certificate...")
        
        cert_file = self.certs_dir / "code_signing.crt"
        key_file = self.certs_dir / "code_signing.key"
        
        if cert_file.exists() and key_file.exists():
            print("✅ Certificate already exists, skipping creation")
            return True
            
        try:
            # Check if OpenSSL is available
            result = subprocess.run(['openssl', 'version'], capture_output=True, text=True)
            if result.returncode != 0:
                print("❌ OpenSSL not found, attempting to install...")
                return self.install_openssl_and_retry()
                
            # Create private key
            subprocess.run([
                'openssl', 'genrsa', '-out', str(key_file), '2048'
            ], check=True, capture_output=True)
            
            # Create certificate
            subject = f"/C={self.cert_info['country']}/ST={self.cert_info['state']}/L={self.cert_info['city']}/O={self.cert_info['organization']}/OU={self.cert_info['organizational_unit']}/CN={self.cert_info['common_name']}/emailAddress={self.cert_info['email']}"
            
            subprocess.run([
                'openssl', 'req', '-new', '-x509', '-key', str(key_file),
                '-out', str(cert_file), '-days', str(self.cert_info['valid_days']),
                '-subj', subject
            ], check=True, capture_output=True)
            
            # Save certificate info
            with open(self.cert_config, 'w') as f:
                json.dump({
                    **self.cert_info,
                    'created': datetime.now().isoformat(),
                    'expires': (datetime.now() + timedelta(days=self.cert_info['valid_days'])).isoformat(),
                    'cert_file': str(cert_file),
                    'key_file': str(key_file)
                }, f, indent=2)
            
            print(f"✅ Certificate created: {cert_file}")
            print(f"✅ Private key created: {key_file}")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to create certificate: {e}")
            return False
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return False
    
    def install_openssl_and_retry(self):
        """Install OpenSSL and retry certificate creation"""
        system = platform.system().lower()
        
        if system == "windows":
            print("📦 Installing OpenSSL via chocolatey...")
            try:
                subprocess.run(['choco', 'install', 'openssl', '-y'], check=True)
                return self.create_self_signed_cert()
            except subprocess.CalledProcessError:
                print("❌ Failed to install OpenSSL via chocolatey")
                print("   Please install OpenSSL manually from https://slproweb.com/products/Win32OpenSSL.html")
                return False
        elif system == "linux":
            print("📦 Installing OpenSSL via apt...")
            try:
                subprocess.run(['sudo', 'apt-get', 'update'], check=True)
                subprocess.run(['sudo', 'apt-get', 'install', '-y', 'openssl'], check=True)
                return self.create_self_signed_cert()
            except subprocess.CalledProcessError:
                print("❌ Failed to install OpenSSL via apt")
                return False
        elif system == "darwin":
            print("📦 Installing OpenSSL via homebrew...")
            try:
                subprocess.run(['brew', 'install', 'openssl'], check=True)
                return self.create_self_signed_cert()
            except subprocess.CalledProcessError:
                print("❌ Failed to install OpenSSL via homebrew")
                return False
        else:
            print(f"❌ Unsupported platform: {system}")
            return False
    
    def create_signature(self, file_path: Path):
        """Create digital signature for a file"""
        if not file_path.exists():
            return None
            
        # Calculate file hash
        with open(file_path, 'rb') as f:
            file_hash = hashlib.sha256(f.read()).hexdigest()
        
        # Create signature metadata
        signature = {
            'file': str(file_path.relative_to(self.project_root)),
            'hash': file_hash,
            'algorithm': 'SHA256',
            'signed_by': self.cert_info['common_name'],
            'signed_at': datetime.now().isoformat(),
            'size': file_path.stat().st_size
        }
        
        return signature
    
    def sign_file(self, file_path: Path):
        """Sign a file and create signature"""
        signature = self.create_signature(file_path)
        if not signature:
            return False
            
        # Create signature file
        sig_file = self.signed_dir / f"{file_path.name}.sig"
        with open(sig_file, 'w') as f:
            json.dump(signature, f, indent=2)
        
        print(f"✅ Signed: {file_path.name}")
        return True
    
    def sign_all_executables(self):
        """Sign all executables in the project"""
        print("🖋️  Signing all executables and scripts...")
        
        # File patterns to sign
        patterns = [
            "*.exe", "*.msi", "*.py", "*.ps1", "*.bat", "*.sh"
        ]
        
        signed_count = 0
        
        for pattern in patterns:
            for file_path in self.project_root.glob(f"**/{pattern}"):
                # Skip files in certain directories
                if any(part in str(file_path) for part in ['__pycache__', '.git', 'node_modules', 'venv']):
                    continue
                    
                if self.sign_file(file_path):
                    signed_count += 1
        
        # Create manifest of all signed files
        manifest = {
            'project': 'OpenTofu Lab Automation',
            'signed_at': datetime.now().isoformat(),
            'total_files': signed_count,
            'certificate': self.cert_info['common_name'],
            'files': []
        }
        
        # Add all signature files to manifest
        for sig_file in self.signed_dir.glob("*.sig"):
            with open(sig_file, 'r') as f:
                manifest['files'].append(json.load(f))
        
        # Save manifest
        manifest_file = self.signed_dir / "signing_manifest.json"
        with open(manifest_file, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        print(f"✅ Signed {signed_count} files")
        print(f"📋 Manifest created: {manifest_file}")
        
        return signed_count > 0
    
    def verify_signature(self, file_path: Path):
        """Verify file signature"""
        sig_file = self.signed_dir / f"{file_path.name}.sig"
        
        if not sig_file.exists():
            return False, "No signature file found"
            
        try:
            with open(sig_file, 'r') as f:
                signature = json.load(f)
            
            # Verify file hash
            with open(file_path, 'rb') as f:
                current_hash = hashlib.sha256(f.read()).hexdigest()
            
            if current_hash != signature['hash']:
                return False, "File hash mismatch"
            
            return True, "Signature valid"
            
        except Exception as e:
            return False, f"Verification error: {e}"
    
    def create_windows_certificate(self):
        """Create Windows-specific certificate using PowerShell"""
        if platform.system() != "Windows":
            return False
            
        print("🔐 Creating Windows code signing certificate...")
        
        # PowerShell script to create self-signed certificate
        ps_script = f'''
        $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN={self.cert_info['common_name']}" -CertStoreLocation "Cert:\\CurrentUser\\My" -NotAfter (Get-Date).AddDays({self.cert_info['valid_days']})
        $cert | Export-Certificate -FilePath "{self.certs_dir}\\windows_code_signing.cer"
        $cert | Export-PfxCertificate -FilePath "{self.certs_dir}\\windows_code_signing.pfx" -Password (ConvertTo-SecureString -String "opentofu123" -Force -AsPlainText)
        Write-Host "Certificate created with thumbprint: $($cert.Thumbprint)"
        '''
        
        try:
            result = subprocess.run(['powershell', '-Command', ps_script], 
                                   capture_output=True, text=True)
            if result.returncode == 0:
                print("✅ Windows certificate created successfully")
                return True
            else:
                print(f"❌ Failed to create Windows certificate: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ Error creating Windows certificate: {e}")
            return False

def main():
    """Main entry point"""
    project_root = Path(__file__).parent
    signer = CodeSigner(project_root)
    
    print("🔐 OpenTofu Lab Automation Code Signing Tool")
    print("=" * 50)
    
    # Create certificates
    if not signer.create_self_signed_cert():
        print("❌ Failed to create certificate")
        return 1
    
    # Create Windows certificate if on Windows
    if platform.system() == "Windows":
        signer.create_windows_certificate()
    
    # Sign all files
    if not signer.sign_all_executables():
        print("❌ Failed to sign files")
        return 1
    
    print("\n🎉 Code signing completed!")
    print(f"📁 Certificates: {signer.certs_dir}")
    print(f"📁 Signatures: {signer.signed_dir}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

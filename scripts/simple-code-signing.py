#!/usr/bin/env python3
"""
Simple Hash-Based Code Signing for OpenTofu Lab Automation

Creates digital signatures using cryptographic hashes and timestamps.
"""

import os
import sys
import json
import hashlib
import hmac
import base64
from pathlib import Path
from datetime import datetime
import secrets

class SimpleCodeSigner:
    """Simple hash-based code signing"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.signed_dir = project_root / "signed"
        self.keys_dir = project_root / "keys"
        
        # Create directories
        self.signed_dir.mkdir(exist_ok=True)
        self.keys_dir.mkdir(exist_ok=True)
        
        # Load or create signing key
        self.signing_key = self.get_or_create_signing_key()
        
    def get_or_create_signing_key(self):
        """Get existing signing key or create new one"""
        key_file = self.keys_dir / "signing_key.txt"
        
        if key_file.exists():
            with open(key_file, 'r') as f:
                return f.read().strip()
        else:
            # Generate new 256-bit key
            key = secrets.token_hex(32)
            with open(key_file, 'w') as f:
                f.write(key)
            
            # Create key info
            key_info = {
                'created': datetime.now().isoformat(),
                'algorithm': 'HMAC-SHA256',
                'key_length': 256,
                'purpose': 'OpenTofu Lab Automation Code Signing'
            }
            
            with open(self.keys_dir / "key_info.json", 'w') as f:
                json.dump(key_info, f, indent=2)
            
            print(f"✅ Created new signing key: {key_file}")
            return key
    
    def calculate_file_hash(self, file_path: Path):
        """Calculate SHA256 hash of file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
    
    def create_signature(self, file_path: Path):
        """Create HMAC signature for file"""
        if not file_path.exists():
            return None
        
        # Calculate file hash
        file_hash = self.calculate_file_hash(file_path)
        
        # Create signature data
        signature_data = {
            'file': str(file_path.relative_to(self.project_root)),
            'size': file_path.stat().st_size,
            'modified': datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
            'hash': file_hash,
            'algorithm': 'SHA256'
        }
        
        # Create HMAC signature
        signature_string = json.dumps(signature_data, sort_keys=True)
        signature = hmac.new(
            self.signing_key.encode(),
            signature_string.encode(),
            hashlib.sha256
        ).hexdigest()
        
        # Add signature and timestamp
        signature_data.update({
            'signature': signature,
            'signed_at': datetime.now().isoformat(),
            'signed_by': 'OpenTofu Lab Automation Simple Signer',
            'version': '1.0'
        })
        
        return signature_data
    
    def sign_file(self, file_path: Path):
        """Sign a file and save signature"""
        signature = self.create_signature(file_path)
        if not signature:
            return False
        
        # Save signature file
        sig_file = self.signed_dir / f"{file_path.name}.sig"
        with open(sig_file, 'w') as f:
            json.dump(signature, f, indent=2)
        
        return True
    
    def verify_signature(self, file_path: Path):
        """Verify file signature"""
        sig_file = self.signed_dir / f"{file_path.name}.sig"
        
        if not sig_file.exists():
            return False, "No signature file found"
        
        try:
            # Load signature
            with open(sig_file, 'r') as f:
                sig_data = json.load(f)
            
            # Verify file hash
            current_hash = self.calculate_file_hash(file_path)
            if current_hash != sig_data['hash']:
                return False, "File has been modified"
            
            # Recreate signature data without signature fields
            verify_data = {
                'file': sig_data['file'],
                'size': sig_data['size'],
                'modified': sig_data['modified'],
                'hash': sig_data['hash'],
                'algorithm': sig_data['algorithm']
            }
            
            # Verify HMAC signature
            verify_string = json.dumps(verify_data, sort_keys=True)
            expected_signature = hmac.new(
                self.signing_key.encode(),
                verify_string.encode(),
                hashlib.sha256
            ).hexdigest()
            
            if hmac.compare_digest(expected_signature, sig_data['signature']):
                return True, f"Valid signature (signed: {sig_data['signed_at']})"
            else:
                return False, "Invalid signature"
                
        except Exception as e:
            return False, f"Verification error: {e}"
    
    def sign_all_files(self):
        """Sign all relevant files in the project"""
        print("🖋️  Signing all files with hash-based signatures...")
        
        # File patterns to sign
        include_patterns = {
            '*.py', '*.ps1', '*.bat', '*.sh', '*.exe', '*.msi',
            '*.json', '*.yaml', '*.yml', '*.md', '*.txt'
        }
        
        signed_count = 0
        skipped_count = 0
        
        for pattern in include_patterns:
            for file_path in self.project_root.glob(f"**/{pattern}"):
                # Skip files in certain directories
                if any(part in str(file_path).lower() for part in [
                    '__pycache__', '.git', 'node_modules', 'venv', 
                    'signed', 'keys', '.pytest_cache', 'build', 'dist'
                ]):
                    skipped_count += 1
                    continue
                
                # Skip very large files (>10MB)
                if file_path.stat().st_size > 10 * 1024 * 1024:
                    print(f"⚠️  Skipping large file: {file_path.name}")
                    skipped_count += 1
                    continue
                
                if self.sign_file(file_path):
                    print(f"✅ Signed: {file_path.relative_to(self.project_root)}")
                    signed_count += 1
                else:
                    print(f"❌ Failed to sign: {file_path.name}")
        
        # Create signing manifest
        manifest = {
            'project': 'OpenTofu Lab Automation',
            'signing_method': 'HMAC-SHA256',
            'signed_at': datetime.now().isoformat(),
            'total_files_signed': signed_count,
            'files_skipped': skipped_count,
            'key_info': {
                'algorithm': 'HMAC-SHA256',
                'key_length': 256
            },
            'verification_note': 'Use verify_signature() method to check file integrity'
        }
        
        manifest_file = self.signed_dir / "signing_manifest.json"
        with open(manifest_file, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        print(f"\n📊 Signing Summary:")
        print(f"   ✅ Files signed: {signed_count}")
        print(f"   ⏭️  Files skipped: {skipped_count}")
        print(f"   📄 Manifest: {manifest_file}")
        
        return signed_count > 0
    
    def verify_all_signatures(self):
        """Verify all signed files"""
        print("🔍 Verifying all signatures...")
        
        valid_count = 0
        invalid_count = 0
        
        for sig_file in self.signed_dir.glob("*.sig"):
            if sig_file.name == "signing_manifest.json":
                continue
                
            # Get original file name
            original_name = sig_file.name[:-4]  # Remove .sig extension
            
            # Find the original file
            original_file = None
            for file_path in self.project_root.rglob(original_name):
                if file_path.is_file():
                    original_file = file_path
                    break
            
            if not original_file:
                print(f"❌ Original file not found for: {original_name}")
                invalid_count += 1
                continue
            
            valid, message = self.verify_signature(original_file)
            if valid:
                print(f"✅ {original_name}: {message}")
                valid_count += 1
            else:
                print(f"❌ {original_name}: {message}")
                invalid_count += 1
        
        print(f"\n📊 Verification Summary:")
        print(f"   ✅ Valid: {valid_count}")
        print(f"   ❌ Invalid: {invalid_count}")
        
        return invalid_count == 0

def main():
    """Main entry point"""
    project_root = Path(__file__).parent.parent
    signer = SimpleCodeSigner(project_root)
    
    print("🔐 OpenTofu Lab Automation - Simple Code Signing")
    print("=" * 55)
    
    # Sign all files
    if not signer.sign_all_files():
        print("❌ Failed to sign files")
        return 1
    
    # Verify signatures
    print("\n" + "=" * 55)
    if not signer.verify_all_signatures():
        print("⚠️  Some signatures are invalid")
    
    print("\n🎉 Code signing process completed!")
    print(f"📁 Signatures: {signer.signed_dir}")
    print(f"🔑 Keys: {signer.keys_dir}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

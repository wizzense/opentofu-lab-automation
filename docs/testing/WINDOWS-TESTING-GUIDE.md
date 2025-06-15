# Windows PowerShell Testing Guide

## Quick Start Issues & Solutions

### Issue 1: `curl` Command Not Found or Different Behavior
**Problem**: PowerShell's `curl` is an alias for `Invoke-WebRequest` and doesn't support bash flags like `-sL`

**Solution**: Use proper PowerShell syntax:
```powershell
# [FAIL] DON'T USE (bash syntax)
curl -sL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py | python

# [PASS] USE (PowerShell syntax)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py" | Select-Object -ExpandProperty Content | python
```

### Issue 2: 404 Errors on `/HEAD/` URLs
**Problem**: Feature branch files aren't merged to main yet

**Solution**: Test locally or use feature branch URLs:
```powershell
# Option A: Clone and test locally (RECOMMENDED)
git clone https://github.com/wizzense/opentofu-lab-automation.git
cd opentofu-lab-automation
git checkout feature/deployment-wrapper-gui
python deploy.py

# Option B: Use feature branch URLs directly (once pushed)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/deploy.py" -OutFile "deploy.py"
python deploy.py
```

## PowerShell Command Reference

### Download Files
```powershell
# Basic download
Invoke-WebRequest -Uri "URL" -OutFile "filename"

# Download and run immediately
Invoke-WebRequest -Uri "URL" | Select-Object -ExpandProperty Content | python

# Alternative with iwr alias
iwr "URL" -OutFile "filename"
```

### Check if Python is Available
```powershell
# Check Python installation
python --version
# OR
py --version

# Install Python if missing (requires admin)
winget install Python.Python.3.12
```

### Test the Deployment Scripts
```powershell
# Test CLI deployment
python deploy.py --help

# Test GUI launcher 
python gui.py

# Test Windows batch files
.\deploy.bat
.\launch-gui.bat
```

## Common PowerShell Environment Issues

### Execution Policy
If you get execution policy errors:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Python Path Issues
```powershell
# Check if python is in PATH
Get-Command python
Get-Command py

# Add Python to PATH if needed (replace with your Python path)
$env:PATH += ";C:\Python312;C:\Python312\Scripts"
```

### Alternative Testing Methods

#### Method 1: Local Git Clone (Most Reliable)
```powershell
git clone https://github.com/wizzense/opentofu-lab-automation.git
cd opentofu-lab-automation
git checkout feature/deployment-wrapper-gui
python deploy.py
```

#### Method 2: Download ZIP
1. Go to https://github.com/wizzense/opentofu-lab-automation
2. Click "Code" → "Download ZIP"
3. Extract and run `python deploy.py`

#### Method 3: Manual File Downloads
```powershell
# Create test directory
mkdir opentofu-test
cd opentofu-test

# Download individual files (after merge)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/deploy.py" -OutFile "deploy.py"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/gui.py" -OutFile "gui.py"

# Test
python deploy.py --help
python gui.py
```

## Expected Output

### Successful CLI Test
```
> python deploy.py --help
OpenTofu Lab Automation - Cross-Platform Deployment

Usage: deploy.py [options]
 -h, --help Show this help message
 -c, --config Specify config file
 -g, --gui Launch GUI mode
 -v, --verbose Enable verbose output
```

### Successful GUI Test
```
> python gui.py
[GUI should open with configuration options]
```

## Troubleshooting

### Error: "python: command not found"
- Install Python from python.org or Microsoft Store
- Use `py` instead of `python` on some Windows systems

### Error: "File not found" (404)
- Files are still in feature branch, not main
- Use local clone method for testing

### Error: "SSL/TLS errors"
```powershell
# Bypass SSL issues (temporary, for testing only)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
```

## Next Steps After Testing

Once you've successfully tested the deployment scripts:

1. **Report Success**: Let us know which method worked
2. **Test Features**: Try different deployment options
3. **Provide Feedback**: Report any issues or suggestions
4. **Ready for Merge**: Help us merge to main branch for easier access

## Support

If you encounter issues not covered here:
1. Check the main [TESTING-DEPLOYMENT-WRAPPER.md](TESTING-DEPLOYMENT-WRAPPER.md)
2. Review error messages carefully
3. Try the local clone method as fallback
4. Report specific error messages for assistance

## Recent Fixes (June 13, 2025)

### [PASS] FIXED: Prerequisites Check Error
**Problem**: GUI shows "can't open file 'C:\\temp\\deploy.py': No such file or directory"

**Solution Applied**: 
- Enhanced path detection with multiple fallback locations
- Automatic download of deploy.py if not found locally 
- Improved working directory handling

**Now Works**: Prerequisites check automatically finds or downloads deploy.py

### [PASS] FIXED: Windows Performance Issues
**Problem**: GUI caused severe system performance impact and multiple console windows

**Solutions Applied**:
- Reduced process priority to "below normal" for better system performance
- Added CREATE_NO_WINDOW flag to prevent extra console windows
- Optimized GUI update frequency (200ms instead of 100ms)
- Implemented batched output processing to prevent GUI freezing

**Now Works**: GUI runs smoothly without impacting system performance

### [PASS] FIXED: Windows File Association Issues 
**Problem**: Windows prompting to choose application for .py files

**Solutions Applied**:
- Enhanced launch-gui.bat with proper no-console launching
- Added launch-gui.ps1 for PowerShell users with clean window management
- Both launchers hide console windows automatically

**Now Works**: Clean GUI launch without extra windows or prompts

> ** Quick Copy-Paste Commands for Windows:**
> 
> **One-liner download and launch (copy this entire line):**
> ```powershell
> Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py" -OutFile "gui.py" -UseBasicParsing; python gui.py
> ```
> 
> **Or with error handling:**
> ```powershell
> try { Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py" -OutFile "gui.py" -UseBasicParsing; Write-Host "[PASS] Downloaded successfully"; python gui.py } catch { Write-Host "[FAIL] Error: $($_.Exception.Message)" }
> ```
> 
> **Multi-step (run each line separately):**
> ```powershell
> Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/gui.py" -OutFile "gui.py" -UseBasicParsing
> python gui.py
> ```

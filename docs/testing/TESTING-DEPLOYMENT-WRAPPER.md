# Testing Guide: Deployment Wrapper & GUI

## 🎯 Quick Test Checklist

### ✅ **CLI Testing**

#### 1. Test Main Deployment Script
```bash
# Test basic deployment
python3 deploy.py

# Test quick deployment (no questions)
python3 deploy.py --quick

# Test GUI launch from CLI
python3 deploy.py --gui

# Test help
python3 deploy.py --help
```

#### 2. Test Platform Launchers
```bash
# Linux/macOS
./deploy.sh
./launch-gui.sh

# Windows (in Command Prompt or PowerShell)
deploy.bat
launch-gui.bat
```

#### 3. Test CLI Downloads (New Feature)
```bash
# Test individual file download
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py
python3 deploy.py

# Test one-liner execution
curl -sL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py | python3
```

### 🎨 **GUI Testing**

#### 1. Launch GUI
```bash
# Method 1: Direct launcher
python3 gui.py

# Method 2: GUI launcher script
python3 launch-gui.py

# Method 3: Platform launcher
./launch-gui.sh    # Linux/macOS
launch-gui.bat     # Windows

# Method 4: Via deploy script
python3 deploy.py --gui
```

#### 2. Test Configuration Builder
- **Form Fields**: Verify all fields have sensible defaults
- **File Browsers**: Test "Browse" buttons for path selection
- **Load Config**: Test loading existing JSON config files
- **Save Config**: Test saving configuration to new files
- **Reset**: Test reset to defaults functionality

#### 3. Test Deployment Features
- **Prerequisites Check**: Click "🔍 Check Prerequisites"
- **Quick Deploy**: Click "⚡ Quick Deploy" 
- **Full Deploy**: Click "🚀 Deploy Lab"
- **Real-time Output**: Verify scrollable output display
- **Progress Monitoring**: Check status updates and progress bar
- **Stop Function**: Test "⏹️ Stop" button during deployment

### 🔧 **Configuration Testing**

#### 1. Test Default Configurations
```bash
# Check if default config works
ls -la configs/config_files/default-config.json

# Verify GUI loads defaults correctly
python3 gui.py
```

#### 2. Test Custom Configuration
```bash
# Create test config
cat > test-config.json << EOF
{
  "RepoUrl": "https://github.com/test/repo.git",
  "LocalPath": "/tmp/test-lab",
  "RunnerScriptName": "runner.ps1",
  "InfraRepoUrl": "https://github.com/test/infra.git", 
  "InfraRepoPath": "/tmp/test-infra",
  "Verbosity": "detailed"
}
EOF

# Test loading in GUI
python3 gui.py
# Then use "Load Config" button to load test-config.json
```

### 🌐 **Cross-Platform Testing**

#### Windows Testing
```cmd
REM Test Windows batch launcher
deploy.bat

REM Test Windows GUI launcher  
launch-gui.bat

REM Test PowerShell downloads
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py' -OutFile 'deploy.py'"
python deploy.py
```

#### Linux/macOS Testing
```bash
# Test shell launchers
chmod +x *.sh
./deploy.sh
./launch-gui.sh

# Test permissions
ls -la deploy.py gui.py launch-gui.py
# Should show executable permissions (rwxrwxrwx)

# Test curl downloads
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/gui.py
python3 gui.py
```

### ⚠️ **Error Scenario Testing**

#### 1. Missing Dependencies
```bash
# Test without tkinter (GUI should show helpful error)
# Note: This may require a Python environment without tkinter

# Test without Python (should show clear error)
# Test on system without Python 3.7+
```

#### 2. Invalid Configurations
```bash
# Test with malformed JSON
echo '{"invalid": json}' > bad-config.json
# Try to load in GUI

# Test with missing required fields
echo '{"RepoUrl": ""}' > incomplete-config.json
# Try to deploy with this config
```

#### 3. Network Issues
```bash
# Test with invalid repository URLs
# Test with unreachable servers
# Test download interruption scenarios
```

### 📊 **Validation Testing**

#### 1. File Structure Validation
```bash
# Verify all required files exist
ls -la deploy.py deploy.bat deploy.sh gui.py launch-gui.*
ls -la configs/config_files/default-config.json

# Check file permissions
stat deploy.py gui.py launch-gui.py
```

#### 2. Documentation Validation
```bash
# Verify README.md includes new download commands
grep -A 10 "Download individual files" README.md

# Check CHANGELOG.md for feature documentation
grep -A 5 "deployment wrapper" CHANGELOG.md
```

#### 3. Integration Testing
```bash
# Test with existing PowerShell scripts
python3 deploy.py --config configs/config_files/default-config.json

# Verify compatibility with existing workflows
./run-comprehensive-tests.ps1
```

## 🐛 **Known Issues to Watch For**

1. **tkinter Availability**: Some minimal Python installations may not include tkinter
2. **File Permissions**: Shell scripts may need executable permissions on Unix systems
3. **Path Separators**: Cross-platform path handling in configuration files
4. **PowerShell Execution Policy**: Windows may block script execution
5. **Network Timeouts**: Download commands may timeout on slow connections

## ✅ **Success Criteria**

- ✅ All launchers work on target platforms
- ✅ GUI loads without errors and displays configuration form
- ✅ Configuration can be loaded, edited, and saved
- ✅ Deployment starts and shows real-time output
- ✅ CLI download commands work from fresh directory
- ✅ Error handling shows helpful messages
- ✅ Documentation is clear and accurate

## 🚀 **Quick Smoke Test**

```bash
# 1. Basic functionality
python3 deploy.py --help

# 2. GUI launches
python3 gui.py

# 3. Download works
curl -LO https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/HEAD/deploy.py
python3 deploy.py --help

# 4. Platform launchers work
./launch-gui.sh    # Should open GUI
./deploy.sh        # Should start deployment
```

If all these pass, the deployment wrapper is working correctly! 🎉

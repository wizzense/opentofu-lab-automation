# -*- mode: python ; coding: utf-8 -*-
"""
Enhanced PyInstaller specification for OpenTofu Lab Automation GUI
Optimized for cross-platform deployment with advanced performance and size optimizations
"""

import sys
import os
from pathlib import Path

# Enhanced build configuration
block_cipher = None
debug = False

# Determine platform-specific optimizations
is_windows = sys.platform.startswith('win')
is_linux = sys.platform.startswith('linux')
is_mac = sys.platform.startswith('darwin')

# Base directory paths
gui_path = Path('gui.py')
project_root = Path('.')

# Enhanced data files to include
datas = [
    ('configs', 'configs'),              # Include config files (if exists)
    ('README.md', '.'),                  # Include documentation (if exists)
    ('LICENSE', '.'),                    # Include license (if exists)
]

# TCL/TK data handling - exclude problematic timezone files
import tkinter
import os
tcl_dir = os.path.dirname(tkinter.__file__)
if os.path.exists(tcl_dir):
    datas.append((tcl_dir, 'tcl'))

# Filter function to exclude problematic timezone files
def filter_timezone_data(data_list):
    """Filter out problematic timezone data files that cause extraction issues"""
    filtered = []
    problematic_patterns = [
        'tzdata/australia/lord_howe',
        'tzdata\\australia\\lord_howe',
        'lord_howe',
        'australia/lord_howe',
        'australia\\lord_howe'
    ]
    
    for item in data_list:
        if isinstance(item, tuple) and len(item) >= 2:
            src_path = str(item[0]).lower()
            # Skip problematic timezone files
            if not any(pattern in src_path for pattern in problematic_patterns):
                filtered.append(item)
        else:
            filtered.append(item)
    
    return filtered

# Apply filter to datas
datas = filter_timezone_data(datas)

# Conditional data files - only add if they exist
conditional_files = [
    ('version_info.txt', '.'),           # Version information
    ('assets', 'assets'),                # Include assets if they exist
]

for src, dst in conditional_files:
    if Path(src).exists():
        datas.append((src, dst))

# Enhanced hidden imports for GUI dependencies
hiddenimports = [
    # Core GUI dependencies
    'tkinter',
    'tkinter.ttk',
    'tkinter.filedialog',
    'tkinter.messagebox',
    'tkinter.scrolledtext',
    'tkinter.font',
    'tkinter.constants',    # System and threading
    'threading',
    'queue',
    'subprocess',
    'platform',
    'multiprocessing',
    'multiprocessing.spawn',
    'multiprocessing.util',
    'multiprocessing.pool',
    'multiprocessing.dummy',
    'multiprocessing.process',
    'multiprocessing.context',
    'multiprocessing.reduction',
    
    # Critical system modules
    'locale',
    'signal',
    'io',
    'os',
    'sys',
    'collections',
    'collections.abc',
    'functools',
    'itertools',
    'operator',
    'types',
    'weakref',
    
    # Network and socket modules
    'socket',
    '_socket',
    'ssl',
    'select',
    
    # Data handling
    'json',
    'pathlib',
    'time',
    'datetime',
    'hashlib',
    'uuid',
    
    # Network and web
    'urllib.request',
    'urllib.parse',
    'webbrowser',
    
    # File operations
    'shutil',
    'tempfile',
    'glob',
    
    # Error handling and logging
    'traceback',
    'logging',
    'warnings',
      # Encoding
    'encodings.utf_8',
    'encodings.ascii',
    'encodings.latin1',
    'encodings.cp1252',
    'encodings.idna',
    
    # Additional system modules for multiprocessing
    'atexit',
    'errno',
    'fcntl',
    'stat',
    'string',
    'struct',
    'copy',
    'pickle',
    'shelve',
]

# Platform-specific imports
if is_windows:
    hiddenimports.extend([
        'ctypes',
        'ctypes.wintypes',
        'msvcrt',
        'winreg',
        'winsound',
    ])
elif is_linux:
    hiddenimports.extend([
        'readline',
        'termios',
        'tty',
        'fcntl',
    ])
elif is_mac:
    hiddenimports.extend([
        'readline',
        'termios',
        'tty',
    ])

# Optional performance dependencies (add if available)
optional_imports = [
    'psutil',           # For performance optimizations
    'pillow',           # For image handling
    'numpy',            # For data processing (if used)
    'requests',         # For HTTP requests (if used)
]

for imp in optional_imports:
    try:
        __import__(imp)
        hiddenimports.append(imp)
    except ImportError:
        pass

# Enhanced excluded modules to reduce size significantly
excludes = [
    # Development and testing
    'setuptools',
    'pip',
    'wheel',
    'distutils',
    'unittest',
    'test',
    'tests',
    'pytest',
    'nose',
    'coverage',
    'tox',
    
    # Documentation and help
    'pydoc',
    'pydoc_data',
    'doctest',
    'help',
    
    # Development tools
    'pdb',
    'profile',
    'cProfile',
    'pstats',
    'trace',
    'py_compile',
    'compileall',
    
    # Alternative GUI frameworks
    'PyQt4',
    'PyQt5',
    'PyQt6',
    'PySide',
    'PySide2',
    'PySide6',
    'wx',
    'wxPython',
    'kivy',
    'pyglet',
    'pygame',
    
    # Scientific computing (unless needed)
    'matplotlib',
    'scipy',
    'pandas',
    'sympy',
    'sklearn',
    'tensorflow',
    'torch',
    'keras',
    
    # Web frameworks
    'django',
    'flask',
    'tornado',
    'bottle',
    'cherrypy',
    'pyramid',
    
    # Database
    'sqlite3',
    'pymongo',
    'psycopg2',
    'mysql',
    
    # Jupyter and IPython
    'jupyter',
    'IPython',
    'notebook',
    'ipykernel',
    'ipywidgets',
    
    # Email and web
    'email',
    'html',
    'http',
    'xml',
    'xmlrpc',
    'wsgiref',
      # Cryptography (if not needed)
    'cryptography',
      # Networking (keep socket and ssl for GUI functionality)
    'socketserver',
    'ftplib',
    'poplib',
    
    # TCL timezone data that causes issues
    '_tcl_data.tzdata.australia.lord_howe',
    'tcl.tzdata.australia.lord_howe',
    'imaplib',
    'smtplib',
    'telnetlib',
      # Package management
    'pkg_resources',
    'importlib_metadata',
    'packaging',
    
    # Internationalization (keep locale for system compatibility)
    'gettext',
    
    # Legacy modules
    'imp',
    'optparse',
    'dummy_threading',
]

# Platform-specific excludes
if is_windows:
    excludes.extend([
        'readline',
        'termios',
        'tty',
        'fcntl',
        'pwd',
        'grp',
        'resource',
        'syslog',
    ])
else:
    excludes.extend([
        'winsound',
        'msvcrt',
        'winreg',
        'ctypes.wintypes',
    ])

# Enhanced Analysis configuration with optimizations
source_file = 'gui.py'  # Use the fixed GUI file

a = Analysis(
    [source_file],# Use optimized source if available
    pathex=['.'],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=['.'],  # Include current directory for custom hooks
    hooksconfig={},
    runtime_hooks=[],
    excludes=excludes,
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
    optimize=2,  # Maximum optimization
)

# Advanced PYZ configuration for better compression
pyz = PYZ(
    a.pure, 
    a.zipped_data,
    cipher=block_cipher,
    # Add compression optimization
)

# Platform-specific executable configuration with enhanced settings
if is_windows:
    exe_name = 'OpenTofu-Lab-GUI.exe'
    console = False  # Hide console window
    icon = None  # Disable icon for now to avoid build issues
    version_file = 'version_info.txt' if Path('version_info.txt').exists() else None
elif is_mac:
    exe_name = 'OpenTofu-Lab-GUI'
    console = False
    icon = None  # Disable icon for now
    version_file = None
else:  # Linux
    exe_name = 'opentofu-lab-gui'
    console = False
    icon = None
    version_file = None

# Enhanced EXE configuration
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name=exe_name,
    debug=debug,
    bootloader_ignore_signals=False,
    strip=True,          # Strip debug symbols for smaller size
    upx=True,           # Enable UPX compression
    upx_exclude=[],
    runtime_tmpdir=None,
    console=console,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=icon,
    version=version_file,
    # Additional optimizations
    exclude_binaries=False,  # Include binaries for single file
)

# Enhanced macOS App Bundle configuration
if is_mac:
    app = BUNDLE(
        exe,
        name='OpenTofu Lab GUI.app',
        icon=icon,
        bundle_identifier='com.wizzense.opentofu.lab.gui',
        info_plist={
            'NSPrincipalClass': 'NSApplication',
            'NSAppleScriptEnabled': False,
            'CFBundleDisplayName': 'OpenTofu Lab GUI',
            'CFBundleVersion': '1.0.0',
            'CFBundleShortVersionString': '1.0.0',
            'NSHighResolutionCapable': True,
            'NSRequiresAquaSystemAppearance': False,
            'LSMinimumSystemVersion': '10.14.0',
            'CFBundleDocumentTypes': [{
                'CFBundleTypeName': 'Configuration File',
                'CFBundleTypeExtensions': ['json'],
                'CFBundleTypeRole': 'Editor',
            }],
            'UTExportedTypeDeclarations': [{
                'UTTypeIdentifier': 'com.wizzense.opentofu.config',
                'UTTypeDescription': 'OpenTofu Configuration',
                'UTTypeConformsTo': ['public.json'],
                'UTTypeTagSpecification': {
                    'public.filename-extension': ['json']
                }
            }],
        },
    )

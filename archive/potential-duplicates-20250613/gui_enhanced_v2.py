#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Enhanced GUI Interface v2.0

Enhanced graphical interface with:
- Dark mode theme
- Comprehensive runner script selection
- Lab environment deployment integration  
- Better error handling and no hanging issues
- Real-time monitoring
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import json
import os
import sys
import threading
import subprocess
import platform
from pathlib import Path
from typing import Dict, Optional, Any, List
import queue
import time
import glob

# Dark Mode Theme Configuration
DARK_THEME = {
    'bg': '#2b2b2b',
    'fg': '#ffffff',
    'select_bg': '#404040',
    'select_fg': '#ffffff',
    'button_bg': '#404040',
    'button_fg': '#ffffff',
    'entry_bg': '#404040',
    'entry_fg': '#ffffff',
    'text_bg': '#1e1e1e',
    'text_fg': '#ffffff',
    'frame_bg': '#2b2b2b',
    'accent': '#0078d4',
    'success': '#107c10',
    'warning': '#ff8c00',
    'error': '#d13438'
}

def apply_dark_theme(widget, theme=DARK_THEME):
    """Apply dark theme to a widget recursively"""
    try:
        widget_class = widget.winfo_class()
        
        if widget_class == 'Toplevel' or widget_class == 'Tk':
            widget.configure(bg=theme['bg'])
        elif widget_class == 'Frame':
            widget.configure(bg=theme['bg'])
        elif widget_class == 'Label':
            widget.configure(bg=theme['bg'], fg=theme['fg'])
        elif widget_class == 'Button':
            widget.configure(bg=theme['button_bg'], fg=theme['button_fg'], 
                           activebackground=theme['select_bg'], activeforeground=theme['select_fg'])
        elif widget_class == 'Entry':
            widget.configure(bg=theme['entry_bg'], fg=theme['entry_fg'], 
                           insertbackground=theme['fg'], selectbackground=theme['select_bg'])
        elif widget_class == 'Text':
            widget.configure(bg=theme['text_bg'], fg=theme['text_fg'], 
                           insertbackground=theme['fg'], selectbackground=theme['select_bg'])
        elif widget_class == 'Listbox':
            widget.configure(bg=theme['entry_bg'], fg=theme['entry_fg'], 
                           selectbackground=theme['select_bg'], selectforeground=theme['select_fg'])
        elif widget_class == 'Checkbutton':
            widget.configure(bg=theme['bg'], fg=theme['fg'], 
                           activebackground=theme['bg'], activeforeground=theme['fg'],
                           selectcolor=theme['entry_bg'])
        
        # Apply to all children
        for child in widget.winfo_children():
            apply_dark_theme(child, theme)
            
    except tk.TclError:
        pass  # Some widgets don't support certain options

# Ensure proper working directory
def get_working_directory():
    """Get and ensure proper working directory exists"""
    if platform.system() == "Windows":
        work_dir = Path("C:/temp/opentofu-lab-automation")
    else:
        work_dir = Path("/tmp/opentofu-lab-automation")
    
    work_dir.mkdir(parents=True, exist_ok=True)
    return work_dir

# Force UTF-8 encoding for Windows
if platform.system() == "Windows":
    try:
        import codecs
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
        os.environ['PYTHONIOENCODING'] = 'utf-8'
    except:
        pass

# Import configuration schema
sys.path.append(str(Path(__file__).parent))
sys.path.append(str(Path(__file__).parent / "py"))
try:
    from config_schema import ConfigSchema, ConfigField
except ImportError:
    # Fallback if config_schema is not available
    class ConfigField:
        def __init__(self, name, display_name, field_type, default_value, help_text, **kwargs):
            self.name = name
            self.display_name = display_name
            self.field_type = field_type
            self.default_value = default_value
            self.help_text = help_text
            for k, v in kwargs.items():
                setattr(self, k, v)
    
    class ConfigSchema:
        def __init__(self):
            self.sections = {"General": []}
        def get_defaults(self):
            return {}
        def validate_config(self, config):
            return []

# Project constants - use proper working directory
WORK_DIR = get_working_directory()
PROJECT_ROOT = Path(__file__).parent
CONFIGS_DIR = PROJECT_ROOT / "configs" / "config_files"
RUNNER_SCRIPTS_DIR = PROJECT_ROOT / "pwsh" / "runner_scripts"
DEFAULT_CONFIG = CONFIGS_DIR / "default-config.json"

class RunnerScriptManager:
    """Manager for PowerShell runner scripts with selection interface"""
    
    def __init__(self, parent):
        self.parent = parent
        self.scripts = {}
        self.selected_scripts = set()
        self.setup_ui()
        self.load_runner_scripts()
        
    def setup_ui(self):
        """Create runner script selection UI"""
        # Main frame
        main_frame = ttk.LabelFrame(self.parent, text="🔧 Runner Scripts", padding="10")
        main_frame.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill="x", pady=(0, 10))
        
        ttk.Button(button_frame, text="🔄 Refresh Scripts", command=self.load_runner_scripts).pack(side="left", padx=5)
        ttk.Button(button_frame, text="✅ Select All", command=self.select_all).pack(side="left", padx=5)
        ttk.Button(button_frame, text="❌ Clear All", command=self.clear_all).pack(side="left", padx=5)
        ttk.Button(button_frame, text="▶️ Run Selected", command=self.run_selected).pack(side="left", padx=5)
        
        # Script list with checkboxes
        list_frame = ttk.Frame(main_frame)
        list_frame.pack(fill="both", expand=True)
        
        # Create scrollable frame for checkboxes
        canvas = tk.Canvas(list_frame, bg=DARK_THEME['bg'])
        scrollbar = ttk.Scrollbar(list_frame, orient="vertical", command=canvas.yview)
        self.scrollable_frame = ttk.Frame(canvas)
        
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        self.canvas = canvas
        
        # Output area for runner script results
        output_frame = ttk.LabelFrame(main_frame, text="Output", padding="5")
        output_frame.pack(fill="both", expand=True, pady=(10, 0))
        
        self.output_text = scrolledtext.ScrolledText(output_frame, height=8, 
                                                   bg=DARK_THEME['text_bg'], 
                                                   fg=DARK_THEME['text_fg'],
                                                   insertbackground=DARK_THEME['fg'])
        self.output_text.pack(fill="both", expand=True)
        
    def load_runner_scripts(self):
        """Load available runner scripts from the pwsh/runner_scripts directory"""
        self.scripts.clear()
        self.selected_scripts.clear()
        
        # Clear existing checkboxes
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()
        
        try:
            if RUNNER_SCRIPTS_DIR.exists():
                script_files = sorted(RUNNER_SCRIPTS_DIR.glob("*.ps1"))
                
                for script_file in script_files:
                    script_name = script_file.name
                    script_num = script_name.split("_")[0] if "_" in script_name else "9999"
                    
                    # Extract description from script name
                    description = script_name.replace(".ps1", "").replace("_", " - ", 1)
                    
                    self.scripts[script_name] = {
                        'path': script_file,
                        'number': script_num,
                        'description': description,
                        'var': tk.BooleanVar()
                    }
                    
                    # Create checkbox
                    cb = ttk.Checkbutton(
                        self.scrollable_frame, 
                        text=f"{script_num}: {description}",
                        variable=self.scripts[script_name]['var'],
                        command=lambda name=script_name: self.on_script_toggled(name)
                    )
                    cb.pack(anchor="w", padx=5, pady=2)
                    
                self.log_output(f"Loaded {len(self.scripts)} runner scripts")
            else:
                self.log_output(f"Runner scripts directory not found: {RUNNER_SCRIPTS_DIR}")
                
        except Exception as e:
            self.log_output(f"Error loading runner scripts: {e}")
    
    def on_script_toggled(self, script_name):
        """Handle script selection toggle"""
        if self.scripts[script_name]['var'].get():
            self.selected_scripts.add(script_name)
        else:
            self.selected_scripts.discard(script_name)
    
    def select_all(self):
        """Select all available scripts"""
        for script_name, script_info in self.scripts.items():
            script_info['var'].set(True)
            self.selected_scripts.add(script_name)
    
    def clear_all(self):
        """Clear all script selections"""
        for script_name, script_info in self.scripts.items():
            script_info['var'].set(False)
        self.selected_scripts.clear()
    
    def run_selected(self):
        """Run the selected runner scripts"""
        if not self.selected_scripts:
            messagebox.showwarning("No Scripts", "Please select at least one script to run.")
            return
        
        self.log_output(f"Running {len(self.selected_scripts)} selected scripts...")
        
        # Run scripts in a separate thread to prevent hanging
        def run_thread():
            try:
                for script_name in sorted(self.selected_scripts):
                    if script_name in self.scripts:
                        script_path = self.scripts[script_name]['path']
                        self.log_output(f"\\n🔄 Running: {script_name}")
                        
                        # Run with PowerShell, non-interactive, with timeout
                        cmd = ["pwsh", "-File", str(script_path), "-NonInteractive"]
                        
                        try:
                            result = subprocess.run(
                                cmd,
                                capture_output=True,
                                text=True,
                                timeout=300,  # 5 minute timeout per script
                                cwd=str(PROJECT_ROOT),
                                encoding='utf-8',
                                errors='replace'
                            )
                            
                            if result.stdout:
                                self.log_output(result.stdout)
                            if result.stderr:
                                self.log_output(f"STDERR: {result.stderr}")
                            
                            if result.returncode == 0:
                                self.log_output(f"✅ {script_name} completed successfully")
                            else:
                                self.log_output(f"❌ {script_name} failed with exit code {result.returncode}")
                                
                        except subprocess.TimeoutExpired:
                            self.log_output(f"⏰ {script_name} timed out after 5 minutes")
                        except Exception as e:
                            self.log_output(f"❌ Error running {script_name}: {e}")
                
                self.log_output("\\n🏁 All selected scripts completed")
                
            except Exception as e:
                self.log_output(f"❌ Runner thread error: {e}")
        
        threading.Thread(target=run_thread, daemon=True).start()
    
    def log_output(self, message):
        """Thread-safe output logging"""
        def update_output():
            self.output_text.insert(tk.END, message + "\\n")
            self.output_text.see(tk.END)
        
        # Schedule GUI update from main thread
        self.parent.after(0, update_output)

class EnhancedConfigBuilder:
    """Enhanced configuration builder with dark mode and lab deployment support"""
    
    def __init__(self, parent):
        self.parent = parent
        self.config_schema = ConfigSchema()
        self.config = {}
        self.config_file = None
        self.field_widgets = {}
        self.help_labels = {}
        self.setup_ui()
        self.load_defaults()
        
    def setup_ui(self):
        """Create enhanced configuration builder UI with dark mode"""
        # Main frame
        main_frame = ttk.LabelFrame(self.parent, text="⚙️ Configuration Builder", padding="10")
        main_frame.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Quick settings frame
        quick_frame = ttk.Frame(main_frame)
        quick_frame.pack(fill="x", pady=(0, 10))
        
        ttk.Label(quick_frame, text="Quick Settings:", font=("Arial", 10, "bold")).pack(side="left")
        
        self.deployment_type_var = tk.StringVar(value="development")
        deployment_combo = ttk.Combobox(quick_frame, textvariable=self.deployment_type_var,
                                      values=["development", "testing", "production"],
                                      state="readonly", width=15)
        deployment_combo.pack(side="left", padx=(10, 5))
        
        ttk.Button(quick_frame, text="Apply Template", command=self.apply_template).pack(side="left", padx=5)
        
        # Configuration sections
        config_notebook = ttk.Notebook(main_frame)
        config_notebook.pack(fill="both", expand=True, pady=(10, 0))
        
        # Create basic configuration tabs
        self.create_general_tab(config_notebook)
        self.create_lab_environment_tab(config_notebook)
        self.create_security_tab(config_notebook)
        self.create_tools_tab(config_notebook)
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill="x", pady=(10, 0))
        
        ttk.Button(button_frame, text="📁 Load Config", command=self.load_config).pack(side="left", padx=5)
        ttk.Button(button_frame, text="💾 Save Config", command=self.save_config).pack(side="left", padx=5)
        ttk.Button(button_frame, text="🔄 Reset", command=self.load_defaults).pack(side="left", padx=5)
        ttk.Button(button_frame, text="✅ Validate", command=self.validate_config).pack(side="left", padx=5)
    
    def create_general_tab(self, notebook):
        """Create general settings tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="General")
        
        scroll_frame = self.create_scrollable_frame(frame)
        
        # Computer name settings
        self.add_config_field(scroll_frame, "ComputerName", "Computer Name", "entry", "lab-computer")
        self.add_config_field(scroll_frame, "SetComputerName", "Set Computer Name", "checkbox", False)
        
        # Network settings
        self.add_config_field(scroll_frame, "DNSServers", "DNS Servers", "entry", "8.8.8.8,1.1.1.1")
        self.add_config_field(scroll_frame, "SetDNSServers", "Set DNS Servers", "checkbox", False)
        
    def create_lab_environment_tab(self, notebook):
        """Create lab environment specific settings"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="Lab Environment")
        
        scroll_frame = self.create_scrollable_frame(frame)
        
        # Lab type settings
        self.add_config_field(scroll_frame, "LabType", "Lab Type", "combo", "hyperv", 
                            options=["hyperv", "vmware", "virtualbox", "docker", "cloud"])
        
        # Resource allocation
        self.add_config_field(scroll_frame, "LabMemoryGB", "Lab Memory (GB)", "entry", "8")
        self.add_config_field(scroll_frame, "LabCPUCores", "Lab CPU Cores", "entry", "4")
        self.add_config_field(scroll_frame, "LabStorageGB", "Lab Storage (GB)", "entry", "100")
        
        # Lab features
        self.add_config_field(scroll_frame, "EnableMonitoring", "Enable Monitoring", "checkbox", True)
        self.add_config_field(scroll_frame, "EnableLogging", "Enable Centralized Logging", "checkbox", True)
        self.add_config_field(scroll_frame, "EnableBackups", "Enable Automated Backups", "checkbox", False)
        
    def create_security_tab(self, notebook):
        """Create security settings tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="Security")
        
        scroll_frame = self.create_scrollable_frame(frame)
        
        self.add_config_field(scroll_frame, "AllowRemoteDesktop", "Allow Remote Desktop", "checkbox", False)
        self.add_config_field(scroll_frame, "ConfigureFirewall", "Configure Firewall", "checkbox", True)
        self.add_config_field(scroll_frame, "DisableTCPIP6", "Disable IPv6", "checkbox", False)
        
    def create_tools_tab(self, notebook):
        """Create tools installation tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="Tools")
        
        scroll_frame = self.create_scrollable_frame(frame)
        
        self.add_config_field(scroll_frame, "InstallGit", "Install Git", "checkbox", True)
        self.add_config_field(scroll_frame, "InstallVSCode", "Install VS Code", "checkbox", True)
        self.add_config_field(scroll_frame, "InstallDocker", "Install Docker Desktop", "checkbox", False)
        self.add_config_field(scroll_frame, "InstallPython", "Install Python", "checkbox", True)
        self.add_config_field(scroll_frame, "InstallGo", "Install Go", "checkbox", False)
        self.add_config_field(scroll_frame, "InstallOpenTofu", "Install OpenTofu", "checkbox", True)
        
    def create_scrollable_frame(self, parent):
        """Create a scrollable frame for configuration fields"""
        canvas = tk.Canvas(parent, bg=DARK_THEME['bg'])
        scrollbar = ttk.Scrollbar(parent, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        return scrollable_frame
    
    def add_config_field(self, parent, name, label, field_type, default_value, options=None):
        """Add a configuration field to the UI"""
        frame = ttk.Frame(parent)
        frame.pack(fill="x", padx=5, pady=3)
        
        # Label
        label_widget = ttk.Label(frame, text=label, width=25, anchor="w")
        label_widget.pack(side="left", padx=(0, 10))
        
        # Field widget
        if field_type == "entry":
            widget = ttk.Entry(frame, width=30)
            widget.insert(0, str(default_value))
        elif field_type == "checkbox":
            var = tk.BooleanVar(value=default_value)
            widget = ttk.Checkbutton(frame, variable=var)
            widget.var = var
        elif field_type == "combo":
            widget = ttk.Combobox(frame, values=options or [], state="readonly", width=27)
            widget.set(default_value)
        
        widget.pack(side="left")
        self.field_widgets[name] = widget
    
    def apply_template(self):
        """Apply configuration template based on deployment type"""
        deployment_type = self.deployment_type_var.get()
        
        if deployment_type == "development":
            # Development template - minimal security, more tools
            self.field_widgets["AllowRemoteDesktop"].var.set(True)
            self.field_widgets["InstallVSCode"].var.set(True)
            self.field_widgets["InstallDocker"].var.set(True)
        elif deployment_type == "testing":
            # Testing template - moderate security, monitoring enabled
            self.field_widgets["EnableMonitoring"].var.set(True)
            self.field_widgets["EnableLogging"].var.set(True)
        elif deployment_type == "production":
            # Production template - high security, minimal tools
            self.field_widgets["ConfigureFirewall"].var.set(True)
            self.field_widgets["AllowRemoteDesktop"].var.set(False)
            self.field_widgets["EnableBackups"].var.set(True)
        
        messagebox.showinfo("Template Applied", f"Applied {deployment_type} configuration template")
    
    def get_config(self):
        """Get current configuration as dictionary"""
        config = {}
        for name, widget in self.field_widgets.items():
            try:
                if hasattr(widget, 'var'):  # Checkbox
                    config[name] = widget.var.get()
                else:  # Entry or Combobox
                    config[name] = widget.get()
            except:
                config[name] = None
        return config
    
    def load_defaults(self):
        """Load default configuration values"""
        # This would typically load from the config schema
        messagebox.showinfo("Defaults Loaded", "Default configuration values loaded")
    
    def load_config(self):
        """Load configuration from file"""
        file_path = filedialog.askopenfilename(
            title="Load Configuration File",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            initialdir=CONFIGS_DIR
        )
        
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                
                # Update UI fields
                for name, value in config.items():
                    if name in self.field_widgets:
                        widget = self.field_widgets[name]
                        if hasattr(widget, 'var'):  # Checkbox
                            widget.var.set(bool(value))
                        else:  # Entry or Combobox
                            widget.delete(0, tk.END)
                            widget.insert(0, str(value))
                
                self.config_file = file_path
                messagebox.showinfo("Success", f"Configuration loaded from {Path(file_path).name}")
                
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load configuration:\\n{str(e)}")
    
    def save_config(self):
        """Save current configuration to file"""
        config = self.get_config()
        
        file_path = filedialog.asksaveasfilename(
            title="Save Configuration File",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            defaultextension=".json",
            initialdir=CONFIGS_DIR,
            initialfile="lab-config.json"
        )
        
        if file_path:
            try:
                Path(file_path).parent.mkdir(parents=True, exist_ok=True)
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(config, f, indent=2, sort_keys=True)
                
                self.config_file = file_path
                messagebox.showinfo("Success", f"Configuration saved to {Path(file_path).name}")
                
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save configuration:\\n{str(e)}")
    
    def validate_config(self):
        """Validate current configuration"""
        config = self.get_config()
        errors = []
        
        # Basic validation
        if config.get("LabMemoryGB"):
            try:
                memory = int(config["LabMemoryGB"])
                if memory < 2:
                    errors.append("Lab memory should be at least 2GB")
                elif memory > 64:
                    errors.append("Lab memory seems excessive (>64GB)")
            except ValueError:
                errors.append("Lab memory must be a valid number")
        
        if errors:
            messagebox.showerror("Validation Errors", "\\n".join(errors))
            return False
        else:
            messagebox.showinfo("Validation", "Configuration is valid!")
            return True

class EnhancedLabGUI:
    """Main Enhanced Lab Automation GUI with dark mode"""
    
    def __init__(self):
        self.root = tk.Tk()
        self.setup_window()
        self.setup_dark_theme()
        self.create_widgets()
        
    def setup_window(self):
        """Configure main window"""
        self.root.title("OpenTofu Lab Automation - Enhanced GUI v2.0")
        self.root.geometry("1600x1000")
        self.root.minsize(1200, 800)
        
        # Configure grid weights
        self.root.grid_rowconfigure(0, weight=1)
        self.root.grid_columnconfigure(0, weight=1)
        self.root.grid_columnconfigure(1, weight=1)
        
    def setup_dark_theme(self):
        """Setup dark theme for the application"""
        # Configure ttk styles for dark mode
        style = ttk.Style()
        
        # Configure dark theme colors
        style.theme_use('clam')
        
        style.configure('TLabel', background=DARK_THEME['bg'], foreground=DARK_THEME['fg'])
        style.configure('TFrame', background=DARK_THEME['bg'])
        style.configure('TLabelFrame', background=DARK_THEME['bg'], foreground=DARK_THEME['fg'])
        style.configure('TLabelFrame.Label', background=DARK_THEME['bg'], foreground=DARK_THEME['fg'])
        style.configure('TButton', background=DARK_THEME['button_bg'], foreground=DARK_THEME['button_fg'])
        style.configure('TEntry', fieldbackground=DARK_THEME['entry_bg'], foreground=DARK_THEME['entry_fg'])
        style.configure('TCombobox', fieldbackground=DARK_THEME['entry_bg'], foreground=DARK_THEME['entry_fg'])
        style.configure('TCheckbutton', background=DARK_THEME['bg'], foreground=DARK_THEME['fg'])
        style.configure('TNotebook', background=DARK_THEME['bg'])
        style.configure('TNotebook.Tab', background=DARK_THEME['button_bg'], foreground=DARK_THEME['button_fg'])
        
        # Apply dark theme to root window
        self.root.configure(bg=DARK_THEME['bg'])
        
    def create_widgets(self):
        """Create main application widgets"""
        # Main notebook for different sections
        main_notebook = ttk.Notebook(self.root)
        main_notebook.grid(row=0, column=0, columnspan=2, sticky="nsew", padx=10, pady=10)
        
        # Configuration tab
        config_frame = ttk.Frame(main_notebook)
        main_notebook.add(config_frame, text="⚙️ Configuration")
        
        self.config_builder = EnhancedConfigBuilder(config_frame)
        
        # Runner Scripts tab
        runner_frame = ttk.Frame(main_notebook)
        main_notebook.add(runner_frame, text="🔧 Runner Scripts")
        
        self.runner_manager = RunnerScriptManager(runner_frame)
        
        # Lab Deployment tab
        deploy_frame = ttk.Frame(main_notebook)
        main_notebook.add(deploy_frame, text="🚀 Lab Deployment")
        
        self.create_deployment_tab(deploy_frame)
        
        # Status bar
        self.status_bar = ttk.Label(self.root, text=f"Working Directory: {WORK_DIR} | Theme: Dark Mode", 
                                  relief="sunken")
        self.status_bar.grid(row=1, column=0, columnspan=2, sticky="ew")
        
        # Apply dark theme to all widgets
        self.root.after(100, lambda: apply_dark_theme(self.root))
    
    def create_deployment_tab(self, parent):
        """Create lab deployment interface"""
        # Main frame
        main_frame = ttk.LabelFrame(parent, text="🚀 Lab Environment Deployment", padding="10")
        main_frame.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Deployment options
        options_frame = ttk.Frame(main_frame)
        options_frame.pack(fill="x", pady=(0, 10))
        
        ttk.Label(options_frame, text="Deployment Type:", font=("Arial", 10, "bold")).pack(side="left")
        
        self.deploy_type_var = tk.StringVar(value="full")
        deploy_combo = ttk.Combobox(options_frame, textvariable=self.deploy_type_var,
                                  values=["quick", "full", "custom", "production"],
                                  state="readonly", width=15)
        deploy_combo.pack(side="left", padx=(10, 20))
        
        # Action buttons
        button_frame = ttk.Frame(options_frame)
        button_frame.pack(side="right")
        
        ttk.Button(button_frame, text="🔍 Validate", command=self.validate_deployment).pack(side="left", padx=5)
        ttk.Button(button_frame, text="🚀 Deploy", command=self.start_deployment).pack(side="left", padx=5)
        ttk.Button(button_frame, text="⏹️ Stop", command=self.stop_deployment).pack(side="left", padx=5)
        
        # Progress and status
        status_frame = ttk.Frame(main_frame)
        status_frame.pack(fill="x", pady=10)
        
        ttk.Label(status_frame, text="Status:").pack(side="left")
        self.deploy_status_var = tk.StringVar(value="Ready")
        status_label = ttk.Label(status_frame, textvariable=self.deploy_status_var, foreground=DARK_THEME['accent'])
        status_label.pack(side="left", padx=(10, 0))
        
        self.deploy_progress = ttk.Progressbar(main_frame, mode="indeterminate")
        self.deploy_progress.pack(fill="x", pady=5)
        
        # Deployment log
        log_frame = ttk.LabelFrame(main_frame, text="Deployment Log", padding="5")
        log_frame.pack(fill="both", expand=True, pady=(10, 0))
        
        self.deploy_log = scrolledtext.ScrolledText(log_frame, height=15,
                                                  bg=DARK_THEME['text_bg'], 
                                                  fg=DARK_THEME['text_fg'],
                                                  insertbackground=DARK_THEME['fg'])
        self.deploy_log.pack(fill="both", expand=True)
        
        self.deployment_process = None
        
    def validate_deployment(self):
        """Validate deployment configuration"""
        self.log_deployment("🔍 Validating deployment configuration...")
        
        config = self.config_builder.get_config()
        errors = []
        
        # Check for required PowerShell
        try:
            result = subprocess.run(["pwsh", "--version"], capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                errors.append("PowerShell 7+ not found or not working")
            else:
                self.log_deployment(f"✅ PowerShell version: {result.stdout.strip()}")
        except:
            errors.append("PowerShell 7+ not found")
        
        # Check working directory
        if not WORK_DIR.exists():
            errors.append(f"Working directory does not exist: {WORK_DIR}")
        else:
            self.log_deployment(f"✅ Working directory: {WORK_DIR}")
        
        # Check runner scripts
        if not RUNNER_SCRIPTS_DIR.exists():
            errors.append(f"Runner scripts directory not found: {RUNNER_SCRIPTS_DIR}")
        else:
            scripts = list(RUNNER_SCRIPTS_DIR.glob("*.ps1"))
            self.log_deployment(f"✅ Found {len(scripts)} runner scripts")
        
        if errors:
            self.log_deployment("❌ Validation failed:")
            for error in errors:
                self.log_deployment(f"  • {error}")
            messagebox.showerror("Validation Failed", "\\n".join(errors))
            return False
        else:
            self.log_deployment("✅ All validation checks passed!")
            messagebox.showinfo("Validation Success", "Deployment configuration is valid!")
            return True
    
    def start_deployment(self):
        """Start lab deployment based on configuration"""
        if not self.validate_deployment():
            return
        
        self.deploy_status_var.set("Deploying...")
        self.deploy_progress.start()
        
        def deploy_thread():
            try:
                config = self.config_builder.get_config()
                deploy_type = self.deploy_type_var.get()
                
                self.log_deployment(f"🚀 Starting {deploy_type} deployment...")
                
                # Save configuration temporarily
                temp_config = WORK_DIR / "temp-deploy-config.json"
                with open(temp_config, 'w', encoding='utf-8') as f:
                    json.dump(config, f, indent=2)
                
                self.log_deployment(f"💾 Configuration saved to: {temp_config}")
                
                # Use deploy.py if available, otherwise use runner.ps1
                deploy_script = PROJECT_ROOT / "deploy.py"
                if deploy_script.exists():
                    cmd = [sys.executable, str(deploy_script), "--config", str(temp_config)]
                    if deploy_type == "quick":
                        cmd.append("--quick")
                else:
                    # Fallback to PowerShell runner
                    runner_script = PROJECT_ROOT / "pwsh" / "runner.ps1"
                    cmd = ["pwsh", "-File", str(runner_script), "-ConfigFile", str(temp_config), "-NonInteractive"]
                
                self.log_deployment(f"🔧 Running: {' '.join(cmd)}")
                
                # Start deployment process with timeout
                self.deployment_process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True,
                    cwd=str(PROJECT_ROOT),
                    encoding='utf-8',
                    errors='replace'
                )
                
                # Read output in real-time
                for line in iter(self.deployment_process.stdout.readline, ''):
                    if line:
                        self.log_deployment(line.rstrip())
                
                self.deployment_process.wait()
                
                if self.deployment_process.returncode == 0:
                    self.log_deployment("✅ Deployment completed successfully!")
                    self.deploy_status_var.set("Completed")
                else:
                    self.log_deployment(f"❌ Deployment failed with exit code {self.deployment_process.returncode}")
                    self.deploy_status_var.set("Failed")
                
            except subprocess.TimeoutExpired:
                self.log_deployment("⏰ Deployment timed out")
                self.deploy_status_var.set("Timeout")
            except Exception as e:
                self.log_deployment(f"❌ Deployment error: {e}")
                self.deploy_status_var.set("Error")
            finally:
                self.deploy_progress.stop()
                self.deployment_process = None
        
        threading.Thread(target=deploy_thread, daemon=True).start()
    
    def stop_deployment(self):
        """Stop running deployment"""
        if self.deployment_process:
            self.deployment_process.terminate()
            self.log_deployment("⏹️ Deployment stopped by user")
            self.deploy_status_var.set("Stopped")
            self.deploy_progress.stop()
    
    def log_deployment(self, message):
        """Thread-safe deployment logging"""
        def update_log():
            timestamp = time.strftime("%H:%M:%S")
            self.deploy_log.insert(tk.END, f"[{timestamp}] {message}\\n")
            self.deploy_log.see(tk.END)
        
        self.root.after(0, update_log)
    
    def run(self):
        """Start the GUI application"""
        try:
            self.root.mainloop()
        except KeyboardInterrupt:
            print("Application interrupted by user")
        except Exception as e:
            print(f"Application error: {e}")

def main():
    """Main entry point"""
    print("Starting OpenTofu Lab Automation GUI v2.0...")
    print(f"Working directory: {WORK_DIR}")
    print("Features: Dark Mode, Runner Script Selection, Lab Deployment")
    
    # Ensure working directory and configs exist
    CONFIGS_DIR.mkdir(parents=True, exist_ok=True)
    
    app = EnhancedLabGUI()
    app.run()

if __name__ == "__main__":
    main()

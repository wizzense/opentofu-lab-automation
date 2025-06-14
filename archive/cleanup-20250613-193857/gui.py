#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Fixed GUI Interface

Fixed version with local prerequisite checking and proper button handling.
No more duplicate windo        # Main frame with larger styling
        self.frame = ttk.LabelFrame(self.parent, text="Deployment Management", padding="20")
        self.frame.grid(row=1, column=0, sticky="ew", padx=15, pady=10)or external process launches for simple checks.
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
from typing import Dict, Optional, Any
import queue
import time

# Project constants
PROJECT_ROOT = Path(__file__).parent
CONFIGS_DIR = PROJECT_ROOT / "configs" / "config_files"
DEFAULT_CONFIG = CONFIGS_DIR / "default-config.json"

class ConfigBuilder:
    """Configuration file builder and editor"""
    
    def __init__(self, parent):
        self.parent = parent
        self.config = {}
        self.config_file = None
        self.setup_ui()
        
    def setup_ui(self):
        """Create configuration builder UI"""        # Main frame with larger padding
        self.frame = ttk.LabelFrame(self.parent, text="Configuration Builder", padding="20")
        self.frame.grid(row=0, column=0, sticky="ew", padx=15, pady=10)
        
        # Configuration fields
        self.fields = {}
          # Repository URL with larger elements
        ttk.Label(self.frame, text="Repository URL:", style="Large.TLabel").grid(row=0, column=0, sticky="w", pady=5)
        self.fields['RepoUrl'] = ttk.Entry(self.frame, width=60, style="Large.TEntry")
        self.fields['RepoUrl'].grid(row=0, column=1, columnspan=2, sticky="ew", pady=5)
        self.fields['RepoUrl'].insert(0, "https://github.com/wizzense/tofu-base-lab.git")
        
        # Local Path with larger elements
        ttk.Label(self.frame, text="Local Path:", style="Large.TLabel").grid(row=1, column=0, sticky="w", pady=5)
        self.fields['LocalPath'] = ttk.Entry(self.frame, width=45, style="Large.TEntry")
        self.fields['LocalPath'].grid(row=1, column=1, sticky="ew", pady=5)
        ttk.Button(self.frame, text="Browse", command=self.browse_local_path, style="Large.TButton").grid(row=1, column=2, padx=(10,0), pady=5)
        
        # Set default path based on platform
        if platform.system() == "Windows":
            default_path = "C:/temp/opentofu-lab"
        else:
            default_path = "/tmp/opentofu-lab"
        self.fields['LocalPath'].insert(0, default_path)
        
        # Runner Script Name
        ttk.Label(self.frame, text="Runner Script:").grid(row=2, column=0, sticky="w", pady=2)
        self.fields['RunnerScriptName'] = ttk.Entry(self.frame, width=30)
        self.fields['RunnerScriptName'].grid(row=2, column=1, sticky="ew", pady=2)
        self.fields['RunnerScriptName'].insert(0, "run-lab.ps1")
        
        # Infrastructure Path
        ttk.Label(self.frame, text="Infrastructure Path:").grid(row=3, column=0, sticky="w", pady=2)
        self.fields['InfrastructurePath'] = ttk.Entry(self.frame, width=45)
        self.fields['InfrastructurePath'].grid(row=3, column=1, sticky="ew", pady=2)
        ttk.Button(self.frame, text="Browse", command=self.browse_infra_path).grid(row=3, column=2, padx=(5,0), pady=2)
        self.fields['InfrastructurePath'].insert(0, "infrastructure/")
        
        # Control buttons
        button_frame = ttk.Frame(self.frame)
        button_frame.grid(row=4, column=0, columnspan=3, pady=10)
        
        ttk.Button(button_frame, text="Load Config", command=self.load_config, style="Large.TButton").pack(side=tk.LEFT, padx=10)
        ttk.Button(button_frame, text="Save Config", command=self.save_config, style="Large.TButton").pack(side=tk.LEFT, padx=10)
        ttk.Button(button_frame, text="Reset Defaults", command=self.reset_defaults, style="Large.TButton").pack(side=tk.LEFT, padx=10)
        
        # Configure column weights
        self.frame.columnconfigure(1, weight=1)
        
    def browse_local_path(self):
        """Browse for local deployment path"""
        directory = filedialog.askdirectory(title="Select Local Deployment Path")
        if directory:
            self.fields['LocalPath'].delete(0, tk.END)
            self.fields['LocalPath'].insert(0, directory)
    
    def browse_infra_path(self):
        """Browse for infrastructure path"""
        directory = filedialog.askdirectory(title="Select Infrastructure Path")
        if directory:
            self.fields['InfrastructurePath'].delete(0, tk.END)
            self.fields['InfrastructurePath'].insert(0, directory)
    
    def get_config(self) -> Dict[str, Any]:
        """Get current configuration as dictionary"""
        config = {}
        for key, widget in self.fields.items():
            config[key] = widget.get()
        return config
    
    def load_config(self):
        """Load configuration from file"""
        file_path = filedialog.askopenfilename(
            title="Load Configuration",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                with open(file_path, 'r') as f:
                    config = json.load(f)
                
                # Update fields
                for key, value in config.items():
                    if key in self.fields:
                        self.fields[key].delete(0, tk.END)
                        self.fields[key].insert(0, str(value))
                
                self.config_file = file_path
                messagebox.showinfo("Success", f"Configuration loaded from {file_path}")
                
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load configuration: {e}")
    
    def save_config(self):
        """Save current configuration to file"""
        file_path = filedialog.asksaveasfilename(
            title="Save Configuration",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                config = self.get_config()
                with open(file_path, 'w') as f:
                    json.dump(config, f, indent=2)
                
                self.config_file = file_path
                messagebox.showinfo("Success", f"Configuration saved to {file_path}")
                
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save configuration: {e}")
    
    def reset_defaults(self):
        """Reset all fields to default values"""
        defaults = {
            'RepoUrl': 'https://github.com/wizzense/tofu-base-lab.git',
            'LocalPath': 'C:/temp/opentofu-lab' if platform.system() == "Windows" else '/tmp/opentofu-lab',
            'RunnerScriptName': 'run-lab.ps1',
            'InfrastructurePath': 'infrastructure/'
        }
        
        for key, value in defaults.items():
            if key in self.fields:
                self.fields[key].delete(0, tk.END)
                self.fields[key].insert(0, value)

class DeploymentManager:
    """Manages deployment process and real-time output"""
    
    def __init__(self, parent, config_builder):
        self.parent = parent
        self.config_builder = config_builder
        self.process = None
        self.output_queue = queue.Queue()
        self.setup_ui()
        
    def setup_ui(self):
        """Create deployment management UI"""
        # Main frame
        self.frame = ttk.LabelFrame(self.parent, text="Deployment Management", padding="10")
        self.frame.grid(row=1, column=0, sticky="nsew", padx=10, pady=5)
        
        # Control buttons
        button_frame = ttk.Frame(self.frame)
        button_frame.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 10))
        
        self.deploy_btn = ttk.Button(button_frame, text="🚀 Start Deployment", command=self.start_deployment, style="Large.TButton")
        self.deploy_btn.pack(side=tk.LEFT, padx=10)
        
        self.quick_btn = ttk.Button(button_frame, text="⚡ Quick Deploy", command=self.quick_deployment, style="Large.TButton")
        self.quick_btn.pack(side=tk.LEFT, padx=10)
        
        self.check_btn = ttk.Button(button_frame, text="🔍 Check Prerequisites", command=self.check_prerequisites, style="Large.TButton")
        self.check_btn.pack(side=tk.LEFT, padx=10)
        
        self.stop_btn = ttk.Button(button_frame, text="🛑 Stop", command=self.stop_deployment, state="disabled", style="Large.TButton")
        self.stop_btn.pack(side=tk.LEFT, padx=10)
        
        # Status label
        self.status_label = ttk.Label(self.frame, text="Ready", foreground="blue")
        self.status_label.grid(row=1, column=0, sticky="w", pady=5)
        
        # Output text area
        output_frame = ttk.Frame(self.frame)
        output_frame.grid(row=2, column=0, columnspan=2, sticky="nsew", pady=5)
        
        self.output_text = scrolledtext.ScrolledText(output_frame, height=15, wrap=tk.WORD, 
                                                   font=('Consolas', 11), padx=10, pady=10)
        self.output_text.pack(fill=tk.BOTH, expand=True)
        
        # Configure grid weights
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)
        
    def log_output(self, message: str):
        """Add message to output display"""
        timestamp = time.strftime("[%H:%M:%S]")
        full_message = f"{timestamp} {message}\n"
        
        self.output_text.insert(tk.END, full_message)
        self.output_text.see(tk.END)
        self.output_text.update()
        
    def update_status(self, status: str, color: str = "blue"):
        """Update status label"""
        self.status_label.config(text=status, foreground=color)
        
    def set_buttons_state(self, deploying: bool):
        """Enable/disable buttons based on deployment state"""
        state = "disabled" if deploying else "normal"
        stop_state = "normal" if deploying else "disabled"
        
        self.deploy_btn.config(state=state)
        self.quick_btn.config(state=state)
        self.check_btn.config(state=state)
        self.stop_btn.config(state=stop_state)
    
    def run_deployment_command(self, args: list):
        """Run deployment command in background"""
        try:
            python_cmd = sys.executable
            deploy_script = PROJECT_ROOT / "deploy.py"
            
            if not deploy_script.exists():
                self.log_output("❌ Deploy script not found!")
                self.deployment_complete(1)
                return
            
            cmd = [python_cmd, str(deploy_script)] + args
            self.log_output(f"Running: {' '.join(cmd)}")
            
            # Start process
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Read output
            for line in iter(self.process.stdout.readline, ''):
                if line:
                    self.output_queue.put(('output', line.strip()))
            
            # Wait for completion
            return_code = self.process.wait()
            self.output_queue.put(('complete', return_code))
            
        except Exception as e:
            self.output_queue.put(('error', str(e)))
    
    def check_output_queue(self):
        """Check for output from background process"""
        try:
            while True:
                msg_type, content = self.output_queue.get_nowait()
                
                if msg_type == 'output':
                    self.log_output(content)
                elif msg_type == 'complete':
                    self.deployment_complete(content)
                    return
                elif msg_type == 'error':
                    self.deployment_error(content)
                    return
                    
        except queue.Empty:
            pass
        
        # Schedule next check
        self.parent.after(100, self.check_output_queue)
    
    def deployment_complete(self, return_code: int):
        """Handle deployment completion"""
        if return_code == 0:
            self.log_output("🎉 Deployment completed successfully!")
            self.update_status("Deployment completed", "green")
        else:
            self.log_output(f"❌ Deployment failed with code {return_code}")
            self.update_status("Deployment failed", "red")
        
        self.set_buttons_state(False)
    
    def deployment_error(self, error: str):
        """Handle deployment error"""
        self.log_output(f"❌ Deployment error: {error}")
        self.update_status("Deployment error", "red")
        self.set_buttons_state(False)
    
    def start_deployment(self):
        """Start full deployment with current configuration"""
        self.set_buttons_state(True)
        self.update_status("Starting deployment...", "blue")
        self.output_text.delete(1.0, tk.END)
        
        # Save current config to temp file
        config = self.config_builder.get_config()
        temp_config = PROJECT_ROOT / "temp_config.json"
        
        try:
            with open(temp_config, 'w') as f:
                json.dump(config, f, indent=2)
            
            self.log_output(f"Using configuration: {config}")
        except Exception as e:
            self.log_output(f"Error saving config: {e}")
            self.set_buttons_state(False)
            return
        
        # Start deployment in background
        args = ['--config', str(temp_config), '--non-interactive']
        threading.Thread(target=self.run_deployment_command, args=[args], daemon=True).start()
        
        # Start output monitoring
        self.check_output_queue()
    
    def quick_deployment(self):
        """Start quick deployment with defaults"""
        self.set_buttons_state(True)
        self.update_status("Starting quick deployment...", "blue")
        self.output_text.delete(1.0, tk.END)
        
        # Start quick deployment
        args = ['--quick', '--non-interactive']
        threading.Thread(target=self.run_deployment_command, args=[args], daemon=True).start()
        
        # Start output monitoring
        self.check_output_queue()
    
    def check_prerequisites(self):
        """Check prerequisites locally without external process"""
        self.set_buttons_state(True)
        self.update_status("Checking prerequisites...", "blue")
        self.output_text.delete(1.0, tk.END)
        
        def run_local_checks():
            """Run prerequisite checks locally"""
            try:
                # Check Python version
                python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
                self.log_output(f"✅ Python: {python_version}")
                
                # Check tkinter
                try:
                    import tkinter
                    self.log_output("✅ GUI support (tkinter) available")
                except ImportError:
                    self.log_output("❌ tkinter not available")
                
                # Check project structure
                required_files = ['deploy.py', 'configs', 'pwsh', 'scripts']
                missing = []
                for file_path in required_files:
                    if not (PROJECT_ROOT / file_path).exists():
                        missing.append(file_path)
                
                if missing:
                    self.log_output(f"❌ Missing files/directories: {', '.join(missing)}")
                else:
                    self.log_output("✅ Project structure validated")
                
                # Check core dependencies
                try:
                    import json, pathlib, subprocess
                    self.log_output("✅ Core dependencies available")
                except ImportError as e:
                    self.log_output(f"❌ Missing dependency: {e}")
                
                # Check PowerShell modules
                pwsh_modules = PROJECT_ROOT / "pwsh" / "modules"
                if pwsh_modules.exists():
                    modules = list(pwsh_modules.iterdir())
                    self.log_output(f"✅ PowerShell modules: {len(modules)} found")
                else:
                    self.log_output("❌ PowerShell modules directory not found")
                
                self.log_output("\n🎉 Prerequisites check completed!")
                
                # Update UI on main thread
                self.parent.after(0, lambda: [
                    self.update_status("Prerequisites check completed", "green"),
                    self.set_buttons_state(False)
                ])
                
            except Exception as e:
                self.log_output(f"❌ Error during checks: {e}")
                self.parent.after(0, lambda: [
                    self.update_status("Prerequisites check failed", "red"),
                    self.set_buttons_state(False)
                ])
        
        # Run checks in background thread
        threading.Thread(target=run_local_checks, daemon=True).start()
    
    def stop_deployment(self):
        """Stop current deployment"""
        if self.process:
            try:
                self.process.terminate()
                self.log_output("🛑 Deployment stopped by user")
                self.update_status("Deployment stopped", "orange")
            except Exception as e:
                self.log_output(f"Error stopping deployment: {e}")
        
        self.set_buttons_state(False)

class LabAutomationGUI:
    """Main GUI application"""
    
    def __init__(self):
        self.root = tk.Tk()
        self.optimize_performance()
        self.setup_window()
        self.create_widgets()
        self.create_menu()
        self.load_initial_config()
    
    def optimize_performance(self):
        """Apply performance optimizations with proper DPI scaling"""
        # Disable window resizing during creation
        self.root.resizable(False, False)
        
        # Configure DPI scaling for Windows
        if platform.system() == "Windows":
            try:
                from ctypes import windll
                windll.shcore.SetProcessDpiAwareness(1)
            except:
                pass
        
        # Set proper scaling for high-DPI displays
        self.root.tk.call('tk', 'scaling', 1.5)  # Increase scaling for better visibility        # Configure default fonts for better readability
        default_font = ('Segoe UI', 10)
        self.root.option_add('*Font', default_font)        # Configure ttk styles for larger elements
        style = ttk.Style()
        
        # Configure button styles with larger padding
        style.configure("Large.TButton", 
                       padding=(15, 10),
                       font=('Segoe UI', 11, 'normal'))
        
        # Configure entry field styles with larger padding  
        style.configure("Large.TEntry", 
                       padding=(8, 6),
                       font=('Segoe UI', 11))
        
        # Configure label styles with larger fonts
        style.configure("Large.TLabel", 
                       font=('Segoe UI', 12, 'normal'))
    
    def setup_window(self):
        """Configure main window with larger size for better visibility"""
        self.root.title("OpenTofu Lab Automation")
        self.root.geometry("1400x900")  # Much larger window
        
        # Center window on screen
        self.root.update_idletasks()
        x = (self.root.winfo_screenwidth() - self.root.winfo_width()) // 2
        y = (self.root.winfo_screenheight() - self.root.winfo_height()) // 2
        self.root.geometry(f"+{x}+{y}")
        
        # Configure grid weights
        self.root.grid_rowconfigure(1, weight=1)
        self.root.grid_columnconfigure(0, weight=1)
        
        # Re-enable resizing
        self.root.resizable(True, True)
        
        # Set minimum size - much larger
        self.root.minsize(1200, 800)
        
    def create_widgets(self):
        """Create main application widgets"""
        # Create main components
        self.config_builder = ConfigBuilder(self.root)
        self.deployment_manager = DeploymentManager(self.root, self.config_builder)
        
        # Status bar
        status_frame = ttk.Frame(self.root)
        status_frame.grid(row=2, column=0, sticky="ew", padx=5, pady=2)
        
        ttk.Label(status_frame, text="OpenTofu Lab Automation v1.0").pack(side=tk.LEFT)
        ttk.Label(status_frame, text=f"Platform: {platform.system()}").pack(side=tk.RIGHT)
        
    def create_menu(self):
        """Create application menu"""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)
        
        # File menu
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="Open Project Folder", command=self.open_project_folder)
        file_menu.add_command(label="Open Config Folder", command=self.open_config_folder)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)
        
        # Tools menu
        tools_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Tools", menu=tools_menu)
        tools_menu.add_command(label="Check Prerequisites", command=self.deployment_manager.check_prerequisites)
        
        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="Documentation", command=self.open_documentation)
        help_menu.add_command(label="About", command=self.show_about)
    
    def load_initial_config(self):
        """Load initial configuration if available"""
        if DEFAULT_CONFIG.exists():
            try:
                with open(DEFAULT_CONFIG, 'r') as f:
                    config = json.load(f)
                
                # Update config builder fields
                for key, value in config.items():
                    if key in self.config_builder.fields:
                        self.config_builder.fields[key].delete(0, tk.END)
                        self.config_builder.fields[key].insert(0, str(value))
                        
            except Exception as e:
                print(f"Warning: Could not load default config: {e}")
    
    def open_project_folder(self):
        """Open project folder in file explorer"""
        try:
            if platform.system() == "Windows":
                os.startfile(PROJECT_ROOT)
            elif platform.system() == "Darwin":
                subprocess.run(["open", PROJECT_ROOT])
            else:
                subprocess.run(["xdg-open", PROJECT_ROOT])
        except Exception as e:
            messagebox.showerror("Error", f"Could not open folder: {e}")
    
    def open_config_folder(self):
        """Open config folder in file explorer"""
        try:
            CONFIGS_DIR.mkdir(parents=True, exist_ok=True)
            if platform.system() == "Windows":
                os.startfile(CONFIGS_DIR)
            elif platform.system() == "Darwin":
                subprocess.run(["open", CONFIGS_DIR])
            else:
                subprocess.run(["xdg-open", CONFIGS_DIR])
        except Exception as e:
            messagebox.showerror("Error", f"Could not open config folder: {e}")
    
    def open_documentation(self):
        """Open documentation in web browser"""
        import webbrowser
        docs_url = "https://github.com/wizzense/opentofu-lab-automation/blob/main/README.md"
        webbrowser.open(docs_url)
    
    def show_about(self):
        """Show about dialog"""
        about_text = """OpenTofu Lab Automation
        
A cross-platform tool for deploying and managing 
OpenTofu laboratory environments.

Version: 1.0.0
Platform: """ + platform.system() + """
Python: """ + f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}" + """

© 2025 OpenTofu Lab Automation Project"""
        
        messagebox.showinfo("About", about_text)
    
    def run(self):
        """Start the application"""
        self.root.mainloop()

def main():
    """Main entry point"""
    # Check for tkinter availability
    try:
        import tkinter
    except ImportError:
        print("❌ tkinter is required but not available.")
        print("Please install tkinter for your Python distribution.")
        return 1
    
    # Windows-specific optimizations
    if platform.system() == "Windows":
        try:
            # Try to set DPI awareness
            import ctypes
            ctypes.windll.shcore.SetProcessDpiAwareness(1)
        except:
            pass
    
    # Create and run application
    try:
        app = LabAutomationGUI()
        app.run()
        return 0
    except Exception as e:
        print(f"❌ Application error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

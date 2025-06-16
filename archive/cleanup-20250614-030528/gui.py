#!/usr/bin/env python3
"""
OpenTofu Lab Automation - GUI Interface

A cross-platform graphical interface for deploying and managing OpenTofu lab environments.
Features configuration file builder, deployment management, and real-time progress monitoring.

Dependencies: tkinter (included with Python), threading
Requires: Python 3.7+
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
        """Create configuration builder UI"""
        # Main frame
        self.frame = ttk.LabelFrame(self.parent, text="Configuration Builder", padding="10")
        self.frame.grid(row=0, column=0, sticky="ew", padx=10, pady=5)
        
        # Configuration fields
        self.fields = {}
        
        # Repository URL
        ttk.Label(self.frame, text="Repository URL:").grid(row=0, column=0, sticky="w", pady=2)
        self.fields'RepoUrl' = ttk.Entry(self.frame, width=60)
        self.fields'RepoUrl'.grid(row=0, column=1, columnspan=2, sticky="ew", pady=2)
        self.fields'RepoUrl'.insert(0, "https://github.com/wizzense/tofu-base-lab.git")
        
        # Local Path
        ttk.Label(self.frame, text="Local Path:").grid(row=1, column=0, sticky="w", pady=2)
        self.fields'LocalPath' = ttk.Entry(self.frame, width=45)
        self.fields'LocalPath'.grid(row=1, column=1, sticky="ew", pady=2)
        ttk.Button(self.frame, text="Browse", command=self.browse_local_path).grid(row=1, column=2, padx=(5,0), pady=2)
        
        # Set default path based on platform
        if platform.system() == "Windows":
            self.fields'LocalPath'.insert(0, "C:\\Temp\\lab")
        else:
            self.fields'LocalPath'.insert(0, "/tmp/lab")
        
        # Runner Script Name
        ttk.Label(self.frame, text="Runner Script:").grid(row=2, column=0, sticky="w", pady=2)
        self.fields'RunnerScriptName' = ttk.Entry(self.frame, width=30)
        self.fields'RunnerScriptName'.grid(row=2, column=1, sticky="w", pady=2)
        self.fields'RunnerScriptName'.insert(0, "runner.ps1")
        
        # Infrastructure Repository URL
        ttk.Label(self.frame, text="Infrastructure Repo:").grid(row=3, column=0, sticky="w", pady=2)
        self.fields'InfraRepoUrl' = ttk.Entry(self.frame, width=60)
        self.fields'InfraRepoUrl'.grid(row=3, column=1, columnspan=2, sticky="ew", pady=2)
        self.fields'InfraRepoUrl'.insert(0, "https://github.com/wizzense/base-infra.git")
        
        # Infrastructure Path
        ttk.Label(self.frame, text="Infrastructure Path:").grid(row=4, column=0, sticky="w", pady=2)
        self.fields'InfraRepoPath' = ttk.Entry(self.frame, width=45)
        self.fields'InfraRepoPath'.grid(row=4, column=1, sticky="ew", pady=2)
        ttk.Button(self.frame, text="Browse", command=self.browse_infra_path).grid(row=4, column=2, padx=(5,0), pady=2)
        
        # Set default infra path
        if platform.system() == "Windows":
            self.fields'InfraRepoPath'.insert(0, "C:\\Temp\\base-infra")
        else:
            self.fields'InfraRepoPath'.insert(0, "/tmp/base-infra")
        
        # Verbosity
        ttk.Label(self.frame, text="Verbosity:").grid(row=5, column=0, sticky="w", pady=2)
        self.fields'Verbosity' = ttk.Combobox(self.frame, values="silent", "normal", "detailed", width=15)
        self.fields'Verbosity'.grid(row=5, column=1, sticky="w", pady=2)
        self.fields'Verbosity'.set("normal")
        
        # Buttons frame
        button_frame = ttk.Frame(self.frame)
        button_frame.grid(row=6, column=0, columnspan=3, pady=10)
        
        ttk.Button(button_frame, text="Load Config", command=self.load_config).pack(side="left", padx=5)
        ttk.Button(button_frame, text="Save Config", command=self.save_config).pack(side="left", padx=5)
        ttk.Button(button_frame, text="Reset to Defaults", command=self.reset_defaults).pack(side="left", padx=5)
        
        # Configure column weights
        self.frame.columnconfigure(1, weight=1)
        
    def browse_local_path(self):
        """Browse for local deployment path"""
        directory = filedialog.askdirectory(title="Select Local Deployment Directory")
        if directory:
            self.fields'LocalPath'.delete(0, tk.END)
            self.fields'LocalPath'.insert(0, directory)
    
    def browse_infra_path(self):
        """Browse for infrastructure path"""
        directory = filedialog.askdirectory(title="Select Infrastructure Directory")
        if directory:
            self.fields'InfraRepoPath'.delete(0, tk.END)
            self.fields'InfraRepoPath'.insert(0, directory)
    
    def get_config(self) -> Dictstr, Any:
        """Get current configuration from UI fields"""
        config = {}
        for key, field in self.fields.items():
            value = field.get().strip()
            if value:  # Only include non-empty values
                configkey = value
        return config
    
    def load_config(self):
        """Load configuration from file"""
        file_path = filedialog.askopenfilename(
            title="Load Configuration File",
            filetypes=("JSON files", "*.json"), ("All files", "*.*"),
            initialdir=CONFIGS_DIR
        )
        
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                
                # Clear and populate fields
                for key, field in self.fields.items():
                    field.delete(0, tk.END)
                    if key in config:
                        field.insert(0, str(configkey))
                
                self.config_file = file_path
                messagebox.showinfo("Success", f"Configuration loaded from {Path(file_path).name}")
                
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load configuration:\n{str(e)}")
    
    def save_config(self):
        """Save current configuration to file"""
        config = self.get_config()
        
        if not config:
            messagebox.showwarning("Warning", "No configuration to save!")
            return
        
        file_path = filedialog.asksaveasfilename(
            title="Save Configuration File",
            filetypes=("JSON files", "*.json"), ("All files", "*.*"),
            defaultextension=".json",
            initialdir=CONFIGS_DIR,
            initialfile="my-lab-config.json"
        )
        
        if file_path:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(config, f, indent=2)
                
                self.config_file = file_path
                messagebox.showinfo("Success", f"Configuration saved to {Path(file_path).name}")
                
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save configuration:\n{str(e)}")
    
    def reset_defaults(self):
        """Reset all fields to default values"""
        defaults = {
            'RepoUrl': "https://github.com/wizzense/tofu-base-lab.git",
            'LocalPath': "C:\\Temp\\lab" if platform.system() == "Windows" else "/tmp/lab",
            'RunnerScriptName': "runner.ps1",
            'InfraRepoUrl': "https://github.com/wizzense/base-infra.git",
            'InfraRepoPath': "C:\\Temp\\base-infra" if platform.system() == "Windows" else "/tmp/base-infra",
            'Verbosity': "normal"
        }
        
        for key, field in self.fields.items():
            field.delete(0, tk.END)
            if key in defaults:
                field.insert(0, defaultskey)

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
        self.frame.grid(row=1, column=0, sticky="ew", padx=10, pady=5)
        
        # Control buttons
        button_frame = ttk.Frame(self.frame)
        button_frame.grid(row=0, column=0, sticky="ew", pady=(0, 10))
        
        self.deploy_btn = ttk.Button(button_frame, text=" Deploy Lab", command=self.start_deployment)
        self.deploy_btn.pack(side="left", padx=5)
        
        self.quick_btn = ttk.Button(button_frame, text=" Quick Deploy", command=self.quick_deployment)
        self.quick_btn.pack(side="left", padx=5)
        
        self.check_btn = ttk.Button(button_frame, text="� Check Prerequisites", command=self.check_prerequisites)
        self.check_btn.pack(side="left", padx=5)
        
        self.stop_btn = ttk.Button(button_frame, text="⏹ Stop", command=self.stop_deployment, state="disabled")
        self.stop_btn.pack(side="left", padx=5)
        
        # Progress bar
        self.progress_var = tk.StringVar(value="Ready")
        ttk.Label(self.frame, text="Status:").grid(row=1, column=0, sticky="w")
        self.status_label = ttk.Label(self.frame, textvariable=self.progress_var, foreground="blue")
        self.status_label.grid(row=1, column=0, sticky="w", padx=(50, 0))
        
        self.progress = ttk.Progressbar(self.frame, mode="indeterminate")
        self.progress.grid(row=2, column=0, sticky="ew", pady=5)
        
        # Output display
        ttk.Label(self.frame, text="Deployment Output:").grid(row=3, column=0, sticky="w", pady=(10, 5))
        
        self.output_text = scrolledtext.ScrolledText(self.frame, height=20, width=80)
        self.output_text.grid(row=4, column=0, sticky="ew", pady=5)
        
        # Configure column weights
        self.frame.columnconfigure(0, weight=1)
        
    def log_output(self, message: str):
        """Add message to output display"""
        self.output_text.insert(tk.END, f"{time.strftime('%H:%M:%S')} - {message}\n")
        self.output_text.see(tk.END)
        
    def update_status(self, status: str, color: str = "blue"):
        """Update status label"""
        self.progress_var.set(status)
        self.status_label.configure(foreground=color)
        
    def set_buttons_state(self, deploying: bool):
        """Enable/disable buttons based on deployment state"""
        state = "disabled" if deploying else "normal"
        self.deploy_btn.configure(state=state)
        self.quick_btn.configure(state=state)
        self.check_btn.configure(state=state)
        self.stop_btn.configure(state="normal" if deploying else "disabled")
        
        if deploying:
            self.progress.start()
        else:
            self.progress.stop()
    
    def run_deployment_command(self, args: list):
        """Run deployment command in background thread"""
        try:
            # Find deploy.py - check multiple locations
            possible_locations = 
                PROJECT_ROOT / "deploy.py",  # Same directory as GUI
                Path.cwd() / "deploy.py",    # Current working directory
                Path(__file__).parent / "deploy.py",  # Script directory
            
            
            deploy_script = None
            for location in possible_locations:
                if location.exists():
                    deploy_script = location
                    break
            
            if not deploy_script:
                # Try to download deploy.py if not found
                self.log_output("WARN deploy.py not found locally, attempting to download...")
                try:
                    import urllib.request
                    deploy_url = "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/feature/deployment-wrapper-gui/deploy.py"
                    deploy_script = Path.cwd() / "deploy.py"
                    urllib.request.urlretrieve(deploy_url, deploy_script)
                    self.log_output(f"PASS Downloaded deploy.py to {deploy_script}")
                except Exception as e:
                    self.output_queue.put(('error', f"Could not find or download deploy.py: {str(e)}"))
                    return
            
            # Build command
            cmd = sys.executable, str(deploy_script) + args
            
            self.log_output(f"Running: {' '.join(cmd)}")
            self.log_output(f"Deploy script location: {deploy_script}")
            
            # Start process
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                cwd=deploy_script.parent,  # Set working directory to script location
                bufsize=1,
                universal_newlines=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == "Windows" else 0
            )
            
            # Read output in real-time
            for line in iter(self.process.stdout.readline, ''):
                if line:
                    self.output_queue.put(('output', line.rstrip()))
                
            # Wait for completion
            return_code = self.process.wait()
            self.output_queue.put(('complete', return_code))
            
        except Exception as e:
            self.output_queue.put(('error', str(e)))
        
        finally:
            self.process = None
    
    def check_output_queue(self):
        """Check for new output from deployment process"""
        processed_count = 0
        max_per_cycle = 10  # Limit processing to prevent GUI freezing
        
        try:
            while processed_count < max_per_cycle:
                msg_type, data = self.output_queue.get_nowait()
                
                if msg_type == 'output':
                    self.log_output(data)
                elif msg_type == 'complete':
                    self.deployment_complete(data)
                    return  # Don't schedule next check if deployment is complete
                elif msg_type == 'error':
                    self.deployment_error(data)
                    return  # Don't schedule next check if there's an error
                
                processed_count += 1
                    
        except queue.Empty:
            pass
        
        # Schedule next check with slightly longer delay for better performance
        if self.process is not None:
            self.parent.after(200, self.check_output_queue)  # Increased from 100ms to 200ms
    
    def deployment_complete(self, return_code: int):
        """Handle deployment completion"""
        self.set_buttons_state(False)
        
        if return_code == 0:
            self.update_status("Deployment completed successfully!", "green")
            self.log_output(" Deployment completed successfully!")
            messagebox.showinfo("Success", "Lab deployment completed successfully!")
        else:
            self.update_status("Deployment failed", "red")
            self.log_output(f"FAIL Deployment failed with exit code {return_code}")
            messagebox.showerror("Error", f"Deployment failed with exit code {return_code}")
    
    def deployment_error(self, error: str):
        """Handle deployment error"""
        self.set_buttons_state(False)
        self.update_status("Deployment error", "red")
        self.log_output(f"� Error: {error}")
        messagebox.showerror("Error", f"Deployment error:\n{error}")
    
    def start_deployment(self):
        """Start interactive deployment"""
        config = self.config_builder.get_config()
        
        if not config:
            messagebox.showwarning("Warning", "Please configure your deployment settings first!")
            return
        
        # Save temporary config
        temp_config = PROJECT_ROOT / "temp-gui-config.json"
        try:
            with open(temp_config, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save configuration:\n{str(e)}")
            return
        
        self.set_buttons_state(True)
        self.update_status("Starting deployment...", "blue")
        self.output_text.delete(1.0, tk.END)
        
        # Start deployment in background
        args = '--config', str(temp_config), '--non-interactive'
        threading.Thread(target=self.run_deployment_command, args=args, daemon=True).start()
        
        # Start output monitoring
        self.check_output_queue()
    
    def quick_deployment(self):
        """Start quick deployment with defaults"""
        self.set_buttons_state(True)
        self.update_status("Starting quick deployment...", "blue")
        self.output_text.delete(1.0, tk.END)
        
        # Start quick deployment
        args = '--quick', '--non-interactive'
        threading.Thread(target=self.run_deployment_command, args=args, daemon=True).start()
        
        # Start output monitoring
        self.check_output_queue()
    
    def check_prerequisites(self):
        """Check prerequisites only"""
        self.set_buttons_state(True)
        self.update_status("Checking prerequisites...", "blue")
        self.output_text.delete(1.0, tk.END)
        
        # Start prerequisites check
        args = '--check', '--non-interactive'
        threading.Thread(target=self.run_deployment_command, args=args, daemon=True).start()
        
        # Start output monitoring
        self.check_output_queue()
    
    def stop_deployment(self):
        """Stop current deployment"""
        if self.process:
            try:
                self.process.terminate()
                self.log_output("� Deployment stopped by user")
                self.update_status("Deployment stopped", "orange")
            except Exception as e:
                self.log_output(f"Error stopping deployment: {e}")
        
        self.set_buttons_state(False)

class LabAutomationGUI:
    """Main GUI application"""
    
    def __init__(self):
        self.root = tk.Tk()
        self.setup_window()
        self.create_widgets()
        self.load_initial_config()
        
        # Performance optimizations
        self.optimize_performance()
        
    def optimize_performance(self):
        """Optimize GUI performance, especially on Windows"""
        # Reduce update frequency for better performance
        self.root.tk.call('tk', 'scaling', 1.0)
        
        # Set priority and process optimizations for Windows
        if platform.system() == "Windows":
            try:
                import psutil
                import os
                # Set normal priority instead of high priority
                p = psutil.Process(os.getpid())
                p.nice(psutil.NORMAL_PRIORITY_CLASS)
            except ImportError:
                pass  # psutil not available, continue without optimization
        
        # Optimize tkinter performance
        self.root.option_add('*tearOff', False)
        
    def setup_window(self):
        """Configure main window"""
        self.root.title("OpenTofu Lab Automation - GUI")
        self.root.geometry("900x800")
        
        # Hide console window on Windows if launched from .py file
        if platform.system() == "Windows":
            try:
                import ctypes
                ctypes.windll.user32.ShowWindow(ctypes.windll.kernel32.GetConsoleWindow(), 0)
            except:
                pass  # If it fails, continue without hiding console
        
        # Configure icon (if available)
        try:
            # Try to set window icon
            self.root.iconbitmap(default="icon.ico")
        except:
            pass
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=0)  # Config builder
        self.root.rowconfigure(1, weight=1)  # Deployment manager
        
        # Set minimum size
        self.root.minsize(800, 600)
        
        # Make window appear on top initially, then allow normal behavior
        self.root.lift()
        self.root.attributes('-topmost', True)
        self.root.after(1000, lambda: self.root.attributes('-topmost', False))
        
    def create_widgets(self):
        """Create main UI widgets"""
        # Header
        header_frame = ttk.Frame(self.root)
        header_frame.grid(row=0, column=0, sticky="ew", padx=10, pady=10)
        
        title_label = ttk.Label(header_frame, text=" OpenTofu Lab Automation", font=("Arial", 16, "bold"))
        title_label.pack(side="left")
        
        subtitle_label = ttk.Label(header_frame, text="Cross-Platform Infrastructure Lab Deployment", font=("Arial", 10))
        subtitle_label.pack(side="left", padx=(10, 0))
        
        # Platform info
        platform_info = f"Platform: {platform.system()} {platform.release()}"
        platform_label = ttk.Label(header_frame, text=platform_info, font=("Arial", 9), foreground="gray")
        platform_label.pack(side="right")
        
        # Main content frame
        main_frame = ttk.Frame(self.root)
        main_frame.grid(row=1, column=0, sticky="nsew", padx=10, pady=(0, 10))
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(1, weight=1)
        
        # Create config builder and deployment manager
        self.config_builder = ConfigBuilder(main_frame)
        self.deployment_manager = DeploymentManager(main_frame, self.config_builder)
        
        # Menu bar
        self.create_menu()
        
    def create_menu(self):
        """Create application menu"""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)
        
        # File menu
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="New Config", command=self.config_builder.reset_defaults)
        file_menu.add_command(label="Load Config...", command=self.config_builder.load_config)
        file_menu.add_command(label="Save Config...", command=self.config_builder.save_config)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)
        
        # Tools menu
        tools_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Tools", menu=tools_menu)
        tools_menu.add_command(label="Check Prerequisites", command=self.deployment_manager.check_prerequisites)
        tools_menu.add_command(label="Open Project Folder", command=self.open_project_folder)
        tools_menu.add_command(label="Open Config Folder", command=self.open_config_folder)
        
        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="About", command=self.show_about)
        help_menu.add_command(label="Documentation", command=self.open_documentation)
    
    def load_initial_config(self):
        """Load default configuration if available"""
        if DEFAULT_CONFIG.exists():
            try:
                with open(DEFAULT_CONFIG, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                
                # Populate fields
                for key, field in self.config_builder.fields.items():
                    if key in config:
                        field.delete(0, tk.END)
                        field.insert(0, str(configkey))
                        
            except Exception as e:
                print(f"Could not load default config: {e}")
    
    def open_project_folder(self):
        """Open project folder in file manager"""
        try:
            if platform.system() == "Windows":
                os.startfile(PROJECT_ROOT)
            elif platform.system() == "Darwin":  # macOS
                subprocess.run("open", PROJECT_ROOT)
            else:  # Linux and others
                subprocess.run("xdg-open", PROJECT_ROOT)
        except Exception as e:
            messagebox.showerror("Error", f"Could not open project folder:\n{str(e)}")
    
    def open_config_folder(self):
        """Open config folder in file manager"""
        try:
            if platform.system() == "Windows":
                os.startfile(CONFIGS_DIR)
            elif platform.system() == "Darwin":  # macOS
                subprocess.run("open", CONFIGS_DIR)
            else:  # Linux and others
                subprocess.run("xdg-open", CONFIGS_DIR)
        except Exception as e:
            messagebox.showerror("Error", f"Could not open config folder:\n{str(e)}")
    
    def open_documentation(self):
        """Open documentation in web browser"""
        import webbrowser
        try:
            readme_path = PROJECT_ROOT / "README.md"
            webbrowser.open(f"file://{readme_path}")
        except Exception as e:
            messagebox.showerror("Error", f"Could not open documentation:\n{str(e)}")
    
    def show_about(self):
        """Show about dialog"""
        about_text = """OpenTofu Lab Automation - GUI Interface

Version: 1.0.0
Platform: Cross-platform (Windows, Linux, macOS)

A comprehensive automation framework for deploying and managing 
OpenTofu (Terraform alternative) infrastructure labs.

Features:
• Configuration file builder and editor
• Real-time deployment progress monitoring  
• Cross-platform compatibility
• Integration with PowerShell automation
• Prerequisites checking and validation

© 2025 OpenTofu Lab Automation Project
Licensed under MIT License"""
        
        messagebox.showinfo("About OpenTofu Lab Automation", about_text)
    
    def run(self):
        """Start the GUI application"""
        try:
            self.root.mainloop()
        except KeyboardInterrupt:
            self.root.quit()
        finally:
            # Cleanup temporary files
            temp_config = PROJECT_ROOT / "temp-gui-config.json"
            if temp_config.exists():
                try:
                    temp_config.unlink()
                except:
                    pass

def main():
    """Main entry point"""
    # Check for tkinter availability
    try:
        import tkinter
    except ImportError:
        print("Error: tkinter is not available.")
        print("Please install tkinter:")
        print("  Ubuntu/Debian: sudo apt-get install python3-tk")
        print("  CentOS/RHEL: sudo yum install tkinter")
        print("  macOS: tkinter should be included with Python")
        print("  Windows: tkinter should be included with Python")
        return 1
    
    # Windows-specific optimizations
    if platform.system() == "Windows":
        try:
            # Try to reduce process priority for better system performance
            import ctypes
            import ctypes.wintypes
            
            # Set process to below normal priority
            BELOW_NORMAL_PRIORITY_CLASS = 0x00004000
            handle = ctypes.windll.kernel32.GetCurrentProcess()
            ctypes.windll.kernel32.SetPriorityClass(handle, BELOW_NORMAL_PRIORITY_CLASS)
        except Exception:
            pass  # Continue if optimization fails
    
    # Create and run application
    try:
        app = LabAutomationGUI()
        app.run()
        return 0
    except Exception as e:
        print(f"Error starting GUI: {e}")
        if platform.system() == "Windows":
            # Show error dialog on Windows
            try:
                import ctypes
                ctypes.windll.user32.MessageBoxW(0, f"Error starting GUI: {str(e)}", "OpenTofu Lab Automation", 0x10)
            except:
                pass
        return 1

if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Enhanced GUI Interface

Enhanced graphical interface with comprehensive configuration builder,
help system, and improved deployment management.

Features:
- Comprehensive configuration builder with help text
- Organized configuration sections 
- Validation and error checking
- Real-time deployment monitoring
- Cross-platform compatibility
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
try:
 from config_schema import ConfigSchema, ConfigField
except ImportError:
 # Fallback if config_schema is not available
 class ConfigSchema:
 def __init__(self):
 self.sections = {"General": []}
 def get_defaults(self):
 return {}
 def validate_config(self, config):
 return []

# Project constants - use proper working directory
WORK_DIR = get_working_directory()
PROJECT_ROOT = WORK_DIR
CONFIGS_DIR = PROJECT_ROOT / "configs" / "config_files"
DEFAULT_CONFIG = CONFIGS_DIR / "default-config.json"

class EnhancedConfigBuilder:
 """Enhanced configuration builder with comprehensive options and help"""
 
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
 """Create enhanced configuration builder UI"""
 # Create main notebook for sections
 self.notebook = ttk.Notebook(self.parent)
 self.notebook.grid(row=0, column=0, sticky="nsew", padx=10, pady=5)
 
 # Create tabs for each configuration section
 self.section_frames = {}
 for section_name, fields in self.config_schema.sections.items():
 self.create_section_tab(section_name, fields)
 
 # Control buttons frame
 control_frame = ttk.Frame(self.parent)
 control_frame.grid(row=1, column=0, sticky="ew", padx=10, pady=5)
 
 ttk.Button(control_frame, text="Load Config", command=self.load_config).pack(side="left", padx=5)
 ttk.Button(control_frame, text="Save Config", command=self.save_config).pack(side="left", padx=5)
 ttk.Button(control_frame, text="Reset to Defaults", command=self.load_defaults).pack(side="left", padx=5)
 ttk.Button(control_frame, text="Validate Config", command=self.validate_config).pack(side="left", padx=5)
 
 # Configure grid weights
 self.parent.grid_rowconfigure(0, weight=1)
 self.parent.grid_columnconfigure(0, weight=1)
 
 def create_section_tab(self, section_name: str, fields: list):
 """Create a tab for a configuration section"""
 # Create frame for this section
 frame = ttk.Frame(self.notebook)
 self.notebook.add(frame, text=section_name)
 self.section_frames[section_name] = frame
 
 # Create scrollable area
 canvas = tk.Canvas(frame)
 scrollbar = ttk.Scrollbar(frame, orient="vertical", command=canvas.yview)
 scrollable_frame = ttk.Frame(canvas)
 
 scrollable_frame.bind(
 "<Configure>",
 lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
 )
 
 canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
 canvas.configure(yscrollcommand=scrollbar.set)
 
 canvas.pack(side="left", fill="both", expand=True)
 scrollbar.pack(side="right", fill="y")
 
 # Add fields to scrollable frame
 row = 0
 for field in fields:
 # Skip platform-specific fields if not applicable
 if field.platform_specific:
 current_platform = platform.system().lower()
 if current_platform not in field.platform_specific:
 continue
 
 self.create_field_widget(scrollable_frame, field, row)
 row += 1
 
 # Configure column weights
 scrollable_frame.grid_columnconfigure(1, weight=1)
 
 def create_field_widget(self, parent: ttk.Frame, field: ConfigField, row: int):
 """Create widget for a configuration field"""
 # Label with required indicator
 label_text = field.display_name
 if field.required:
 label_text += " *"
 
 label = ttk.Label(parent, text=label_text)
 label.grid(row=row, column=0, sticky="nw", padx=(5, 10), pady=5)
 
 # Create appropriate widget based on field type
 widget = None
 
 if field.field_type == "bool":
 widget = ttk.Checkbutton(parent)
 widget.grid(row=row, column=1, sticky="w", pady=5)
 
 elif field.field_type == "choice":
 widget = ttk.Combobox(parent, values=field.choices, state="readonly", width=20)
 widget.grid(row=row, column=1, sticky="w", pady=5)
 
 elif field.field_type == "path":
 # Path with browse button
 path_frame = ttk.Frame(parent)
 path_frame.grid(row=row, column=1, sticky="ew", pady=5)
 
 widget = ttk.Entry(path_frame, width=50)
 widget.pack(side="left", fill="x", expand=True)
 
 browse_btn = ttk.Button(path_frame, text="Browse", 
 command=lambda f=field: self.browse_path(f))
 browse_btn.pack(side="right", padx=(5, 0))
 
 path_frame.grid_columnconfigure(0, weight=1)
 
 else: # text, url, number
 width = 60 if field.field_type == "url" else 30
 widget = ttk.Entry(parent, width=width)
 widget.grid(row=row, column=1, sticky="ew", pady=5)
 
 # Help text label
 help_label = ttk.Label(parent, text=field.help_text, font=("TkDefaultFont", 8), 
 foreground="gray", wraplength=400)
 help_label.grid(row=row, column=2, sticky="nw", padx=(10, 5), pady=5)
 
 # Store widget references
 self.field_widgets[field.name] = widget
 self.help_labels[field.name] = help_label
 
 def browse_path(self, field: ConfigField):
 """Browse for a directory path"""
 directory = filedialog.askdirectory(title=f"Select {field.display_name}")
 if directory:
 widget = self.field_widgets[field.name]
 widget.delete(0, tk.END)
 widget.insert(0, directory)
 
 def load_defaults(self):
 """Load default values into all fields"""
 defaults = self.config_schema.get_defaults()
 
 for field_name, widget in self.field_widgets.items():
 field = self.config_schema.get_field_by_name(field_name)
 if not field:
 continue
 
 default_value = defaults.get(field_name, field.default_value)
 
 if field.field_type == "bool":
 if hasattr(widget, 'state'):
 widget.state(['!alternate'])
 if default_value:
 widget.state(['selected'])
 else:
 widget.state(['!selected'])
 else:
 widget.delete(0, tk.END)
 widget.insert(0, str(default_value))
 
 messagebox.showinfo("Defaults Loaded", "All fields have been reset to their recommended default values.")
 
 def get_config(self) -> Dict[str, Any]:
 """Get current configuration from UI fields"""
 config = {}
 
 for field_name, widget in self.field_widgets.items():
 field = self.config_schema.get_field_by_name(field_name)
 if not field:
 continue
 
 if field.field_type == "bool":
 # Check if widget has instate method (Checkbutton)
 if hasattr(widget, 'instate'):
 config[field_name] = widget.instate(['selected'])
 else:
 config[field_name] = field.default_value
 else:
 value = widget.get().strip()
 if value: # Only include non-empty values
 # Convert to appropriate type
 if field.field_type == "number":
 try:
 config[field_name] = float(value) if '.' in value else int(value)
 except ValueError:
 config[field_name] = value # Keep as string if conversion fails
 else:
 config[field_name] = value
 
 return config
 
 def validate_config(self):
 """Validate current configuration"""
 config = self.get_config()
 errors = self.config_schema.validate_config(config)
 
 if errors:
 error_message = "Configuration validation errors:\n\n" + "\n".join(f"• {error}" for error in errors)
 messagebox.showerror("Validation Errors", error_message)
 else:
 messagebox.showinfo("Validation Success", "Configuration is valid!")
 
 return len(errors) == 0
 
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
 
 # Load values into fields
 for field_name, widget in self.field_widgets.items():
 field = self.config_schema.get_field_by_name(field_name)
 if not field or field_name not in config:
 continue
 
 value = config[field_name]
 
 if field.field_type == "bool":
 if hasattr(widget, 'state'):
 widget.state(['!alternate'])
 if value:
 widget.state(['selected'])
 else:
 widget.state(['!selected'])
 else:
 widget.delete(0, tk.END)
 widget.insert(0, str(value))
 
 self.config_file = file_path
 messagebox.showinfo("Success", f"Configuration loaded from {Path(file_path).name}")
 
 except Exception as e:
 messagebox.showerror("Error", f"Failed to load configuration:\n{str(e)}")
 
 def save_config(self):
 """Save current configuration to file"""
 if not self.validate_config():
 if not messagebox.askyesno("Validation Failed", 
 "Configuration has validation errors. Save anyway?"):
 return
 
 config = self.get_config()
 
 if not config:
 messagebox.showwarning("Warning", "No configuration to save!")
 return
 
 file_path = filedialog.asksaveasfilename(
 title="Save Configuration File",
 filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
 defaultextension=".json",
 initialdir=CONFIGS_DIR,
 initialfile="my-lab-config.json"
 )
 
 if file_path:
 try:
 # Ensure directory exists
 Path(file_path).parent.mkdir(parents=True, exist_ok=True)
 
 with open(file_path, 'w', encoding='utf-8') as f:
 json.dump(config, f, indent=2, sort_keys=True)
 
 self.config_file = file_path
 messagebox.showinfo("Success", f"Configuration saved to {Path(file_path).name}")
 
 except Exception as e:
 messagebox.showerror("Error", f"Failed to save configuration:\n{str(e)}")

class DeploymentManager:
 """Enhanced deployment manager with better error handling"""
 
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
 self.frame.grid(row=0, column=1, sticky="nsew", padx=10, pady=5)
 
 # Control buttons
 button_frame = ttk.Frame(self.frame)
 button_frame.grid(row=0, column=0, sticky="ew", pady=(0, 10))
 
 self.deploy_btn = ttk.Button(button_frame, text=" Deploy Lab", command=self.start_deployment)
 self.deploy_btn.pack(side="left", padx=5)
 
 self.quick_btn = ttk.Button(button_frame, text=" Quick Deploy", command=self.quick_deployment)
 self.quick_btn.pack(side="left", padx=5)
 
 self.check_btn = ttk.Button(button_frame, text=" Check Prerequisites", command=self.check_prerequisites)
 self.check_btn.pack(side="left", padx=5)
 
 self.stop_btn = ttk.Button(button_frame, text="⏹ Stop", command=self.stop_deployment, state="disabled")
 self.stop_btn.pack(side="left", padx=5)
 
 # Status and progress
 status_frame = ttk.Frame(self.frame)
 status_frame.grid(row=1, column=0, sticky="ew", pady=5)
 
 ttk.Label(status_frame, text="Status:").pack(side="left")
 self.status_var = tk.StringVar(value="Ready")
 self.status_label = ttk.Label(status_frame, textvariable=self.status_var, foreground="blue")
 self.status_label.pack(side="left", padx=(10, 0))
 
 self.progress = ttk.Progressbar(self.frame, mode="indeterminate")
 self.progress.grid(row=2, column=0, sticky="ew", pady=5)
 
 # Working directory display
 workdir_frame = ttk.Frame(self.frame)
 workdir_frame.grid(row=3, column=0, sticky="ew", pady=5)
 
 ttk.Label(workdir_frame, text="Working Directory:").pack(side="left")
 ttk.Label(workdir_frame, text=str(WORK_DIR), font=("TkDefaultFont", 8), foreground="gray").pack(side="left", padx=(10, 0))
 
 # Output display
 ttk.Label(self.frame, text="Deployment Output:").grid(row=4, column=0, sticky="w", pady=(10, 5))
 
 self.output_text = scrolledtext.ScrolledText(self.frame, height=20, width=80, font=("Consolas", 9))
 self.output_text.grid(row=5, column=0, sticky="nsew", pady=5)
 
 # Configure grid weights
 self.frame.grid_columnconfigure(0, weight=1)
 self.frame.grid_rowconfigure(5, weight=1)
 
 def log_output(self, message: str, level: str = "INFO"):
 """Add message to output display with timestamp and level"""
 timestamp = time.strftime('%H:%M:%S')
 formatted_message = f"[{timestamp}] {level}: {message}\n"
 
 self.output_text.insert(tk.END, formatted_message)
 self.output_text.see(tk.END)
 
 # Color coding for different levels
 if level == "ERROR":
 self.output_text.tag_add("error", f"{self.output_text.index(tk.END)}-1l linestart", 
 f"{self.output_text.index(tk.END)}-1l lineend")
 self.output_text.tag_config("error", foreground="red")
 elif level == "WARNING":
 self.output_text.tag_add("warning", f"{self.output_text.index(tk.END)}-1l linestart", 
 f"{self.output_text.index(tk.END)}-1l lineend")
 self.output_text.tag_config("warning", foreground="orange")
 
 def check_prerequisites(self):
 """Check system prerequisites non-interactively"""
 self.log_output("Checking system prerequisites...")
 self.status_var.set("Checking prerequisites...")
 self.progress.start()
 
 def check_thread():
 try:
 # Change to working directory
 os.chdir(WORK_DIR)
 
 # Check PowerShell
 self.log_output("Checking PowerShell installation...")
 try:
 result = subprocess.run(['pwsh', '-Command', '$PSVersionTable.PSVersion.Major'], 
 capture_output=True, text=True, timeout=10)
 if result.returncode == 0:
 version = result.stdout.strip()
 self.log_output(f" PowerShell 7+ found (version {version})")
 else:
 self.log_output(" PowerShell 7+ not found", "WARNING")
 except Exception as e:
 self.log_output(f" PowerShell check failed: {e}", "ERROR")
 
 # Check Git
 self.log_output("Checking Git installation...")
 try:
 result = subprocess.run(['git', '--version'], capture_output=True, text=True, timeout=5)
 if result.returncode == 0:
 version = result.stdout.strip()
 self.log_output(f" Git found: {version}")
 else:
 self.log_output(" Git not found", "WARNING")
 except Exception as e:
 self.log_output(f" Git check failed: {e}", "ERROR")
 
 # Check Python
 self.log_output("Checking Python installation...")
 try:
 result = subprocess.run([sys.executable, '--version'], capture_output=True, text=True, timeout=5)
 if result.returncode == 0:
 version = result.stdout.strip()
 self.log_output(f" Python found: {version}")
 else:
 self.log_output(" Python check failed", "WARNING")
 except Exception as e:
 self.log_output(f" Python check failed: {e}", "ERROR")
 
 # Check working directory
 self.log_output(f"Working directory: {WORK_DIR}")
 if WORK_DIR.exists():
 self.log_output(" Working directory exists")
 else:
 self.log_output("Creating working directory...")
 WORK_DIR.mkdir(parents=True, exist_ok=True)
 self.log_output(" Working directory created")
 
 self.log_output("Prerequisites check completed.")
 self.status_var.set("Prerequisites check completed")
 
 except Exception as e:
 self.log_output(f"Prerequisites check failed: {e}", "ERROR")
 self.status_var.set("Prerequisites check failed")
 finally:
 self.progress.stop()
 
 threading.Thread(target=check_thread, daemon=True).start()
 
 def start_deployment(self):
 """Start full deployment with current configuration"""
 if not self.config_builder.validate_config():
 messagebox.showerror("Configuration Error", 
 "Please fix configuration errors before deploying.")
 return
 
 config = self.config_builder.get_config()
 
 # Save config to temporary file
 temp_config = WORK_DIR / "temp-config.json"
 try:
 with open(temp_config, 'w', encoding='utf-8') as f:
 json.dump(config, f, indent=2)
 except Exception as e:
 messagebox.showerror("Error", f"Failed to save temporary config: {e}")
 return
 
 self.deploy_with_config(str(temp_config))
 
 def quick_deployment(self):
 """Quick deployment with defaults"""
 self.deploy_with_config(None)
 
 def deploy_with_config(self, config_path: Optional[str]):
 """Deploy with specified config file"""
 self.log_output("Starting deployment...")
 self.status_var.set("Deploying...")
 self.progress.start()
 
 self.deploy_btn.config(state="disabled")
 self.quick_btn.config(state="disabled")
 self.check_btn.config(state="disabled")
 self.stop_btn.config(state="normal")
 
 def deploy_thread():
 try:
 # Change to working directory
 os.chdir(WORK_DIR)
 self.log_output(f"Working directory: {WORK_DIR}")
 
 # Build command
 deploy_script = Path(__file__).parent / "deploy.py"
 cmd = [sys.executable, str(deploy_script), "--non-interactive"]
 
 if config_path:
 cmd.extend(["--config", config_path])
 else:
 cmd.append("--quick")
 
 self.log_output(f"Running: {' '.join(cmd)}")
 
 # Run deployment
 self.process = subprocess.Popen(
 cmd,
 stdout=subprocess.PIPE,
 stderr=subprocess.STDOUT,
 text=True,
 bufsize=1,
 universal_newlines=True,
 cwd=str(WORK_DIR),
 encoding='utf-8',
 errors='replace'
 )
 
 # Read output in real-time
 for line in iter(self.process.stdout.readline, ''):
 if line:
 self.output_queue.put(("output", line.rstrip()))
 
 self.process.wait()
 
 if self.process.returncode == 0:
 self.output_queue.put(("status", "Deployment completed successfully"))
 self.output_queue.put(("log", " Deployment completed successfully"))
 else:
 self.output_queue.put(("status", "Deployment failed"))
 self.output_queue.put(("log_error", f" Deployment failed with exit code {self.process.returncode}"))
 
 except Exception as e:
 self.output_queue.put(("log_error", f"Deployment error: {e}"))
 self.output_queue.put(("status", "Deployment error"))
 finally:
 self.output_queue.put(("finished", None))
 
 # Start deployment thread
 threading.Thread(target=deploy_thread, daemon=True).start()
 
 # Start output monitor
 self.monitor_output()
 
 def monitor_output(self):
 """Monitor deployment output queue"""
 try:
 while True:
 try:
 msg_type, content = self.output_queue.get_nowait()
 
 if msg_type == "output":
 self.output_text.insert(tk.END, content + "\n")
 self.output_text.see(tk.END)
 elif msg_type == "log":
 self.log_output(content)
 elif msg_type == "log_error":
 self.log_output(content, "ERROR")
 elif msg_type == "status":
 self.status_var.set(content)
 elif msg_type == "finished":
 self.deployment_finished()
 break
 
 except queue.Empty:
 break
 except Exception as e:
 self.log_output(f"Output monitor error: {e}", "ERROR")
 
 # Schedule next check
 self.parent.after(100, self.monitor_output)
 
 def stop_deployment(self):
 """Stop running deployment"""
 if self.process:
 try:
 self.process.terminate()
 self.log_output("Deployment stopped by user", "WARNING")
 self.status_var.set("Deployment stopped")
 except Exception as e:
 self.log_output(f"Error stopping deployment: {e}", "ERROR")
 
 self.deployment_finished()
 
 def deployment_finished(self):
 """Clean up after deployment finishes"""
 self.progress.stop()
 self.deploy_btn.config(state="normal")
 self.quick_btn.config(state="normal") 
 self.check_btn.config(state="normal")
 self.stop_btn.config(state="disabled")
 self.process = None

class EnhancedLabGUI:
 """Enhanced main GUI application"""
 
 def __init__(self):
 self.root = tk.Tk()
 self.setup_window()
 self.create_widgets()
 
 def setup_window(self):
 """Setup main window properties"""
 self.root.title("OpenTofu Lab Automation - Enhanced Configuration & Deployment")
 self.root.geometry("1400x900")
 
 # Set window icon if available
 try:
 # Try to set an icon (you can add an icon file to the project)
 pass
 except:
 pass
 
 # Configure grid weights
 self.root.grid_rowconfigure(0, weight=1)
 self.root.grid_columnconfigure(0, weight=1)
 self.root.grid_columnconfigure(1, weight=1)
 
 def create_widgets(self):
 """Create main application widgets"""
 # Main container
 main_frame = ttk.Frame(self.root)
 main_frame.grid(row=0, column=0, columnspan=2, sticky="nsew", padx=10, pady=10)
 main_frame.grid_rowconfigure(0, weight=1)
 main_frame.grid_columnconfigure(0, weight=2) # Config builder gets more space
 main_frame.grid_columnconfigure(1, weight=1) # Deployment manager
 
 # Configuration builder (left side)
 config_frame = ttk.Frame(main_frame)
 config_frame.grid(row=0, column=0, sticky="nsew", padx=(0, 5))
 config_frame.grid_rowconfigure(0, weight=1)
 config_frame.grid_columnconfigure(0, weight=1)
 
 self.config_builder = EnhancedConfigBuilder(config_frame)
 
 # Deployment manager (right side)
 deploy_frame = ttk.Frame(main_frame)
 deploy_frame.grid(row=0, column=1, sticky="nsew", padx=(5, 0))
 deploy_frame.grid_rowconfigure(0, weight=1)
 deploy_frame.grid_columnconfigure(0, weight=1)
 
 self.deployment_manager = DeploymentManager(deploy_frame, self.config_builder)
 
 # Status bar
 self.status_bar = ttk.Label(self.root, text=f"Working Directory: {WORK_DIR}", relief="sunken")
 self.status_bar.grid(row=1, column=0, columnspan=2, sticky="ew")
 
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
 print("Starting OpenTofu Lab Automation GUI...")
 print(f"Working directory: {WORK_DIR}")
 
 # Ensure working directory and configs exist
 CONFIGS_DIR.mkdir(parents=True, exist_ok=True)
 
 app = EnhancedLabGUI()
 app.run()

if __name__ == "__main__":
 main()

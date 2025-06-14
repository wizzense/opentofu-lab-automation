#!/usr/bin/env python3
"""
GitHub Actions Workflow Status Dashboard
Provides a comprehensive view of all workflow statuses and recent runs.
"""

import os
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

def run_command(cmd, capture_output=True):
 """Run a shell command and return the result."""
 try:
 result = subprocess.run(cmd, shell=True, capture_output=capture_output, text=True)
 return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
 except Exception as e:
 return False, "", str(e)

def get_workflow_status():
 """Get the status of all workflows using GitHub CLI."""
 print(" Fetching workflow status...")
 
 # Get workflow runs
 success, output, error = run_command("gh run list --limit 10 --json status,conclusion,workflowName,createdAt,url")
 
 if not success:
 print(f"[FAIL] Failed to fetch workflow status: {error}")
 return []
 
 try:
 runs = json.loads(output)
 return runs
 except json.JSONDecodeError as e:
 print(f"[FAIL] Failed to parse workflow data: {e}")
 return []

def analyze_workflow_files():
 """Analyze all workflow files and their configurations."""
 workflows_dir = Path('.github/workflows')
 
 if not workflows_dir.exists():
 return []
 
 workflows = []
 
 for workflow_file in workflows_dir.glob('*.yml'):
 try:
 with open(workflow_file, 'r') as f:
 content = f.read()
 
 # Basic analysis
 analysis = {
 'name': workflow_file.name,
 'path': str(workflow_file),
 'size': len(content),
 'lines': len(content.splitlines()),
 'has_matrix': 'matrix:' in content,
 'has_cache': 'cache@' in content,
 'has_artifacts': 'upload-artifact@' in content,
 'platforms': []
 }
 
 # Extract platforms
 if 'windows-latest' in content:
 analysis['platforms'].append('Windows')
 if 'ubuntu-latest' in content:
 analysis['platforms'].append('Linux')
 if 'macos-latest' in content:
 analysis['platforms'].append('macOS')
 
 workflows.append(analysis)
 
 except Exception as e:
 print(f"[WARN] Failed to analyze {workflow_file}: {e}")
 
 return workflows

def generate_dashboard():
 """Generate a comprehensive workflow dashboard."""
 print(" Generating Workflow Dashboard")
 print("=" * 50)
 
 # Get recent runs
 runs = get_workflow_status()
 
 # Analyze workflow files
 workflows = analyze_workflow_files()
 
 # Group runs by workflow
 workflow_runs = {}
 for run in runs:
 workflow_name = run['workflowName']
 if workflow_name not in workflow_runs:
 workflow_runs[workflow_name] = []
 workflow_runs[workflow_name].append(run)
 
 # Display workflow summary
 print(f"\n Workflow Summary ({len(workflows)} workflows)")
 print("-" * 30)
 
 for workflow in sorted(workflows, key=lambda x: x['name']):
 name = workflow['name'].replace('.yml', '')
 platforms = ', '.join(workflow['platforms']) if workflow['platforms'] else 'N/A'
 features = []
 
 if workflow['has_matrix']:
 features.append('Matrix')
 if workflow['has_cache']:
 features.append('Cache')
 if workflow['has_artifacts']:
 features.append('Artifacts')
 
 features_str = ', '.join(features) if features else 'Basic'
 
 print(f"• {name:<25} | {platforms:<20} | {features_str}")
 
 # Display recent runs
 if runs:
 print(f"\n� Recent Workflow Runs ({len(runs)} shown)")
 print("-" * 40)
 
 for run in runs[:10]:
 workflow = run['workflowName']
 status = run['status']
 conclusion = run.get('conclusion', 'N/A')
 created_at = run['createdAt']
 
 # Parse timestamp
 try:
 dt = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
 time_str = dt.strftime('%m/%d %H:%M')
 except:
 time_str = created_at[:16]
 
 # Status emoji
 if conclusion == 'success':
 emoji = '[PASS]'
 elif conclusion == 'failure':
 emoji = '[FAIL]'
 elif status == 'in_progress':
 emoji = '�'
 else:
 emoji = '⚪'
 
 print(f"{emoji} {workflow:<25} | {status:<12} | {time_str}")
 
 # Display workflow health
 print(f"\n� Workflow Health Analysis")
 print("-" * 30)
 
 total_workflows = len(workflows)
 workflows_with_cache = sum(1 for w in workflows if w['has_cache'])
 workflows_with_artifacts = sum(1 for w in workflows if w['has_artifacts'])
 workflows_with_matrix = sum(1 for w in workflows if w['has_matrix'])
 
 print(f"Total workflows: {total_workflows}")
 print(f"With caching: {workflows_with_cache} ({workflows_with_cache/total_workflows*100:.1f}%)")
 print(f"With artifacts: {workflows_with_artifacts} ({workflows_with_artifacts/total_workflows*100:.1f}%)")
 print(f"With matrix builds: {workflows_with_matrix} ({workflows_with_matrix/total_workflows*100:.1f}%)")
 
 # Check for common issues
 issues = []
 
 for workflow in workflows:
 if workflow['lines'] > 200:
 issues.append(f"[WARN] {workflow['name']} is very long ({workflow['lines']} lines)")
 
 if not workflow['platforms']:
 issues.append(f"[WARN] {workflow['name']} has no platform specified")
 
 if issues:
 print(f"\n[WARN] Potential Issues ({len(issues)})")
 print("-" * 20)
 for issue in issues:
 print(issue)
 
 # Generate recommendations
 recommendations = []
 
 if workflows_with_cache < total_workflows * 0.7:
 recommendations.append(" Consider adding caching to more workflows to improve performance")
 
 if workflows_with_artifacts < total_workflows * 0.5:
 recommendations.append(" Consider adding artifact uploads for better debugging")
 
 long_workflows = [w for w in workflows if w['lines'] > 150]
 if long_workflows:
 recommendations.append(f" Consider splitting long workflows ({len(long_workflows)} found)")
 
 if recommendations:
 print(f"\n Recommendations")
 print("-" * 15)
 for rec in recommendations:
 print(rec)
 
 # Save detailed report
 report = {
 'timestamp': datetime.now().isoformat(),
 'workflows': workflows,
 'recent_runs': runs,
 'summary': {
 'total_workflows': total_workflows,
 'with_cache': workflows_with_cache,
 'with_artifacts': workflows_with_artifacts,
 'with_matrix': workflows_with_matrix,
 'issues': issues,
 'recommendations': recommendations
 }
 }
 
 with open('workflow-dashboard-report.json', 'w') as f:
 json.dump(report, f, indent=2)
 
 print(f"\n� Detailed report saved to: workflow-dashboard-report.json")

def main():
 """Main execution function."""
 if not Path('.github').exists():
 print("[FAIL] Not in a GitHub repository")
 sys.exit(1)
 
 # Check if GitHub CLI is available
 success, _, _ = run_command("gh --version")
 if not success:
 print("[WARN] GitHub CLI not available - some features will be limited")
 
 generate_dashboard()
 print("\n✨ Dashboard generation complete!")

if __name__ == "__main__":
 main()

#!/usr/bin/env python3
"""
Workflow validation and optimization script.
Validates GitHub Actions workflows and suggests improvements.
"""

import os
import sys
import yaml
import json
from pathlib import Path

def validate_workflow_syntax(workflow_path):
    """Validate YAML syntax of a workflow file."""
    try:
        with open(workflow_path, 'r') as f:
            yaml.safe_load(f)
        return True, None
    except yaml.YAMLError as e:
        return False, str(e)

def analyze_workflow(workflow_path):
    """Analyze a workflow for common issues."""
    issues = 
    recommendations = 

    try:
        with open(workflow_path, 'r') as f:
            workflow = yaml.safe_load(f)

            # Check for common issues
            triggers = workflow.get('on', workflow.get(True, None))  # Handle 'on' being parsed as True
            if not triggers:
                issues.append("Missing 'on' trigger configuration")

            if 'jobs' not in workflow:
                issues.append("Missing 'jobs' configuration")

            # Check for optimization opportunities
            jobs = workflow.get('jobs', {})

            for job_name, job_config in jobs.items():
                steps = job_config.get('steps', )

                # Check for repeated setup steps
                setup_steps = step for step in steps if 'checkout@' in str(step)
                if len(setup_steps) > 1:
                    recommendations.append(f"Job '{job_name}' has multiple checkout steps")

                # Check for missing error handling
                shell_steps = step for step in steps if step.get('shell') == 'pwsh'
                for step in shell_steps:
                    run_content = step.get('run', '')
                    if 'ErrorActionPreference' not in run_content and 'try' not in run_content:
                        recommendations.append(f"PowerShell step in '{job_name}' could benefit from error handling")

            return issues, recommendations

    except Exception as e:
        return f"Failed to analyze workflow: {e}", 

def validate_all_workflows():
    """Validate all workflow files in the repository."""
    workflows_dir = Path('.github/workflows')

    if not workflows_dir.exists():
        print("FAIL No .github/workflows directory found")
        return False

    workflow_files = list(workflows_dir.glob('*.yml'))
    if not workflow_files:
        print("FAIL No workflow files found")
        return False

    print(f" Found {len(workflow_files)} workflow files")

    all_valid = True

    for workflow_file in workflow_files:
        print(f"\n Validating {workflow_file.name}")

        # Syntax validation
        is_valid, error = validate_workflow_syntax(workflow_file)
        if not is_valid:
            print(f" FAIL Syntax error: {error}")
            all_valid = False
            continue

        print(" PASS Valid YAML syntax")

        # Analysis
        issues, recommendations = analyze_workflow(workflow_file)

        if issues:
            print(" WARN Issues found:")
            for issue in issues:
                print(f" - {issue}")
            all_valid = False

        if recommendations:
            print(" Recommendations:")
            for rec in recommendations:
                print(f" - {rec}")

    return all_valid

def check_workflow_dependencies():
    """Check for missing dependencies and tools."""
    print("\n Checking workflow dependencies...")

    dependencies = {
        'PowerShell': 'pwsh', 'powershell',
        'Python': 'python3', 'python',
        'Node.js': 'node', 'npm',
        'Git': 'git',
    }

    missing = 

    for dep_name, commands in dependencies.items():
        found = False
        for cmd in commands:
            if os.system(f"which {cmd} >/dev/null 2>&1") == 0:
                print(f" PASS {dep_name} ({cmd}) available")
                found = True
                break

        if not found:
            missing.append(dep_name)
            print(f" FAIL {dep_name} not found")

    return len(missing) == 0

def generate_optimization_report():
    """Generate a comprehensive optimization report."""
    print("\n Generating optimization report...")

    report = {
        'timestamp': str(Path('.').resolve()),
        'workflow_validation': validate_all_workflows(),
        'dependencies_check': check_workflow_dependencies(),
        'optimizations': 
    }

    # Save report
    with open('workflow-optimization-report.json', 'w') as f:
        json.dump(report, f, indent=2)

    print(f"� Report saved to: workflow-optimization-report.json")

    return report

def main():
    """Main execution function."""
    print(" GitHub Actions Workflow Validator & Optimizer")
    print("=" * 50)

    if not Path('.github').exists():
        print("FAIL Not in a GitHub repository (no .github directory)")
        sys.exit(1)

    report = generate_optimization_report()

    if report'workflow_validation' and report'dependencies_check':
        print("\nPASS All validations passed!")
        sys.exit(0)
    else:
        print("\nFAIL Some validations failed. Check the report for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()

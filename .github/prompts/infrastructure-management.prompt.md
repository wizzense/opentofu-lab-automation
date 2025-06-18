---
mode: 'agent'
tools: ['codebase', 'run_terminal']
description: 'Manage infrastructure deployment and operations'
---

Manage infrastructure deployment and operations for the OpenTofu Lab Automation project.

## Requirements
Ask for the specific infrastructure task or environment if not provided in the prompt.

The infrastructure management should include:

### Infrastructure Planning
- Design infrastructure architecture and components
- Plan resource requirements and capacity
- Define environment-specific configurations
- Plan network topology and security groups
- Design backup and disaster recovery strategies
- Plan scaling and performance optimization

### OpenTofu/Terraform Operations
- Initialize and configure OpenTofu/Terraform workspaces
- Plan and validate infrastructure changes
- Apply infrastructure configurations safely
- Manage state files and remote backends
- Implement proper resource tagging and organization
- Handle infrastructure drift and reconciliation

### Environment Management
- Manage multiple environments (dev, test, prod)
- Implement environment-specific variable management
- Configure environment promotion pipelines
- Manage environment isolation and security
- Implement environment monitoring and alerting
- Handle environment lifecycle management

### Security and Compliance
- Implement security best practices and policies
- Configure network security and access controls
- Manage secrets and sensitive configuration data
- Implement compliance monitoring and reporting
- Configure audit logging and security monitoring
- Handle security incident response procedures

### Monitoring and Observability
- Set up infrastructure monitoring and alerting
- Configure performance metrics and dashboards
- Implement log aggregation and analysis
- Set up health checks and status monitoring
- Configure capacity planning and resource optimization
- Implement cost monitoring and optimization

### Backup and Recovery
- Implement automated backup procedures
- Configure disaster recovery and business continuity
- Test backup and recovery procedures regularly
- Manage backup retention and archival policies
- Implement point-in-time recovery capabilities
- Document recovery procedures and runbooks

### Scaling and Performance
- Monitor resource utilization and performance
- Implement auto-scaling policies and procedures
- Optimize resource allocation and cost
- Handle capacity planning and growth projections
- Implement performance tuning and optimization
- Monitor and optimize network performance

### Maintenance and Updates
- Plan and execute infrastructure maintenance
- Manage system updates and security patches
- Handle infrastructure migrations and upgrades
- Implement change management procedures
- Configure maintenance windows and notifications
- Document maintenance procedures and runbooks

Follow all standards from the [copilot instructions](../.github/copilot-instructions.md) and ensure comprehensive documentation of all infrastructure configurations and procedures.

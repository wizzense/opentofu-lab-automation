# Hyper-V VM Module

This module provisions a Hyper-V virtual machine and its associated VHD.  It is
intended to replace the repetitive VM resource blocks in the root configuration
with a single reusable component.

## Required Variables
- `vm_count` - number of VMs to create
- `vm_name_prefix` - prefix used for VM names and VHD files
- `hyperv_vm_path` - base path on the Hyper-V host for storing VHDs
- `vhd_size_bytes` - size of the VHD to create
- `iso_path` - installation media attached as a DVD drive
- `switch_name` - name of the Hyper-V virtual switch for networking
- `switch_dependency` - resource to depend on for switch creation
- `memory_startup_bytes`, `memory_maximum_bytes`, `memory_minimum_bytes` - memory settings
- `processor_count` - number of virtual processors


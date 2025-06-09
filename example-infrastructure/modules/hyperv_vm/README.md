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

## Example Usage

The module requires the `hyperv` provider.  A minimal provider configuration
looks like the following:

```hcl
terraform {
  required_providers {
    hyperv = {
      source = "taliesins/hyperv"
    }
  }
}

provider "hyperv" {
  host     = var.hyperv_host_name
  user     = var.hyperv_user
  password = var.hyperv_password
  https    = true
  insecure = true
}
```

After the provider is configured you can call the module from a Terraform
configuration:

```hcl
module "demo_vm" {
  source               = "./modules/hyperv_vm"
  vm_count             = 1
  vm_name_prefix       = "demo"
  hyperv_vm_path       = "D:/VMs/demo"
  vhd_size_bytes       = 50_000_000_000
  iso_path             = var.demo_iso_path
  switch_name          = hyperv_network_switch.wan.name
  switch_dependency    = hyperv_network_switch.wan
  memory_startup_bytes = 2147483648
  memory_maximum_bytes = 4294967296
  memory_minimum_bytes = 536870912
  processor_count      = 2
}
```

### Expected Outputs

The module does not define explicit outputs but you can reference the created
resources directly.  For example, to obtain the IP address of the first VM:

```hcl
output "vm_ip" {
  value = module.demo_vm.hyperv_machine_instance.this[0].ip_addresses
}
```


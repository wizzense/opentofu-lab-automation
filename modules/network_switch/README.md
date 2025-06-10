# Network Switch Module

This module creates a Hyper-V virtual switch. It wraps the `hyperv_network_switch` resource so the switch can be reused by other modules.

## Provider Requirements

The module depends on the `hyperv` provider from the `taliesins` namespace. Include the following in your configuration:

```hcl
terraform {
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = ">=1.2.1"
    }
  }
}
```

## Inputs
- `name` - name of the switch
- `net_adapter_names` - list of adapters
- `allow_management_os` - whether to allow management OS (default `true`)
- `switch_type` - switch type (default `External`)

## Outputs
- `switch_name` - the name of the created switch
- `switch_resource` - the underlying resource

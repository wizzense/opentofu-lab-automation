This repository contains example OpenTofu configurations for deploying a small
Hyper-V lab.  The configuration now uses a reusable module to create virtual
machines so that additional operating systems can be added easily.

To use these configurations clone the repo and run the usual OpenTofu
workflow:

```
tofu init
tofu validate
tofu plan
tofu apply
```

## Customizing variables

Default values for network adapter names, ISO locations and VM counts are
defined in `variables.tf`.  Create a `terraform.tfvars` file or pass `-var`
arguments to override them.  Example `terraform.tfvars`:

```hcl
wan_switch_name   = "lab"
wan_adapter_names = ["Ethernet 2"]
windows_11_vm_count = 2
```

If you need to reset your working copy run:

```
git reset --hard
git clean -fd
git pull
```

## Automated testing

The [test.yml](../.github/workflows/test.yml) workflow installs OpenTofu and
executes `tofu init` and `tofu validate` in this directory. It runs whenever you
push changes or open a pull request, ensuring the examples remain valid.


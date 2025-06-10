variable "lab_config_path" {
  type    = string
  default = "../../templates/lab_config.sample.yaml"
}

locals {
  lab = yamldecode(file(var.lab_config_path))
}

module "switch" {
  source            = "../../modules/network_switch"
  name              = local.lab.switch.name
  net_adapter_names = local.lab.switch.net_adapter_names
}

module "vm" {
  source              = "../../modules/vm"
  vm_count            = local.lab.vms[0].count
  vm_name_prefix      = local.lab.vms[0].name_prefix
  hyperv_vm_path      = local.lab.hyperv.vm_path
  vhd_size_bytes      = local.lab.vms[0].vhd_size_bytes
  iso_path            = local.lab.vms[0].iso_path
  switch_name         = module.switch.switch_name
  switch_dependency   = module.switch.switch_resource
  memory_startup_bytes = local.lab.vms[0].memory_startup_bytes
  memory_maximum_bytes = local.lab.vms[0].memory_maximum_bytes
  memory_minimum_bytes = local.lab.vms[0].memory_minimum_bytes
  processor_count      = local.lab.vms[0].processor_count
}

# Declare the hyperv_network_switch resource
# Get-NetAdapter
resource "hyperv_network_switch" "wan" {
  name                = "wan"
  allow_management_os = true
  switch_type         = "External"
  net_adapter_names   = ["Ethernet"]
}
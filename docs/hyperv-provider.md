# Hyper-V Provider Configuration

This project uses the `taliesins/hyperv` provider to manage Hyper-V resources. The provider supports both certificate-based and NTLM authentication.

## Reference configuration

```hcl
provider "hyperv" {
  user            = "ad\\administrator"
  password        = ""
  host            = "192.168.1.121"
  port            = 5986
  https           = true
  insecure        = false
  use_ntlm        = true
  tls_server_name = "192.168.1.121"
  cacert_path     = "certs/rootca.pem"
  cert_path       = "certs/host.pem"
  key_path        = "certs/host-key.pem"
  script_path     = "C:/Temp/tofu_%RAND%.cmd"
  timeout         = "30s"
}
```

Each argument can instead be sourced from environment variables such as `HYPERV_USER`, `HYPERV_PASSWORD`, `HYPERV_HOST` and so on. Paths for Kerberos configuration also map to `HYPERV_KERBEROS_*` variables. See [`examples/hyperv/examples_tailiesins/hyperv-provider.example`](../examples/hyperv/examples_tailiesins/hyperv-provider.example) for a complete list.

The `pwsh/runner_scripts/0010_Prepare-HyperVHost.ps1` script installs the provider and converts the generated certificates into PEM files so that `providers.tf` works without additional steps.

## Provider version

Specify the Hyper-V provider version in your lab configuration under the `HyperV` section:

```json
"HyperV": {
  "ProviderVersion": "1.2.1"
}
```

If omitted, the scripts fall back to `1.2.1`.


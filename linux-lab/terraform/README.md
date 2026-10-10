# VMware Workstation Terraform integration — investigation status

**Status: NOT WORKING / NO APPLY VERIFIED.** This is a factual record of the separate Packer Terraform Integration chat, not a deployable Terraform example.

- Provider tested: `elsudano/vmworkstation` **2.0.1**.
- Local VMware REST API endpoint: `http://127.0.0.1:8697/api` (`https = false`). `debug = "NONE"` was required by the provider configuration.
- The VMware REST API itself could list the successfully built `ubuntu-2204-packer` VM with 2 vCPU and 4096 MB memory.
- Terraform `init` and `validate` succeeded.
- The data source is named `vmworkstation_virtual_machine` (an older suggested name was incorrect), but data-source lookup by name and/or VM ID failed with **HTTP 404**.
- **No successful Terraform plan/apply or 2-to-3 vCPU update was established** in that conversation.

Do not add a hardcoded API password or credentials to a public repository. Before introducing runnable Terraform configuration, confirm which provider API endpoint format and lookup fields are accepted, then test `terraform plan` with existing resources and assess the changes before `apply`.

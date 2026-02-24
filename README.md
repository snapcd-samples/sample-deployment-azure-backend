# Sample: Azure Backend Configuration

This sample builds on the [sample-deployment](https://github.com/snapcd-samples/sample-deployment) sample. If you haven't already, complete that sample first — it covers the core Snap CD concepts (Namespaces, Modules, Inputs, Secrets, etc.) and sets up a working deployment with local state storage. This sample extends that by showing how to configure remote state storage on Azure. 

> The base [sample-deployment](https://github.com/snapcd-samples/sample-deployment) must already be deployed before this one can be used!

## Overview

Snap CD is an orchestration tool and does not store your state files. By default, Terraform/OpenTofu uses local state, meaning the Runner stores state on its local disk. This sample shows how to configure remote state storage on Azure instead, using Snap CD's configuration resources:

- **Extra Files** (`snapcd_namespace_extra_file`) — Injects a `terraform { backend "azurerm" {} }` block into modules that don't have one.
- **Flags** (`snapcd_namespace_terraform_flag`) — Of type `MigrateState`, which passes `-migrate-state` flag during `terraform init`, so that the state files (that would initially be local) are migrated to the new remote location.
- **Array Flags** (`snapcd_namespace_terraform_array_flag`) — Of type `BackendConfig`, which passes multiple (an array of) `-backend-config` flags during `terraform init` to supply the Azure Storage Account details.
- **Inputs from Definitions** (`snapcd_namespace_input_from_definition`) — Uses the module name to generate unique state file keys.

## Prerequisites

- A running Snap CD instance with a configured Stack
- The [Snap CD Terraform provider](https://registry.terraform.io/providers/schrieksoft/snapcd) installed
- An Azure Storage Account with a blob container for storing state files

## Variables

| Variable | Description | How to Obtain |
|----------|-------------|---------------|
| `client_id` | The Client ID for authentication | From your Service Principal or personal access token settings |
| `client_secret` | The Client Secret for authentication (sensitive) | Generated when creating your Service Principal or personal access token |
| `organization_id` | Your Snap CD Organization ID | Found in your organization settings |
| `stack_name` | The name of the Stack to deploy to | The name of the Stack you created (e.g., "samples") |
| `namespace_name` | Name for the Namespace to create | A name of your choosing |
| `azure_backend_tenant_id` | Azure Tenant ID | Found in Azure Active Directory |
| `azure_backend_subscription_id` | Azure Subscription ID | Found in the Azure Portal under Subscriptions |
| `azure_backend_resource_group_name` | Resource Group containing the Storage Account | The Resource Group you created for state storage |
| `azure_backend_storage_account_name` | Azure Storage Account name | The Storage Account you created for state files |
| `azure_backend_storage_container_name` | Blob container name within the Storage Account | The container you created for state files |
| `azure_backend_storage_path_prefix` | Path prefix for state file keys | A prefix of your choosing (e.g., "prod", "dev") |
| `azure_backend_arm_client_id` | (Optional) Azure SP Client ID to inject as `ARM_CLIENT_ID` env var | From your Azure App Registration |
| `azure_backend_arm_client_secret_name` | (Optional) Name of a Stack Secret containing the Azure SP Client Secret, injected as `ARM_CLIENT_SECRET` env var | The name of the Stack Secret you created |

To set the variables, create a `terraform.tfvars` file:

```hcl
client_id                            = "your-client-id"
client_secret                        = "your-client-secret"
organization_id                      = "your-organization-id"
stack_name                           = "samples"
namespace_name                       = "my-namespace"
azure_backend_tenant_id              = "your-azure-tenant-id"
azure_backend_subscription_id        = "your-azure-subscription-id"
azure_backend_resource_group_name    = "your-resource-group"
azure_backend_storage_account_name   = "your-storage-account"
azure_backend_storage_container_name = "your-container"
azure_backend_storage_path_prefix    = "your-prefix"

# Optional: ambient Azure credentials
# azure_backend_arm_client_id            = "your-azure-sp-client-id"
# azure_backend_arm_client_secret_name   = "your-stack-secret-name"
```

Alternatively, use environment variables:

```bash
export TF_VAR_client_id="your-client-id"
export TF_VAR_client_secret="your-client-secret"
export TF_VAR_organization_id="your-organization-id"
export TF_VAR_stack_name="samples"
export TF_VAR_namespace_name="my-namespace"
export TF_VAR_azure_backend_tenant_id="your-azure-tenant-id"
export TF_VAR_azure_backend_subscription_id="your-azure-subscription-id"
export TF_VAR_azure_backend_resource_group_name="your-resource-group"
export TF_VAR_azure_backend_storage_account_name="your-storage-account"
export TF_VAR_azure_backend_storage_container_name="your-container"
export TF_VAR_azure_backend_storage_path_prefix="your-prefix"

# Optional: ambient Azure credentials
# export TF_VAR_azure_backend_arm_client_id="your-azure-sp-client-id"
# export TF_VAR_azure_backend_arm_client_secret_name="your-stack-secret-name"
```

## Usage

Once you have created the `terraform.tfvars` file and are ready to start deploying, use the usual terraform commands:

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```


## Authenticating Against the Azure API

The `azurerm` backend needs to authenticate against Azure to read and write state files. There are several ways to do this, and all of them are in principle supported by Snap CD — the only requirement is that the appropriate credentials are available to the Runner at the time of execution. See the [official documentation](https://developer.hashicorp.com/terraform/language/backend/azurerm) for more detail.

This sample does not cover all of these, showing only two scenarios
1. A pre-authenticated scenario, i.e. your Runner is already logged in, e.g. by already running `az login` in advance
2. By passing `ARM_` env vars in via Snap CD resources. Note tthat while this is a legitimate approach, we **strongly** recommend setting such env vars directly on the runner instead. The best option however is to use credential-free approaches such as [Workload Identity Federation](https://developer.hashicorp.com/terraform/language/backend/azurerm#microsoft-entra-id) or [Managed Identities](https://developer.hashicorp.com/terraform/language/backend/azurerm#access-key-lookup-with-compute-attached-managed-identity) instead.


If you want to use the second approach, you must set a secret with the value to pass into `ARM_CLIENT_SECRET` on the "samples" stack and pass its name in  `azure_backend_arm_client_secret_name`.


## How It Works

When Snap CD runs `terraform init` for modules in this Namespace, it:

1. Injects an extra file (`extra_root.tf`) containing the `backend "azurerm" {}` block.
2. (Optionally) Injects ambient Azure credentials as environment variables: `ARM_CLIENT_ID`/`ARM_USE_AZUREAD` via `snapcd_namespace_input_from_literal` and `ARM_CLIENT_SECRET` via `data.snapcd_stack_input_from_secret`.
3. Passes `-migrate-state` so that any existing local state is migrated to the remote backend.
4. Passes `-backend-config` flags for each Azure storage parameter (tenant ID, subscription ID, resource group, storage account, container, and key).
5. Uses the module name to generate a unique state file key (`<prefix>/<module_name>.tfstate`), so each module gets its own state file.

This is equivalent to running:

```bash
terraform init \
  -migrate-state \
  -backend-config="tenant_id=..." \
  -backend-config="subscription_id=..." \
  -backend-config="resource_group_name=..." \
  -backend-config="storage_account_name=..." \
  -backend-config="container_name=..." \
  -backend-config="key=<prefix>/<module_name>.tfstate"
```


## Using other backend

Want to use a different backend? The principals are exactly the same.